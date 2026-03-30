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

LITE_INSTALL=$1

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $LITE_INSTALL
if [[ "$?" -ne 0 ]]; then
    return 
fi

# This file downloads the Latest NEPI Docker Image to the NEPI Devices Import Folder


CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER
NEPI_USER_ID=1000



SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

ninet > /dev/null 2>&1

if ! is_valid_internet > /dev/null; then
    echo "No Internet Connection Detected.  Connect and rerun this script"

else

    echo ""
    echo "########################"
    echo "NEPI DOCKER IMAGE INIT"
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
            echo "Run 'nepihostsetup' to fix path location and try again"
        elif [[ ! -d "$NEPI_IMPORT_PATH" ]]; then
            echo "NEPI Docker Import Folder not found at ${NEPI_IMPORT_PATH}"
            echo "Create import path or run 'nepihostsetup' to fix path location and try again"
        else

            CURRENT_FOLDER=$(pwd)


            echo ""
            echo "#################################"
            echo "Installing the Latest NEPI Image"
            echo ""

            sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_IMPORT_PATH}
            sudo chmod -R +x ${NEPI_IMPORT_PATH}/*

            success_image=0
            cd $NEPI_IMPORT_PATH

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
                return 
            fi

            staging_yaml_file=nepi_download_staging.yaml
            staging_yaml_path=${NEPI_IMPORT_PATH}/${staging_yaml_file}
            staging_image_file=nepi_download_staging.img
            staging_image_path=${NEPI_IMPORT_PATH}/${staging_image_file}
            # Cleanup
            if [[ -f "$staging_yaml_path" ]]; then
                sudo rm $staging_yaml_path
            fi
            if [[ -f "$staging_image_path" ]]; then
                sudo rm $staging_image_path
            fi
            sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_IMPORT_PATH}


            if [[ "$HW_TYPE" == 'jetson' ]]; then
                nepi_latest_yaml_link='https://www.dropbox.com/scl/fi/j3ewsgmy22f6tsxyr70i7/nepi-jetson-latest.yaml?rlkey=p5imjukvwlxuonw9v5burnr0j&st=acftb28k&dl=0'
                nepi_latest_image_link='https://www.dropbox.com/scl/fi/j3ewsgmy22f6tsxyr70i7/nepi-jetson-latest.yaml?rlkey=p5imjukvwlxuonw9v5burnr0j&st=06e983zv&dl=0'
            else
                echo "No NEPI Image File available for hardware architecture ${arch_val}"
                return     
            fi

            ################
            #Check if file exists
            echo ""
            echo "Downloading NEPI Docker Image filename file: ${staging_yaml_file}"
            echo ""
            sudo wget ${nepi_latest_yaml_link} -O ${staging_yaml_file}

            
            if [[ ! -f "$staging_yaml_path" ]]; then
                echo ""
                echo "Failed to download NEPI filename file from link: ${nepi_latest_yaml_link}"
                echo ""
            else

                echo ""
                echo "Download Succeeded"
                echo ""

                ### Get Image info from yaml file
                NEPI_LATEST_FILENAME=''
                NEPI_LATEST_GB=''
                load_yaml_file $staging_yaml_path
                if [[ -z "$NEPI_LATEST_FILENAME" || -z "$NEPI_LATEST_GB" ]]; then
                    echo ""
                    echo "Failed to get NEPI Image name from : ${staging_yaml_path}"
                    echo ""
                else
    
                    nepi_image_path=${NEPI_IMPORT_PATH}/${NEPI_LATEST_FILENAME}
                    echo ""
                    echo "Installing NEPI Docker Image: ${NEPI_LATEST_FILENAME}"
                    echo ""
                    if [[ -f "$nepi_image_path" ]]; then
                        echo ""
                        echo "Latest NEPI Docker Image allready installed: ${NEPI_LATEST_FILENAME}"
                        echo ""
                        success_image=1
                    else

                        echo ""
                        echo "Checking for available space NEPI Docker Image: ${NEPI_LATEST_FILENAME}"
                        echo ""
                        avail_space_gb=$(path_space_gb $NEPI_IMPORT_PATH)
                        req_space_gb=$NEPI_LATEST_GB
                        if [[ "$avail_space_gb" -lt "$req_space_gb" ]]; then
                            need_space_gb=$((req_space_gb - avail_space_gb))
                            echo "Not enough free drive space in import path ${NEPI_IMPORT_PATH}"
                            echo "Free up ${need_space_gb} GB in that folders partition and try again"
                        else
                            echo ""
                            echo "Downloading NEPI Docker Image file: ${staging_image_file}"
                            echo ""
                            
                            sudo wget ${nepi_latest_image_link} -O ${staging_image_file}
                            if [[ "$?" -ne 0 ]]; then
                                    echo ""
                                    echo "Failed to download NEPI image file from link: ${nepi_latest_image_link}"
                                    echo ""
                            fi
                            if [[ -f "$staging_image_path" ]]; then
                                echo ""
                                echo "NEPI Docker Image downloaded to: ${staging_image_path}"
                                echo "Renaming to: ${NEPI_LATEST_FILENAME}"
                                echo ""
                                sudo mv $staging_image_path $nepi_image_path
                                success_image=1
                            fi
                        fi
                    fi
                
                fi
            fi                        
            # Cleanup
            if [[ -f "$staging_yaml_path" ]]; then
                sudo rm $staging_yaml_path
            fi
            if [[ -f "$staging_image_path" ]]; then
                sudo rm $staging_image_path
            fi
            sudo chown -R ${NEPI_USER_ID}:${NEPI_USER_ID} ${NEPI_IMPORT_PATH}
            sudo chmod -R +x ${NEPI_IMPORT_PATH}/*
            cd $CURRENT_FOLDER



            ####################################
            # Cleanup

            echo ""
            echo "########################"
            if [[ "$success_image" -eq 0 ]]; then
                echo ""
                echo "NEPI Image Install Failed"
            else
                echo ""
                echo "NEPI Image Install Succeeded"
            fi


            if [[ "$success_storage" -eq 1 && "$success_image" -eq 1 ]]; then
                echo ""
                echo "########################"
                echo "NEPI Docker Image Init Complete"
                echo "########################"
                echo ""

            fi
        fi
    fi
fi

