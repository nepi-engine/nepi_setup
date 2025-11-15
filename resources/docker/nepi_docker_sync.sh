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


export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ "$CONFIG_USER" == 'nepihost'  ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepihost/.bashrc
    ufile=/home/nepihost/.nepi_bash_utils
    afile=/home/nepihost/.nepi_docker_aliases
# elif [[ -f "/home/${CONFIG_USER}/.nepi_docker_aliases" ]]; then
#     bfile=/home/${CONFIG_USER}/.bashrc
#     ufile=/home/${CONFIG_USER}/.nepi_bash_utils
#     afile=/home/${CONFIG_USER}/.nepi_docker_aliases
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


DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)




#############################
# Sync Docker Config folders

# Sync to docker_cfg
SOURCE_PATH=/opt/nepi/docker_cfg
UPDATE_PATH=/mnt/nepi_config/docker_cfg


echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/


#############
# Sync Config Folders

SOURCE_PATH=/opt/nepi/etc
UPDATE_PATH=/mnt/nepi_config/system_cfg/etc


if [[ ! -d "${UPDATE_PATH}" ]]; then
        echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
        if [[ ! -d "${SOURCE_PATH}" ]]; then
            sudo mkdir -p ${SOURCE_PATH}
        fi
        sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
fi
        
SOURCE_PATH=/opt/nepi/etc/nepi_system_config.yaml
UPDATE_PATH=/mnt/nepi_config/system_cfg/nepi_system_config.yaml
sync_yaml_files ${SOURCE_PATH} ${UPDATE_PATH}


######################################
## Sync License Files

SOURCE_PATH=/mnt/nepi_storage/license
UPDATE_PATH=/opt/nepi/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo mkdir -p ${SOURCE_PATH}
fi
sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
fix_folder ${UPDATE_PATH} 775 


SOURCE_PATH=/opt/nepi/license
UPDATE_PATH=/mnt/nepi_storage/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo mkdir -p ${SOURCE_PATH}
fi

sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
fix_folder $UPDATE_PATH 775

# ######################################
# ## Sync Storage Config Files

# SOURCE_PATH=/opt/nepi/user_cfg
# UPDATE_PATH=/mnt/nepi_storage/user_cfg

