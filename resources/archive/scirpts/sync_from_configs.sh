#!/bin/bash

##
## Copyright (c) 2024 Numurus <https://www.numurus.com>.
##
## This file is part of nepi setup tools (nepi_setup) repo
## (see https://github.com/nepi-engine/nepi_setup)
##
## License: nepi setup tools are licensed under the "Numurus Software License", 
## which can be found at: <https://numurus.com/wp-content/uploads/Numurus-Software-License-Terms.pdf>
##
## Redistributions in source code must retain this top-level comment block.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##

# This script syncs from NEPI config folder

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi
if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then
    CONFIG_USER=nepihost
fi

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

CONFIG_PATH=/mnt/nepi_config
fix_path ${CONFIG_PATH} 775

##############################
## Check Folders
source ${ETC_SCRIPTS_FOLDER}/check_config_folders.sh 

##############################
## Sync from Config Folders

# Sync from factory
source_config_path=/mnt/nepi_config/factory_cfg
sync_to_config_folder $source_config_path 'nepi_cfg' 


# Sync from system
source_config_path=/mnt/nepi_config/system_cfg
sync_to_config_folder $source_config_path 'nepi_cfg'
sudo cp ${source_config_path}/etc/nepi_system_config.yaml ${ETC_FOLDER}/


######################################
## Sync Docker Config Files

SOURCE_PATH=/mnt/nepi_config/docker_cfg/nepi_docker_config.yaml
UPDATE_PATH=/opt/nepi/docker_cfg/nepi_docker_config.yaml
sync_yaml_files ${SOURCE_PATH} ${UPDATE_PATH}


######################################
## Sync License Files
SOURCE_PATH=/mnt/nepi_storage/license
UPDATE_PATH=/opt/nepi/license
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
        sudo rsync -ah --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi

    sudo rsync -ah --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}

fi