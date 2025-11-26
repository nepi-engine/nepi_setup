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


# This file installs the NEPI Engine File System installation

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

if [[ "$CONFIG_USER" != 'nepi' && "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi' or 'nepihost'"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

echo ""
echo "########################"
echo "NEPI FILES SETUP"
echo "########################"
echo ""



#######################################################################################
echo ""
echo "Updating NEPI Config Files"

# Define Folders
SOURCE_INSTR_PATH=$(dirname "$SCRIPT_FOLDER")

SOURCE_SYS_CONFIG_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
SOURCE_SYS_CONFIG_FILE=${SOURCE_SYS_CONFIG_PATH}/nepi_system_config.yaml

SOURCE_NEPI_SCRIPTS_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/scripts


NEPI_CONFIG_PATH=/opt/nepi

NEPI_ETC_PATH=${NEPI_CONFIG_PATH}/etc
NEPI_SYS_CONFIG_FILE=${NEPI_ETC_PATH}/nepi_system_config.yaml
NEPI_SYS_CONFIG_LOAD=${NEPI_ETC_PATH}/load_system_config.sh

NEPI_SCRIPTS_PATH=${NEPI_CONFIG_PATH}/scripts




###################
#  Sync and Load NEPI Config File
echo ""
echo "Updating NEPI System Config File"

if [[ ! -d "$NEPI_CONFIG_PATH" ]]; then
    sudo mkdir -p $NEPI_CONFIG_PATH
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_CONFIG_PATH

if [ ! -e "$NEPI_SYS_CONFIG_FILE" ] || [ ! -s "$NEPI_SYS_CONFIG_FILE" ]; then
    sudo cp -r -p "${SOURCE_SYS_CONFIG_PATH}/nepi_system_config.yaml" ${NEPI_SYS_CONFIG_FILE}
else

    echo "Syncing system_config files from  ${SOURCE_SYS_CONFIG_PATH}/nepi_system_config.yaml to ${NEPI_SYS_CONFIG_FILE}"
    sync_yaml_files ${SOURCE_SYS_CONFIG_PATH}/nepi_system_config.yaml ${NEPI_SYS_CONFIG_FILE}
fi




############
echo ""
echo "Updating NEPI Config Folders"

if [[ ! -d "$NEPI_CONFIG_PATH" ]]; then
    sudo mkdir -p $NEPI_CONFIG_PATH 
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_CONFIG_PATH}


if [[ ! -d "$NEPI_ETC_PATH" ]]; then
    sudo mkdir -p $NEPI_ETC_PATH 
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_ETC_PATH}


if [ ! -e "$NEPI_SYS_CONFIG_FILE" ] || [ ! -s "$NEPI_SYS_CONFIG_FILE" ]; then
    sudo cp -p $SOURCE_SYS_CONFIG_FILE $NEPI_SYS_CONFIG_FILE
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_SYS_CONFIG_FILE}


SOURCE_PATH=${SOURCE_SYS_CONFIG_FILE}
UPDATE_PATH=${NEPI_SYS_CONFIG_FILE}
echo "Syncing NEPI System Config YAML File from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_PATH $UPDATE_PATH


if [[ "$SOURCE_SYS_CONFIG_PATH" != "/etc" && -n "$SOURCE_SYS_CONFIG_PATH" ]]; then

    SOURCE_PATH=$SOURCE_SYS_CONFIG_PATH
    UPDATE_PATH=$NEPI_ETC_PATH

    echo "Syncing ETC Folder from ${SOURCE_PATH} to ${UPDATE_PATH}"
    echo "Excluding nepi_system_config.yaml file"
    sudo rsync -arh --exclude='nepi_system_config.yaml' ${SOURCE_PATH}/ ${UPDATE_PATH}/

fi




############
# Install NEPI Sciprts
SOURCE_PATH=${SOURCE_NEPI_SCRIPTS_PATH}
UPDATE_PATH=/opt/nepi/scripts

echo "Updating NEPI Folder ${UPDATE_PATH} from ${SOURCE_PATH}"
if [[ -n "$SOURCE_PATH" && "$SOURCE_PATH" != '/' ]]; then

    if [[ ! -d "$UPDATE_PATH" ]]; then
        sudo mkdir -p $UPDATE_PATH 
    fi
    sudo rm -r $UPDATE_PATH/*

    sudo rsync -arh  ${SOURCE_PATH}/ ${UPDATE_PATH}/
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod +x ${UPDATE_PATH}/*
fi


################
# Update NEPI System Config Files

echo "Updating NEPI Config File Settings"

source $NEPI_SYS_CONFIG_LOAD
if [[ "$?" -ne 0 ]]; then
    echo "Failed to find load config file at: ${NEPI_SYS_CONFIG_LOAD}"
    exit 1
fi

# min_docker_gb=$((NEPI_GB_CONTAINER * 3))

# check_drive=/mnt/nepi_config/docker_cfg
# check_space=$min_docker_gb
# if is_space_avail_gb $check_drive $check_space; then
#     if [[ "$NEPI_AB_FS" -nq 1 ]]; then
#         echo "Would you like to enable NEPI AB Backup/Recovery file system support"
#         enable_ab=$(ask_yes_no)
#         if [[ "$enable_ab" == 'yes' ]]; then
#             export NEPI_AB_FS=1
#         else
#             export NEPI_AB_FS=0
#         fi
#     fi
# fi

# if [[ -z $NEPI_AB_FS ]]; then
#     NEPI_AB_FS=0
# fi
# update_yaml_value "NEPI_AB_FS" $NEPI_AB_FS $NEPI_DOCKER_CONFIG_FILE


#######################################################################################

# Update Config Folders
echo ""
echo "Running Sync to Configs Script"
source /opt/nepi/etc/scripts/sync_to_configs.sh


#######################################################################################

echo ""
echo "########################"
echo "NEPI Files Setup Complete"
echo "########################"
echo ""