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

# This script syncs to NEPI config folder

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

    if [ ! -e "$bfile" ] || [ ! -s "$bfile" ]; then
        echo "Fix ${CONFIG_USER} bash files"
        sudo rsync -ah --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
    fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}

fi
