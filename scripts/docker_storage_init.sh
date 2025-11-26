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
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepihost'"
    exit 1
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

ninet > /dev/null 2>&1

if ! is_valid_internet > /dev/null; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    exit 1
fi

echo ""
echo "########################"
echo "NEPI DOCKER STORAGE INIT"
echo "########################"
echo ""


####################################
# Check NEPI Storage Folder

CURRENT_FOLDER=$(pwd)
NEPI_STORAGE=/mnt/nepi_storage

if [[ ! -d "$NEPI_STORAGE" ]]; then
    #echo "Creating NEPI Folder: ${NEPI_STORAGE}"
    sudo mkdir -p $NEPI_STORAGE
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_STORAGE



if [[ ! -d "$NEPI_STORAGE/nepi_images" ]]; then
    #echo "Creating NEPI Folder: ${NEPI_STORAGE}/nepi_images"
    sudo mkdir -p $NEPI_STORAGE/nepi_images
fi
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_STORAGE}/nepi_images


####################################
# Run User Checks

##################
## NEPI Image Check

success_image=1
cd $NEPI_STORAGE/nepi_images
sudo rm ARCHIVE > /dev/null 2>&1


# UPDATE_NEPI_IMAGE=yes
# echo ""
# tar_files=$(find ./ -name "*.tar")
# if [[ -n "$tar_files" ]]; then
#     echo ""
#     echo "Existing NEPI Image files found"
#     echo "-------------------------------"
#     find ./ -name "*.tar"
#     echo "-------------------------------"
#     echo ""
#     echo " Do you want to download the Latest NEPI Image?"
#     echo ""
#     UPDATE_NEPI_IMAGE=$(ask_yes_no)
#     echo ""
# fi



cd $CURRENT_FOLDER


##################
## NEPI Storage Check

success_storage=1
cd $NEPI_STORAGE

sudo rm ARCHIVE > /dev/null 2>&1

# UPDATE_NEPI_STORAGE=yes
# echo ""
# echo "-------------------------------"
# echo ""
# echo " Do you want to install NEPI Demo AI Models, Sample Data, and User Config files?"
# UPDATE_NEPI_STORAGE=$(ask_yes_no)
# echo ""
# echo "-------------------------------"


cd $CURRENT_FOLDER




####################################
# Download NEPI Image

if [[ "$UPDATE_NEPI_IMAGE" == 'yes' ]]; then
    echo ""
    echo "########################"
    echo "Installing the Latest NEPI Image"
    echo ""

    success_image=0
    cd $NEPI_STORAGE/nepi_images



    HW_TYPE=unknown
    if is_valid_jetson; then
        HW_TYPE=jetson
    elif is_valid_arm64; then
        HW_TYPE=arm64
    elif is_valid_amd64; then
        HW_TYPE=amd64
    else
        arch_val=$(uname -m)
        echo "Arch ${arch_val} not supported yet"
        exit 1
    fi

    if [[ "$HW_TYPE" == 'jetson' ]]; then
        nepi_latest_link='https://dl.dropbox.com/scl/fo/a3zquicze0g7x00vwgo45/ALAZUgfpkcmqqM7Xxacj8Ok?rlkey=aolze0l4albuczba94bzu0ui7&st=8muurhlu&dl=1'
    else
        echo "No NEPI Image File available for hardware architecture ${arch_val}"
        exit 1    
    fi

    sudo wget ${nepi_latest_link}
    if [[ "$?" -ne 0 ]]; then
            echo "Failed to download NEPI Image from link: ${nepi_latest}"
    fi
fi


sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_STORAGE}/nepi_images

cd $CURRENT_FOLDER


###################################
# Download Storage Extras


if [[ "$UPDATE_NEPI_STORAGE" == 'yes' ]]; then

    echo ""
    echo "########################"
    echo "Initializing NEPI Storage Folders"
    echo ""

    success_storage=0
    cd $NEPI_STORAGE


    storage_latest_link='https://www.dropbox.com/scl/fi/116ktcw07rcjbqxa070vh/nepi_storage-test.zip?rlkey=few0xjaxs4jvhaah18fxq8gcb&st=j6ayg4xu&dl=0'
    #storage_latest_link='https://www.dropbox.com/scl/fo/c7qap49hftrmi13ku49tg/h?rlkey=kbufq3lv04y9c2etc17kotk0j&st=hmqc234m&dl=0'
    storage_latest_zip=nepi_storage-latest.zip


    if [[ ! -f ${storage_latest_zip} ]]; then
        sudo wget ${storage_latest_link} -O ${storage_latest_zip}
        if [[ "$?" -ne 0 ]]; then
            echo "Failed to download NEPI Storage from link: ${storage_latest_link}"
            sudo rm ${storage_latest_zip}
        fi
    else
        sudo chown ${CONFIG_USER}:${CONFIG_USER} $storage_latest_zip
    fi

    if [[ -f ${storage_latest_zip} ]]; then
        echo "Unzipping storage folders from ${storage_latest_zip}"
        sudo unzip -o -q $storage_latest_zip
        if [ $? -eq 0 ]; then
            #sudo rm ${storage_latest_zip} > /dev/null 2>&1
            success_storage=1
        else
            echo "Failed to unzip NEPI Storage file: ${storage_latest_zip}"
            #sudo rm ${storage_latest_zip} > /dev/null 2>&1
        fi
    else
        echo "Failed to find NEPI Storage file: ${storage_latest_zip}"
    fi

    if [[ -f ${storage_latest_zip} ]]; then
        sudo rm ${storage_latest_zip} > /dev/null 2>&1
    fi

    if [[ -f ${storage_latest_zip} ]]; then
        sudo rm ${storage_latest_zip} > /dev/null 2>&1
    fi

fi

cd $CURRENT_FOLDER





####################################
# Cleanup


if [[ "$success_image" -eq 0 ]]; then
    echo ""
    echo "NEPI Image Install Failed"
    echo ""
fi

if [[ "$success_storage" -eq 0 ]]; then
    echo ""
    echo "NEPI Storage Install Failed"
    echo ""
fi


if [[ "$success_storage" -eq 1 && "$success_image" -eq 1 ]]; then
    echo ""
    echo "########################"
    echo "NEPI Docker Storage Init Complete"
    echo "########################"
    echo ""

fi


