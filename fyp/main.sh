#!/usr/bin/bash

PATH_self=$(realpath "$0")
PATH_pwd=$(dirname "$PATH_self")

function fn_usage {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo "    --remote  remote URI"
    echo "    --help    show this message"
    echo
    echo "Commands:"
    echo "    food   SmritiGrg/FYP-FoodiesArchive"
    echo "    auto   KripaKadel/TS-Autoparts.git"
    echo "    gym    AashishRauniyar/fyp-gymify"
}


function fn_trap {
    echo "ERROR Traceback:"
    echo "    ${BASH_COMMAND}"
    echo "File $PATH_self, line ${BASH_LINENO[0]}"
    echo
}


trap "fn_trap; fn_usage" ERR


function fn_food {
    echo '* restoring data files to the vps server'
    BACKUP_DIR="${PATH_pwd}/backups/food/"

    data_files=(
        "/root/food/.env"
    )

    for file in "${data_files[@]}"; do
        parent_dir=$(dirname "${file}")

        ssh "root@${REMOTE}" "mkdir -p ${parent_dir}"

        echo "Restoring: ${BACKUP_DIR}/${file} -> ${parent_dir}"
        scp -r "${BACKUP_DIR}/${file}" "root@${REMOTE}":"${parent_dir}"
    done

    echo '* deploying food project to server'

    ssh "root@${REMOTE}" "bash -s" < "${PATH_pwd}/food.sh"

    echo '* deployed the project'
}


function fn_auto {
    echo '* restoring data files to the vps server'
    BACKUP_DIR="${PATH_pwd}/backups/auto/"

    data_files=(
        "/root/auto/ts_autoparts/.env"
        "/root/auto/ts_autoparts/database/migrations/"
    )

    for file in "${data_files[@]}"; do
        parent_dir=$(dirname "${file}")

        ssh "root@${REMOTE}" "mkdir -p ${parent_dir}"

        echo "Restoring: ${BACKUP_DIR}/${file} -> ${parent_dir}"
        scp -r "${BACKUP_DIR}/${file}" "root@${REMOTE}":"${parent_dir}"
    done

    echo '* deploying food project to server'

    ssh "root@${REMOTE}" "bash -s" < "${PATH_pwd}/auto.sh"

    echo '* flutter'
    mkdir -p "~/fyp/"
    # if directory not exists
    if [ ! -d "~/fyp/auto" ]; then
        git clone -b master --single-branch https://github.com/KripaKadel/TS-Autoparts.git auto
    fi
    cd ~/fyp/auto
    sed -i "s|baseUrl = '.*'|baseUrl = 'http://$REMOTE:8000/api'|" ./lib/services/auth_service.dart
    ~/apps/flutter/bin/flutter build web --release
    # copy the build files to the server
    scp -r ~/fyp/auto/build/web/* "root@{$REMOTE}":/root/auto/ts_autoparts/public/
    echo '* deployed the project'
}

function fn_gym {
    echo '* restoring data files to the vps server'
    BACKUP_DIR="${PATH_pwd}/backups/gym/"

    data_files=(
        "/root/gym/be/.env"
    )

    for file in "${data_files[@]}"; do
        parent_dir=$(dirname "${file}")

        ssh "root@${REMOTE}" "mkdir -p ${parent_dir}"

        echo "Restoring: ${BACKUP_DIR}/${file} -> ${parent_dir}"
        scp -r "${BACKUP_DIR}/${file}" "root@${REMOTE}":"${parent_dir}"
    done

    echo '* deploying food project to server'

    ssh "root@${REMOTE}" "bash -s" < "${PATH_pwd}/gym.sh"

    echo '* deployed the project'
}



case $1 in
    food)  RUN=fn_food; shift;;
    gym)   RUN=fn_gym; shift;;
    auto)  RUN=fn_auto; shift;;
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
