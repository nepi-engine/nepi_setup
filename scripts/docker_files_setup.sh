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
## Redistributions in source code must retain this top-level comment block, 
## Along with any License Check related code and checks.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##



LITE_INSTALL=0
if [[ "$1" -eq 1 ]] 2>/dev/null; then
    LITE_INSTALL=$1
fi
# echo "LITE_INSTALL=${LITE_INSTALL}"

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi



# This file configures a NEPI Docker installation Files and Folders





CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepihost'"
    return 
fi

sudo -v


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



echo ""
echo "########################"
echo "NEPI Docker Files SETUP"
echo "########################"
echo ""


############
echo ""
echo "Updating NEPI Config Folders"
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
UPDATE_PATH=/opt/nepi/etc
CONFIG_FILENAME=nepi_system_config.yaml
BACKUP_FILENAME=nepi_system_config.yaml.bak

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}
BACKUP_FILE=${UPDATE_PATH}/${BACKUP_FILENAME}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 
sudo rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
UPDATE_PATH=/mnt/nepi_config/system_cfg/etc
CONFIG_FILENAME=nepi_system_config.yaml
BACKUP_FILENAME=nepi_system_config.yaml.bak

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}
BACKUP_FILE=${UPDATE_PATH}/${BACKUP_FILENAME}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 
sudo rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}

#############################
echo ""
echo "Updating NEPI System Config Files and Folders"

sudo cp $UPDATE_FILE $BACKUP_FILE
sudo chown ${CONFIG_USER}:${CONFIG_USER} $BACKUP_FILE

#############################
echo ""
echo "Updating Docker Config Files and Folders"
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/docker
UPDATE_PATH=/opt/nepi/docker
CONFIG_FILENAME=nepi_docker_config.yaml
BACKUP_FILENAME=nepi_docker_config.yaml.bak

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}
BACKUP_FILE=${UPDATE_PATH}/${BACKUP_FILENAME}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 
sudo rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/docker
UPDATE_PATH=/mnt/nepi_config/docker_cfg
CONFIG_FILENAME=nepi_docker_config.yaml
BACKUP_FILENAME=nepi_docker_config.yaml.bak

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}
BACKUP_FILE=${UPDATE_PATH}/${BACKUP_FILENAME}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 
sudo rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}

#############################
echo ""
echo "Updating Docker Config Files and Folders"

sudo cp $UPDATE_FILE $BACKUP_FILE
sudo chown ${CONFIG_USER}:${CONFIG_USER} $BACKUP_FILE


#############################
echo ""
echo "Updating System Config Files and Folders"

script_file=nepi_docker_sync.sh
script_path=$(dirname "${SCRIPT_FOLDER}")/resources/docker/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    return 
fi



#############################
echo ""
echo "Updating Factory Config Files and Folders"

SOURCE_PATH=/mnt/nepi_config/system_cfg/etc 
UPDATE_PATH=/mnt/nepi_config/factory_cfg/etc 
CONFIG_FILENAME=nepi_system_config.yaml


SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 
sudo rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}


echo ""
echo "########################"
echo "NEPI Docker Files Setup Complete"
echo "########################"
echo ""