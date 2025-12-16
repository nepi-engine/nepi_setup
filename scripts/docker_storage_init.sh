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



# This file installs the NEPI Storage Lite Files
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
    exit 1
fi



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

SYSTEM_FOLDER=/mnt/nepi_config/system_cfg/etc
SYSTEM_CONFIG_FILE=${SYSTEM_FOLDER}/nepi_system_config.yaml
SYSTEM_CONFIG_LOAD_FILE=${SYSTEM_FOLDER}/load_system_config.sh


if [[ ! -f "$SYSTEM_CONFIG_LOAD_FILE" ]]; then
    echo "Docker Config Load file not found at: ${SYSTEM_CONFIG_LOAD_FILE}"
    echo "Run 'nepiupdate' and try again"

else
    source ${SYSTEM_CONFIG_LOAD_FILE}
    if [[ "$?" -eq 1 ]]; then
        echo "Failed to load ${SYSTEM_CONFIG_FILE}"

    elif [[ ! -n "$NEPI_IMPORT_PATH" ]]; then
        echo "NEPI Docker Import Folder not defined in variable NEPI_IMPORT_PATH"
        echo "Run 'nepiconfig' to fix path location and try again"
    elif [[ ! -d "$NEPI_IMPORT_PATH" ]]; then
        echo "NEPI Docker Import Folder not found at ${NEPI_IMPORT_PATH}"
        echo "Create import path or run 'nepiconfig' to fix path location and try again"
    else

        CURRENT_FOLDER=$(pwd)
        ####################################
        # Check NEPI Storage Folder
        sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_IMPORT_PATH
        avail_space_gb=$(path_space_gb $NEPI_IMPORT_PATH)
        req_space_gb=1
        if [[ "$avail_space_gb" -lt "$req_space_gb" ]]; then
            need_space_gb=$((req_space_gb - avail_space_gb))
            echo "Not enough free drive space in import path ${NEPI_IMPORT_PATH}"
            echo "Free up ${need_space_gb} GB in that folders partition and try again"
        else


            echo ""
            echo "#################################"
            echo "Initializing NEPI Storage Folders"
            echo "#################################"
            echo ""

            ###################################
            # Download Storage Extras
            NEPI_STORAGE=/mnt/nepi_storage
            sudo find $NEPI_STORAGE -type d -exec chown ${CONFIG_USER}:${CONFIG_USER} {} +


            success_storage=0
            cd $NEPI_STORAGE
            sudo rm ARCHIVE > /dev/null 2>&1


            storage_latest_link='https://www.dropbox.com/scl/fi/za3sz2q7e0pbcj6m89d8h/nepi_storage-latest.zip?rlkey=eq6u97w6qpqiqblcudqnwj8ud&st=jppfzx1c&dl=0'
            storage_latest_zip=nepi_storage-latest.zip


            if [[ ! -f ${storage_latest_zip} ]]; then
                sudo wget ${storage_latest_link} -O ${storage_latest_zip}
                if [[ "$?" -ne 0 ]]; then
                    echo ""
                    echo "Failed to download NEPI Storage from link: ${storage_latest_link}"
                    echo ""
                    sudo rm ${storage_latest_zip}
                fi
            else
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $storage_latest_zip
            fi

            if [[ -f ${storage_latest_zip} ]]; then
                echo ""
                echo "Unzipping storage folders from ${storage_latest_zip}"
                echo ""
                sudo unzip -o -q $storage_latest_zip
                if [ $? -eq 0 ]; then
                    #sudo rm ${storage_latest_zip} > /dev/null 2>&1
                    success_storage=1
                else
                    echo ""
                    echo "Failed to unzip NEPI Storage file: ${storage_latest_zip}"
                    echo ""
                    #sudo rm ${storage_latest_zip} > /dev/null 2>&1
                fi
            else
                echo ""
                echo "Failed to find NEPI Storage file: ${storage_latest_zip}"
                echo ""
            fi

            if [[ -f ${storage_latest_zip} ]]; then
                sudo rm ${storage_latest_zip} > /dev/null 2>&1
            fi

            if [[ -f ${storage_latest_zip} ]]; then
                sudo rm ${storage_latest_zip} > /dev/null 2>&1
            fi

            sudo find $NEPI_STORAGE -type d -exec chown ${CONFIG_USER}:${CONFIG_USER} {} +

            cd $CURRENT_FOLDER





            ####################################
            # Cleanup

            if [[ "$success_storage" -eq 0 ]]; then
                echo "NEPI Storage Setup Failed"
                echo ""
            else
                echo ""
                echo "NEPI Storage Setup Succeeded"
            fi


            if [[ "$success_storage" -eq 1 && "$success_image" -eq 1 ]]; then
                echo ""
                echo "########################"
                echo "NEPI Docker Storage Init Complete"
                echo "########################"
                echo ""

            fi
        fi
    fi
fi


