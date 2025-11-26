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

# This script syncs to NEPI Docker files and folders

sudo -v

CONFIG_USER=nepihost

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


################## 
# Fix Folder Owners
echo "Fixing NEPI Foder Owners to Config User: ${CONFIG_USER}"
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
sudo chmod 0775 /opt/nepi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
sudo chmod 0750 /mnt/nepi_config
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_storage
sudo chmod 0750 /mnt/nepi_storage

#############################
# Sync Docker Config folders

# Sync to docker_cfg

SOURCE_PATH=/mnt/nepi_config/docker_cfg
UPDATE_PATH=/opt/nepi/docker_cfg

SOURCE_FILE=${SOURCE_PATH}/nepi_docker_config.yaml
UPDATE_FILE=${UPDATE_PATH}/nepi_docker_config.yaml

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "${SOURCE_PATH}" ]]; then
    sudo rsync -ar $UPDATE_FILE $SOURCE_FILE
else

    if [ ! -e "$SOURCE_FILE" ] || [ ! -s "$SOURCE_FILE" ]; then
        echo "Fix ${SOURCE_PATH} file"
        sudo rsync ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi
    
    sudo rsync -ar --exclude='nepi_docker_config.yaml' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
    sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/
    

fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}


#############
# Sync Config Folders

SOURCE_PATH=/mnt/nepi_config/system_cfg/etc
UPDATE_PATH=/opt/nepi/system_cfg/etc

SOURCE_FILE=${SOURCE_PATH}/nepi_system_config.yaml
UPDATE_FILE=${UPDATE_PATH}/nepi_system_config.yaml

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "$SOURCE_PATH" && -d "$UPDATE_PATH" ]]; then
    sudo rsync -ar $UPDATE_FILE $SOURCE_FILE
else

    if [[ ! -d "$UPDATE_PATH" ]]; then
        sudo mkdir -p $UPDATE_PATH
    fi
    if [ ! -e "$SOURCE_FILE" ] || [ ! -s "$SOURCE_FILE" ]; then
        echo "Fix ${SOURCE_PATH} file"
        sudo rsync ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi

    sudo rsync -ar --exclude='nepi_system_config.yaml' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
    sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/

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
if [[ ! -d "${UPDATE_PATH}" ]]; then
    echo "Creating update folder ${UPDATE_PATH}"
    sudo mkdir -p $UPDATE_PATH
    sudo rsync -arh --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
else
    if [ ! -e "$bfile" ] || [ ! -s "$bfile" ]; then
        echo "Update saved bash files ${CONFIG_USER} bash files"
        sudo rsync -arh --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
    fi

    sudo rsync -arh --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}

fi


################## 
# Fix Folder Owners
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
sudo chmod 0775 /opt/nepi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
sudo chmod 0775 /mnt/nepi_config
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_storage
sudo chmod 0775 /mnt/nepi_storage