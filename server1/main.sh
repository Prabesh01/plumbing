#!/usr/bin/bash

set -v
set -e


data_files=(
    "/root/mst/tg_message_record.json"
    "/root/mst/mst_creds.json"
    "/root/rutu/.env"
    "/root/rutu/data/"
    "/root/radio/radio.sh"
    "/etc/ntfy/server.yml"
)
mongo_dbs=(
    "mim"
    "lb"
)


PATH_self=$(realpath "$0")
PATH_pwd=$(dirname "$PATH_self")


function fn_usage {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo "    --remote  remote URI"
    echo "    --help    show this message"
    echo
    echo "Commands:"
    echo "    setup   setup vps server"
    echo "    backup    backup necessary files and db to ./backups/ dir"
    echo "    restore   restore files and db from local ./backups/"
}


function fn_trap {
    echo "ERROR Traceback:"
    echo "    ${BASH_COMMAND}"
    echo "File $PATH_self, line ${BASH_LINENO[0]}"
    echo
}


trap "fn_trap; fn_usage" ERR


function fn_setup {
    echo '* setting up the server'
    read -p "You sure you have backedup every thing?"
    ssh "root@${REMOTE}" "bash -s" < "${PATH_pwd}/setup.sh"

    echo '* setting up the server done'
}


function fn_backup {
    echo '* backing up the data files'

    BACKUP_DIR="${PATH_pwd}/backups_$(date +%Y%m%d_%H%M%S)/"
    mkdir -p "${BACKUP_DIR}/data_files"

    for file in "${data_files[@]}"; do

        clean_path=$(realpath -m "$file")
        relative_path="${clean_path#/}" # remove leading slash

        # to use rsync, below 4 lines
        local_dest="${BACKUP_DIR}/data_files/$(dirname "${relative_path}")"
        mkdir -p "${local_dest}"

        echo "Backing up ${clean_path} -> ${BACKUP_DIR}/data_files/${relative_path}"
        rsync -r --progress --human-readable --human-readable -e ssh "root@${REMOTE}:${clean_path}" "${local_dest}/"

        # to use scp, below lines till done
        # dest_path="${BACKUP_DIR}/data_files/${relative_path}"
        # dest_dir=$(dirname "${dest_path}")
        # mkdir -p "${dest_dir}"

        # echo "Backing up ${file} -> ${dest_path}"
        # scp -r "root@${REMOTE}:${clean_path}" "${dest_path}"

    done

    echo "* Backing up MongoDB databases"
    ssh "root@${REMOTE}" "rm -rf /root/export/mongo && mkdir -p /root/export/mongo"
    for db in "${mongo_dbs[@]}"; do
        ssh "root@${REMOTE}" "mongodump -d ${db} -o /root/export/mongo"
    done
    scp -r "root@${REMOTE}:/root/export/mongo" "${BACKUP_DIR}/mongo"

    echo "* Backing up crontab"
    ssh "root@${REMOTE}" "crontab -l" > "${BACKUP_DIR}/crontab.txt"

    echo "Backup completed at: ${BACKUP_DIR}"
}


function fn_restore {
    echo '* restoring data files to the vps server'
    BACKUP_DIR="${PATH_pwd}/backups/"

    for file in "${data_files[@]}"; do
        parent_dir=$(dirname "${file}")

        ssh "root@${REMOTE}" "mkdir -p ${parent_dir}"

        echo "Restoring: ${BACKUP_DIR}/data_files/${file} -> ${file}"
        scp -r "${BACKUP_DIR}/data_files/${file}" "root@${REMOTE}":"${parent_dir}"
    done

    echo "* Restoring MongoDB files"
    ssh "root@${REMOTE}" "rm -rf /root/export/mongo && mkdir -p /root/export/mongo"
    scp -r "${BACKUP_DIR}/mongo" "root@${REMOTE}:/root/export/"

    # Restore crontab
    echo "* Restoring crontab"
    scp "${BACKUP_DIR}/crontab.txt" "root@${REMOTE}:/root/export/crontab.txt"

    # Private repos
    echo "* Restoring k"
    git clone git@github.com:Prabesh01/mamatabhattarai.com.np.git "${PATH_pwd}/mamatabhattarai.com.np"
    ssh "root@${REMOTE}" "mkdir -p /var/www/"
    scp -r "${PATH_pwd}/mamatabhattarai.com.np" "root@${REMOTE}:/var/www/mamata"
    rm -rf "${PATH_pwd}/mamatabhattarai.com.np"

    echo "Restore complete."
}


case $1 in
    setup)  RUN=fn_setup; shift;;
    backup)   RUN=fn_backup; shift;;
    restore)  RUN=fn_restore; shift;;
    *)        fn_usage; exit;;
esac


GETOPT=$(getopt --options h \
                --longoptions remote:,help \
                --name "$0" -- "$@")

eval set -- "$GETOPT"


while true; do
    case $1 in
        --remote)   REMOTE=$2; shift;;
        --help)     fn_usage; exit;;
        *)          shift; break  # break the loop
    esac
done

if [ -z "$REMOTE" ]; then
    fn_usage
    exit 1
fi

# finally running command
$RUN
