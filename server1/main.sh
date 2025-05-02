#!/usr/bin/bash

set -v
set -e


data_files=(
    "/root/discord/tg_message_record.json"
    "/root/rutu/.env"
    "/root/rutu/data/"
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
}


function fn_backup {
    echo '* backing up the data files'

    BACKUP_DIR="${PATH_pwd}/backups_$(date +%Y%m%d_%H%M%S)/"
    mkdir -p "${BACKUP_DIR}/data_files"

    for file in "${data_files[@]}"; do

        clean_path=$(realpath -m "$file")
        relative_path="${clean_path#/}" # remove leading slash

        dest_path="${BACKUP_DIR}/data_files/${relative_path}"
        dest_dir=$(dirname "${dest_path}")
        mkdir -p "${dest_dir}"

        echo "Backing up ${file} -> ${dest_path}"
        rsync -r --progress --human-readable --human-readable -e ssh "root@${REMOTE}:${clean_path}" "${dest_path}"

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

    find "${BACKUP_DIR}/data_files" -type f | while read -r local_file; do
        relative_path="${local_file#${BACKUP_DIR}/data_files/}"
        remote_path="/${relative_path}"
        echo "Restoring file ${local_file} -> ${remote_path}"
        scp "${local_file}" "root@${REMOTE}:${remote_path}"
    done

    echo "* Restoring MongoDB"
    scp -r "${BACKUP_DIR}/mongo" "${REMOTE_USER}@${REMOTE}:/root/export/"
    ssh "${REMOTE_USER}@${REMOTE}" "for d in \$(ls /root/export/mongo); do mongorestore -d \$d /root/export/mongo/\$d; done"

    # Restore crontab
    echo "* Restoring crontab"
    scp "${BACKUP_DIR}/crontab/root_crontab.txt" "${REMOTE_USER}@${REMOTE}:/tmp/crontab.txt"
    ssh "${REMOTE_USER}@${REMOTE}" "crontab /tmp/crontab.txt && rm /tmp/crontab.txt"

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
