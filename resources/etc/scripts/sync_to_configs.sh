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

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi

elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)



##############################
## Check Folders
load_nepi_config=0
. ${ETC_SCRIPTS_FOLDER}/check_config_folders.sh $load_nepi_config


######################################
## Update USER Config file

echo "Updating USER Config File"
SOURCE_PATH=/opt/nepi/etc/nepi_system_config.yaml
UPDATE_PATH=/home/${CONFIG_USER}/nepi_system_config.yaml


if [[ -f ${SOURCE_PATH} ]]; then
    if [[ ! -f "$UPDATE_PATH" ]]; then
        sudo cp -r -p $ $UPDATE_PATH
    fi

    if yq eval "$UPDATE_PATH" > /dev/null; then
        : # Do nothin
    else
        echo "YAML file '$UPDATE_PATH' is invalid. Will replace:"
        sudo cp -r -p $SOURCE_PATH $UPDATE_PATH
    fi

    sync_yaml_files $UPDATE_PATH $SOURCE_PATH  # This should be reversed to first capture missing entries

    sudo cp $SOURCE_PATH $UPDATE_PATH
fi



#############
# Sync to Config Folders

source_config_path=/opt/nepi

sync_to_config_folder 'system_cfg' $source_config_path
sync_to_config_folder 'factory_cfg' $source_config_path
sync_to_config_folder 'recovery_cfg' $source_config_path


#############################
# Sync Docker Config folders

# Sync to docker
SOURCE_PATH=/opt/nepi/docker_cfg
UPDATE_PATH=/mnt/nepi_config/docker_cfg


if [[ "$CONFIG_USER" == 'nepihost' || ! -d "${UPDATE_PATH}" ]]; then
        echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
        if [[ ! -d "${SOURCE_PATH}" ]]; then
            sudo mkdir -p ${SOURCE_PATH}
        fi
        sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
fi

if [ -z "$(ls -A "$UPDATE_PATH")" ]; then
        sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
fi

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}

######################################
## Sync License Files

SOURCE_PATH=/opt/nepi/license
UPDATE_PATH=/mnt/nepi_storage/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo mkdir -p ${SOURCE_PATH}
fi
sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}

# ######################################
# ## Sync Storage Config Files

# SOURCE_PATH=/opt/nepi/user_cfg
# UPDATE_PATH=/mnt/nepi_storage/user_cfg

