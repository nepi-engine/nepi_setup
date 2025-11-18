#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script syncs to NEPI config folder

if [[ "$(id -un 1000)" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ -f "/home/${USER}/.nepi_docker_aliases" ]]; then
    CONFIG_USER=${USER}
    bfile=/home/${USER}/.bashrc
    ufile=/home/${USER}/.nepi_bash_utils
    afile=/home/${USER}/.nepi_docker_aliases
else
    echo "NEPI Aliases bash file not found"
    exit 1
fi

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)



##############################
## Check Folders
load_nepi_config=0
source ${ETC_SCRIPTS_FOLDER}/check_config_folders.sh $load_nepi_config



#############
# Sync to Config Folders

source_config_path=/opt/nepi
echo "Syncing files from system and factory configs to ${source_config_path}"
sync_to_config_folder $source_config_path 'system_cfg'
sync_to_config_folder $source_config_path 'factory_cfg' 


#############################
# Sync Docker Config folders

# Sync to docker
SOURCE_PATH=/opt/nepi/docker_cfg/nepi_docker_config.yaml
UPDATE_PATH=/mnt/nepi_config/docker_cfg/nepi_docker_config.yaml
sync_yaml_files ${SOURCE_PATH} ${UPDATE_PATH}


######################################
## Sync License Files

SOURCE_PATH=/opt/nepi/license
UPDATE_PATH=/mnt/nepi_storage/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then

    sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
    fix_folder ${UPDATE_PATH} 775 

fi


######################################
## Sync Bash Files
SOURCE_PATH=/opt/nepi/bash/${CONFIG_USER}
UPDATE_PATH=/home/${CONFIG_USER}
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then

    if [ -e "$bfile" ] && [ ! -s "$bfile" ]; then
        echo "Fix ${CONFIG_USER} bash files"
        sudo rsync -av --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    elif [ ! -e "$FILE" ]; then
    echo "Fix ${CONFIG_USER} bash files"
    sudo rsync -av --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi

    sudo rsync -av --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}

fi
