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

# This file initializes NEPI Docker Images

sudo -v

CONFIG_USER=nepihost

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
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
DOCKER_CONFIG_UPDATE_FILE=${DOCKER_FOLDER}/nepi_docker_update.sh

########################
# Update Docker Config
echo ""
echo "Updating Docker Config File"

source $DOCKER_CONFIG_UPDATE_FILE
if [[ "$?" -eq 1 ]]; then
    echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
else

    ########################
    # Start Processes
    INSTALL_IMAGE=$1

    if [[ -f $INSTALL_IMAGE ]]; then

        echo "Initializing image from: ${INSTALL_IMAGE}"

        docker_cfg_path=/mnt/nepi_config/docker_cfg

        echo ""
        echo "Stopping all Running Contatiners"
        sudo docker stop $(sudo docker ps -q )  > /dev/null 2>&1
        sudo docker rm $(sudo docker ps -a -q)  > /dev/null 2>&1

        echo ""
        echo "Removing all Docker Images"
        sudo docker rmi -f $(sudo docker images -q)  > /dev/null 2>&1

        echo "Proceeding with the import..."
        INSTALL_IMAGE=$1

        success=0
        if [[ -z $INSTALL_IMAGE ]]; then
            echo "No image file path provide"
        else
            echo ""
            echo "Initializing NEPI Docker nepi_fs_a"
            source ${DOCKER_FOLDER}/nepi_docker_import.sh $INSTALL_IMAGE 'nepi_fs_a'
            if [[ "$?" -eq 0 ]]; then
                success=1
                #########################
                if [[ "$NEPI_FS_AB" -eq 1 ]]; then
                    echo "Checking avail space in ${NEPI_DOCKER}"

                    check_drive=$NEPI_DOCKER
                    check_space=$NEPI_GB_CONTAINER
                    if ! is_space_avail_gb $check_drive $check_space; then
                        echo "Not enough available space () to support NEPI AB Backup/Recovery File System"
                        echo "Disabling NEPI AB File System Support"
                        file=/mnt/nepi_config/docker_cfg/etc/nepi_docker_config.yaml
                        update_yaml_value "NEPI_FS_AB" 0 "$DOCKER_CONFIG_FILE"
                    else
                        echo ""
                        echo "Initializing NEPI Docker nepi_fs_b"
                        source ${DOCKER_FOLDER}/nepi_docker_import.sh $INSTALL_IMAGE 'nepi_fs_b'
                    fi
                fi
            fi

            echo ""
            bash ${DOCKER_FOLDER}/nepi_docker_update.sh
        fi
    else
        echo "Install Image Not Found ${INSTALL_IMAGE}"
    fi
fi


echo ""
echo "--------------------------"
echo "NEPI Image Initialization Complete"
echo ""

