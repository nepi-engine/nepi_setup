#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script syncs the current folders etc files to the system config folder

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

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

##############################
## Check Folders
load_nepi_config=0
. ${ETC_SCRIPTS_FOLDER}/check_config_folders.sh $load_nepi_config


#############
# Sync to Config Folders

source_config_path=/opt/nepi

sync_to_config_folder $source_config_path 'system_cfg' 


# ######################################
# ## Sync License Files

# SOURCE_PATH=/opt/nepi/license
# UPDATE_PATH=/mnt/nepi_storage/license
# echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
# if [[ ! -d "${SOURCE_PATH}" ]]; then
#     sudo mkdir -p ${SOURCE_PATH}
# fi
# sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
# sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
# sudo chmod -R 775 ${UPDATE_PATH}



    
