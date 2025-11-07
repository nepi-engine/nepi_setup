#! /bin/bash
##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This file initializes a NEPI Storage Drive Folder


sudo -v

echo "Checking for required software"
if command -v yq &>/dev/null; then
    echo "yq is installed."
else
    echo "Install yq software"
    sudo add-apt-repository ppa:rmescandon/yq -y
    sudo apt update
    sudo apt install yq -y
fi
if command -v yq &>/dev/null; then
    echo "yq is installed."
else
    echo "yq not installed, EXITING"
    exit 1
fi



echo "########################"
echo "NEPI DOCKER INITIALIZATION SETUP"
echo "########################"

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

# Load System Config File
source $(dirname ${SCRIPT_FOLDER})/config/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_CONFIG_FILE}"
    exit 1
fi

# Check User Account
CONFIG_USER=$NEPI_HOST_USER
if [[ "$USER" != "$CONFIG_USER" ]]; then
    echo "This script must be run by user account ${CONFIG_USER}."
    echo "Log in as ${CONFIG_USER} and run again"
    exit 2
fi



#####################################
# Update NEPI System Config if needed
#####################################

if [ -f "$NEPI_SYSTEM_CONFIG_DEST" ]; then
    ## Check Selection
    echo ""
    echo ""
    echo "Do You Want to OverWrite System Config: ${OP_SELECTION}"
    select ovw in "View_Original" "View_New" "Yes" "No" "Quit"; do
        case $ovw in
            View_Current) print_config_file $NEPI_SYSTEM_CONFIG_DEST;;
            Reset_Defualt)
            Change_

# If NEPI_IN_CONTAINER=1, set whether NEPI supports a dual A B files system structure for
#  backup and recovery purposes.
# NOTE: If NEPI_AB_FS is enabled, NEPI docker service will manage an Active NEPI container image,
#   and an Inactive Image used for backup and recovery purposes. If NEPI_AB_FS is enabled, 
#   you can switch between the current Active and Inactive A B containers
#   with the terminal command "nepiswitch".
# NOTE: If NEPI_AB_FS is enabled, an additional 100 GB of free drive space will be required
#   for storing backup and staging of Docker images
NEPI_AB_FS: 1

# Set to paths where NEPI will use for importing and exporting
#  NEPI tar container images.
# NOTE: It is recommended that these folders be create as their own partitions
#   so that these files are not affected by any device file system changes
#   NEPI Docker Folder
NEPI_IMPORT_PATH: /mnt/nepi_storage/nepi_images
NEPI_EXPORT_PATH: /mnt/nepi_storage/nepi_images



            Quit ) exit 1
        esac
    done


    if [ "$OVERWRITE" -eq 1 ]; then
        echo "Updating NEPI CONFIG ${NEPI_SYSTEM_CONFIG_DEST} "
        echo $NEPI_SYSTEM_CONFIG_SOURCE
        echo $NEPI_SYSTEM_CONFIG_DEST
        sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${NEPI_SYSTEM_CONFIG_DEST}
        sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_SYSTEM_CONFIG_DEST}/*
        SOURCE_PATH=$ETC_SOURCE_PATH/nepi_system_config.yaml
        UPDATE_PATH=${NEPI_CONFIG_PATH}/nepi_system_config.yaml
        sudo cp ${SOURCE_PATH} ${UPDATE_PATH}
        SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
        SOURCE_PATH=$ETC_SOURCE_PATH/nepi_system_config.sh
        UPDATE_PATH=${NEPI_CONFIG_PATH}/nepi_system_config.sh
        sudo cp ${SOURCE_PATH} ${UPDATE_PATH}
        sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
        sudo chmod 775 ${UPDATE_PATH}

        sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
        sudo chmod 775 ${UPDATE_PATH}
    fi
    #print_config_file $NEPI_SYSTEM_CONFIG_DEST
else
    sudo mkdir -p $NEPI_SYSTEM_CONFIG_DEST_PATH
    sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${NEPI_SYSTEM_CONFIG_DEST}
fi

echo "Refreshing NEPI CONFIG from ${NEPI_SYSTEM_CONFIG_DEST} "
source ${NEPI_SYSTEM_CONFIG_DEST_PATH}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${NEPI_SYSTEM_CONFIG_DEST_PATH}/load_system_config.sh"
    exit 1
fi



#############################
# Download NEPI Docker Image
fs_dest=FSA

# download image from ???

if downloaded

import to FSA



#############################
# Clone NEPI Docker Image if needed

if [[ "$NEPI_AB_FS" -eq 1 ]]; then
    #
    fs_source=FSA
    nepiclone $fs_source # Need to add to nepi_docker_aliasses file
fi


#############################
# Enable NEPI Docker Service

# ENABLE_NEPI=0
# echo "Would You Like to Enable NEPI Docker Service on startup?"
# while true; do
#     read -p "$1 [Y/n]: " yn
#     case $yn in
#         [Yy]* ) ENABLE_NEPI=1; break;; # User entered 'y' or 'Y', return success (0)
#         [Nn]* ) ENABLE_NEPI=0; break;; # User entered 'n' or 'N', return failure (1)
#         * ) echo "Please answer yes or no.";; # Invalid input, prompt again
#     esac
# done

ENABLE_NEPI=1

if [[ "$ENABLE_NEPI" -eq 1 ]]; then
    sudo systemctl enable nepi_docker
    echo "########################"
    echo "NEPI Docker Service enabled on startup"
    echo "You can manually enable/disable nepi_docker service with nepienable/nepidisable"
    echo "########################"
else
    echo "########################"
    echo "NEPI Docker Service disabled on startup"
    echo "You can manually enable/disable nepi_docker service with nepienable/nepidisable"
    echo "########################"
fi


#################################

echo "########################"
echo "NEPI Docker Storage Setup Complete"
echo "########################"
