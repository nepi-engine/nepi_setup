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



LITE_INSTALL=$1

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $LITE_INSTALL
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
USER_CHECK_FILE=${SCRIPT_FOLDER}/nepi_user_check.sh
source $USER_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
echo "Script Folder: ${SCRIPT_FOLDER}"
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

# Load System Config File
#echo "Loading NEPI SYSTEM CONFIG"
nepi_config_loaded=0
NEPI_SETUP_CONFIG_FILE=${RESOURCES_FOLDER}/etc/load_system_config.sh
NEPI_SYSTEM_CONFIG_FILE=${NEPI_SYSTEM_CONFIG}/etc/load_system_config.sh
if [[ -f $NEPI_SYSTEM_CONFIG_FILE ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SYSTEM_CONFIG_FILE}"
    source ${NEPI_SYSTEM_CONFIG_FILE} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        nepi_config_loaded=1
    fi
elif [[ -f $NEPI_SETUP_CONFIG_FILE && $nepi_config_loaded -eq 0 ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SETUP_CONFIG_FILE}"
    source ${NEPI_SETUP_CONFIG_FILE}  >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SETUP_CONFIG_FILE}"
    fi
fi



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


find $UPDATE_PATH -mindepth 1 -maxdepth 1 -type d -exec sudo rm -rf {} +
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/

# sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
# sudo chmod 775 ${SOURCE_PATH}

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=/opt/nepi/etc
UPDATE_PATH=/mnt/nepi_config/system_cfg/etc
CONFIG_FILENAME=nepi_system_config.yaml

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}


find $UPDATE_PATH -mindepth 1 -maxdepth 1 -type d -exec sudo rm -rf {} +
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -f $UPDATE_FILE ]]; then
    sudo cp $SOURCE_FILE $UPDATE_FILE 
fi
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 


sudo cp $UPDATE_FILE $SOURCE_FILE 
sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/

# sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
# sudo chmod 775 ${SOURCE_PATH}

sudo chown -R 1000:1000 ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}

NEPI_SYSTEM_CONFIG_FILE=${NEPI_SYSTEM_CONFIG}/etc/load_system_config.sh
update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_SYS_CONFIG_FILE

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi

#############################
echo ""
echo "Updating Docker Config Files and Folders"
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/docker
UPDATE_PATH=/opt/nepi/docker_cfg
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"

if [[ ! -d $UPDATE_PATH ]]; then
    sudo mkdir $UPDATE_PATH
fi

sudo rsync -ar --delete ${SOURCE_PATH}/ ${UPDATE_PATH}/
sudo cp ${SOURCE_PATH}/nepi_docker_config.yaml ${UPDATE_PATH}/nepi_docker_config.blank

# sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
# sudo chmod 775 ${SOURCE_PATH}

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SOURCE_PATH=/opt/nepi/docker_cfg
UPDATE_PATH=/mnt/nepi_config/docker_cfg
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"

if [[ ! -d $UPDATE_PATH ]]; then
    sudo mkdir $UPDATE_PATH
fi

sudo rsync -ar --delete ${SOURCE_PATH}/ ${UPDATE_PATH}/
sudo cp ${SOURCE_PATH}/nepi_docker_config.yaml ${UPDATE_PATH}/nepi_docker_config.blank

# sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
# sudo chmod 775 ${SOURCE_PATH}

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}



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

find $UPDATE_PATH -mindepth 1 -maxdepth 1 -type d -exec sudo rm -rf {} +
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_FILE $UPDATE_FILE 
sudo rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

sudo chown -R 1000:1000 ${SOURCE_PATH}
sudo chmod -R 775 ${SOURCE_PATH}

sudo chown -R 1000:1000 ${UPDATE_PATH}
sudo chmod -R 775 ${UPDATE_PATH}


echo ""
echo "########################"
echo "NEPI Docker Files Setup Complete"
echo "########################"
echo ""