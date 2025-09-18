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
echo "########################"
echo "NEPI DOCKER STORAGE SETUP"
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


#############################
CREATE_FOLDERS=0
echo "Checking for rerquired NEPI Folders"
check=0
while [ $check -eq 0 ]
do
    check=1 
    needs_docker=0
    if [[ "$NEPI_DOCKER" != "DOCKER" ]]; then
        if [ ! -d ${NEPI_DOCKER} -a $NEPI_IN_CONTAINER -eq 1 ]; then
            check = 
            echo "Missing required folder: ${NEPI_DOCKER} with min size ${DOCKER_MIN_GB} GB"
            check=0
            needs_docker=1
        fi
    fi

    if [ ! -d ${NEPI_STORAGE} ]; then
        check = 
        echo "Missing required folder: ${NEPI_STORAGE} with min size ${STORAGE_MIN_GB} GB"
        check=0
    fi

    if [ ! -d ${NEPI_CONFIG} ]; then
        check = 
        echo "Missing required folder: ${NEPI_CONFIG} with min size ${STORAGE_MIN_GB} GB"
        check=0
    fi

    if [[ "$check" -eq 0 ]]; then
        select option in "Auto Create Folders" "Manually Create and Try Again" "Quit Setup"; do
            echo "Choose an option to proceed"
            case $option in
                "Auto Create Folders"  ) CREATE_FOLDERS=1 ;; 
                "Manually Create and Try Again" ) ;;
                "Quit Setup" ) exit 1;;
            esac
        done
    fi
done


if [[ ! -d "${NEPI_DOCKER}/nepi_images" ]]; then
    sudo mkdir -p $NEPI_DOCKER
fi
sudo chown -R root:root $NEPI_DOCKER

if [[ ! -d "${NEPI_STORAGE}/nepi_images" ]]; then
    sudo mkdir -p ${NEPI_STORAGE}/nepi_images
fi
sudo chown -R ${USER}:${USER} $NEPI_STORAGE

rfolder=${NEPI_CONFIG}/docker_cfg/etc
if [ ! -f "$rfolder" ]; then
    echo "Creating NEPI Folder: ${rfolder}"
    sudo mkdir -p $rfolder
fi
rfolder=${NEPI_CONFIG}/factory_cfg/etc
if [ ! -d "$rfolder" ]; then
    echo "Creating NEPI Folder: ${rfolder}"
    sudo mkdir -p $rfolder
fi
rfolder=${NEPI_CONFIG}/system_cfg/etc
if [ ! -d "$rfolder" ]; then
    echo "Creating NEPI Folder: ${rfolder}"
    sudo mkdir -p $rfolder
fi

sudo chown -R ${USER}:${USER} $NEPI_CONFIG
#################################

echo "########################"
echo "NEPI Docker Storage Setup Complete"
echo "########################"
