#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This file initializes NEPI Docker Images

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

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
                        update_yaml_value "NEPI_FS_AB" 0 "$file"
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

