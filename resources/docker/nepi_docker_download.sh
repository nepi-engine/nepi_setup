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

DOWNLOAD_LINK=$1


if [[ -z "$DOWNLOAD_LINK" ]]; then
    echo "No Download Link provided"
else


    sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    if [[ -d "/home/nepihost" ]]; then
        CONFIG_USER=nepihost
    else
        CONFIG_USER=$(id -nu 1000)
    fi
fi
export CONFIG_USER=$CONFIG_USER

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

    ninet > /dev/null 2>&1

    if ! is_valid_internet > /dev/null; then
        echo "No Internet Connection Detected.  Connect and rerun this script"

    else

        echo ""
        echo "Downloading NEPI DOCKER IMAGE from ${DOWNLOAD_LINK}"
        echo ""

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


                sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_IMPORT_PATH}
                sudo chmod -R +x ${NEPI_IMPORT_PATH}/*

                success_image=0
                cd $NEPI_IMPORT_PATH

                staging_image_file=nepi_download_staging.zip
                staging_image_path=${NEPI_IMPORT_PATH}/${staging_image_file}
                # Cleanup
                if [[ -f "$staging_image_path" ]]; then
                    sudo rm $staging_image_path
                fi
                sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${NEPI_IMPORT_PATH}

            
                echo ""
                echo "Downloading NEPI Docker Image to staging file: ${staging_yaml_file}"
                echo ""
                echo "The Download Process will take several minutes to complete"
                echo ""
                curl -L -o "${staging_image_file}" -O "${DOWNLOAD_LINK}?dl=1"
                if [[ "$?" -ne 0 ]]; then
                        echo ""
                        echo "Failed to download NEPI image file from link: ${DOWNLOAD_LINK}"
                        echo ""
                fi
                if [[ -f "$staging_image_path" ]]; then
                    echo ""
                    echo "NEPI Docker Image downloaded to: ${staging_image_path}"
                    nepi_image=$(zipinfo -1 ${staging_image_path} | tail -n 1)
                    if [[ -z $nepi_image ]]; then
                        echo "Download zip file does not contain any files"

                    elif [[ ${nepi_image##*.} != 'tar' ]]; then
                        echo "Download zip file does not contain a nepi_image file"

                    else

                            echo "Unzipping nepi image ${nepi_image}"
                            echo ""
                            sudo unzip -o -q $staging_image_path 2> /dev/null
                            nepi_image_path=${NEPI_IMPORT_PATH}/${nepi_image}
                            if [[ -f $nepi_image_path ]]; then
                                success_image=1
                            else
                                echo ""
                                echo "Failed to unzip NEPI Storage file: ${staging_image_path}"
                                echo ""
                            fi

                    fi
                else
                    echo ""
                    echo "Failed to find NEPI Storage file: ${staging_image_path}"
                    echo ""
                fi




                # Cleanup
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
                    echo "NEPI Image Download Failed"
                else
                    echo ""
                    echo "NEPI Image Download Succeeded"
                    echo ""
                    echo "Starting Import Process"
                    import_path=${NEPI_STORAGE}/nepi_images
                    image_path=${import_path}/${nepi_image}
                    echo "Calling NEPI Import script with file ${image_path}"
                    if [[ -f "$image_path" ]]; then
                        bash ${NEPI_DOCKER_CONFIG}/nepi_docker_import.sh $image_path
                    else
                        echo "No NEPI Image Files Found in: ${import_path}"
                    fi  

                fi

            fi
        fi
    fi
fi