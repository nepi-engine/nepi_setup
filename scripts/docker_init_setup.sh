#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs the NEPI Engine File System installation

sudo -v

export CONFIG_USER=$(id -un 1000)

# if [[ "$CONFIG_USER" != 'nepi' && "$CONFIG_USER" != 'nepihost' ]]; then
#     echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi' or 'nepihost'"
#     exit 1
# fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

ninet

if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    exit 1
fi

echo "########################"
echo "NEPI DOCKER INITIALIZATION SETUP"
echo "########################"




####################################
# Check NEPI Storage Folder

CURRENT_FOLDER=$(pwd)
NEPI_STORAGE=/mnt/nepi_storage

if [[ ! -d "$NEPI_STORAGE" ]]; then
    echo "Creating NEPI Folder: ${NEPI_STORAGE}"
    sudo mkdir -p $NEPI_STORAGE
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_STORAGE


####################################
# Download Storage Extras

cd $NEPI_STORAGE

storage_latest_link='https://www.dropbox.com/scl/fo/c7qap49hftrmi13ku49tg/h?rlkey=kbufq3lv04y9c2etc17kotk0j&st=hmqc234m&dl=0'
storage_latest_zip=nepi_storage-latest.zip


if [[ ! -f ${storage_latest_zip} ]]; then
    sudo wget ${storage_latest_link} -O ${storage_latest_zip}
fi
if [[ -f ${storage_latest_zip} ]]; then
    chown -R ${CONFIG_USER}:${CONFIG_USER} ${storage_latest_zip}
    unzip -o ${storage_latest_zip}
    if [ $? -eq 0 ]; then
        sudo rm ${storage_latest_zip}
    else
        echo "Failed to unzip NEPI Storage file: ${storage_latest_zip}"
    fi
else
    echo "Failed to download NEPI Storage from link: ${storage_latest_link}"
fi

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_STORAGE}/ai_models  > /dev/null 2>&1
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_STORAGE}/sample_data  > /dev/null 2>&1
sudo chown ${CONFIG_USER}:${CONFIG_USER}${NEPI_STORAGE}/nepi_src  > /dev/null 2>&1
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_STORAGE}/nepi_src/rui_logo_update  > /dev/null 2>&1

cd $CURRENT_FOLDER




# ####################################
# # Download NEPI Image

# if [[ ! -d "$NEPI_STORAGE/nepi_images" ]]; then
#     echo "Creating NEPI Folder: ${NEPI_STORAGE}/nepi_images"
#     sudo mkdir -p $NEPI_STORAGE/nepi_images
# fi
# sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_STORAGE/nepi_images

# cd $NEPI_STORAGE/nepi_images

# HW_TYPE=jetson

# # HW_TYPE=unknown
# # if is_valid_jetson; then
# #     HW_TYPE=jetson
# # elif is_valid_arm64; then
# #     HW_TYPE=arm64
# # elif is_valid_amd64; then
# #     HW_TYPE=amd64
# # else
# #     arch_val=$(uname -m)
# #     echo "Arch ${arch_val} not supported yet"
# #     exit 1
# # fi


# # cd $NEPI_STORAGE/nepi_images
# # sudo rm *.zip

# if [[ "$HW_TYPE" == 'jetson' ]]; then
#     nepi_latest_link='https://www.dropbox.com/scl/fi/jopn4tmak3b8c67hm62yb/nepi-jetson-latest.zip?rlkey=c6709sxktzaxegcymg0hvueak&st=xwd3lrpr&dl=0'
#     nepi_latest_name=nepi-jetson-latest.zip
# else
#     echo "No NEPI Image File available for hardware architecture ${arch_val}"
#     exit 1    
# fi


# if [[ ! -f ${nepi_latest_name} ]]; then
#     sudo wget ${nepi_latest_link} -O ${nepi_latest_name}
# fi

# if [[ -f ${nepi_latest_name} ]]; then
#     chown -R ${CONFIG_USER}:${CONFIG_USER} ${nepi_latest_name}
#     unzip -o ${nepi_latest_name}
#     if [ $? -eq 0 ]; then
#         sudo rm ${nepi_latest_name}
#     else
#         echo "Failed to unzip NEPI Image file: ${nepi_latest_name}"
#     fi
# else
#     echo "Failed to download NEPI Image from link: ${nepi_latest}"
# fi
# sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_STORAGE}/nepi_images

# cd $CURRENT_FOLDER





####################################
# Cleanup



echo "########################"
echo "NEPI Docker Initialization Setup Complete"
echo "########################"