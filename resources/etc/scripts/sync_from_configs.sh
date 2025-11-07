#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script syncs from NEPI config folder

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi

elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 


ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})


sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
sudo chmod -R 0775 /mnt/nepi_config

##############################
## Check Folders
load_nepi_config=0
. ${ETC_SCRIPTS_FOLDER}/check_config_folders.sh $load_nepi_config


######################################
## Update From USER Config file

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



##############################
## Sync from Config Folders

# Sync from factory
source_config_path=/mnt/nepi_config/factory_cfg
sync_to_config_folder 'nepi_cfg' $source_config_path

# Sync from system
source_config_path=/mnt/nepi_config/system_cfg
sync_to_config_folder 'nepi_cfg' $source_config_path


######################################
## Sync Docker Config Files

SOURCE_PATH=/mnt/nepi_config/docker_cfg
UPDATE_PATH=/opt/nepi/docker_cfg
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo mkdir -p ${SOURCE_PATH}
fi
sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}


######################################
## Sync License Files
SOURCE_PATH=/mnt/nepi_storage/license
UPDATE_PATH=/opt/nepi/license
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo mkdir -p ${SOURCE_PATH}
fi
sudo rsync -arh ${SOURCE_PATH}/ ${UPDATE_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}



# ######################################
# ## Sync Storage Config Files
# SOURCE_PATH=/mnt/nepi_storage/user_cfg
# UPDATE_PATH=/opt/nepi/user_cfg

