#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script syncs to NEPI Docker files and folders

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

    bfile=/home/${CONFIG_USER}/.bashrc
    ufile=/home/${CONFIG_USER}/.nepi_bash_utils
    afile=/home/${CONFIG_USER}/.nepi_docker_aliases

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)




#############################
# Sync Docker Config folders

# Sync to docker_cfg

SOURCE_PATH=/mnt/nepi_config/docker_cfg
UPDATE_PATH=/opt/nepi/docker_cfg

SOURCE_FILE=${SOURCE_PATH}/nepi_docker_config.yaml
UPDATE_FILE=${UPDATE_PATH}/nepi_docker_config.yaml

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo rsync -arv $UPDATE_FILE $SOURCE_FILE
else

    if [ ! -e "$SOURCE_FILE" ] || [ ! -s "$SOURCE_FILE" ]; then
        echo "Fix ${SOURCE_PATH} file"
        sudo rsync ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi
    
    sudo rsync -arv --exclude='nepi_docker_config.yaml' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
    sudo rsync -arv ${SOURCE_PATH}/ ${UPDATE_PATH}/
    

fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}


#############
# Sync Config Folders

SOURCE_PATH=/mnt/nepi_config/system_cfg
UPDATE_PATH=/opt/nepi/system_cfg

SOURCE_FILE=${SOURCE_PATH}/nepi_system_config.yaml
UPDATE_FILE=${UPDATE_PATH}/nepi_system_config.yaml

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo rsync -arv $UPDATE_FILE $SOURCE_FILE
else

    if [ ! -e "$SOURCE_FILE" ] || [ ! -s "$SOURCE_FILE" ]; then
        echo "Fix ${SOURCE_PATH} file"
        sudo rsync ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi

    sudo rsync -arv --exclude='nepi_docker_config.yaml' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
    sudo rsync -arv ${SOURCE_PATH}/ ${UPDATE_PATH}/

fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}

######################################
## Sync License Files

SOURCE_PATH=/mnt/nepi_storage/license
UPDATE_PATH=/opt/nepi/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then

    sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
    fix_folder ${UPDATE_PATH} 775 

fi


SOURCE_PATH=/opt/nepi/license
UPDATE_PATH=/mnt/nepi_storage/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then

    sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
    fix_folder ${UPDATE_PATH} 775 

fi


######################################
## Sync Bash Files
SOURCE_PATH=/home/${CONFIG_USER} 
UPDATE_PATH=/opt/nepi/bash/${CONFIG_USER}
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then

    if [ ! -e "$bfile" ] || [ ! -s "$bfile" ]; then
        echo "Fix ${CONFIG_USER} bash files"
        sudo rsync -av --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi

    sudo rsync -av --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}

fi