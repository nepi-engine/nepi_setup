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


# This file Logs into a Running Container

sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
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
    
    echo ""
    echo "Cleaning and Fixing Folders"
    #sudo rm -r /tmp/* >/dev/null 2>&1
    sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
    sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_storage
    echo ""  
    ########################
    # Start Processes

    LOGIN_USER=$1
    if [[ -z "$LOGIN_USER" ]]; then
        LOGIN_USER=nepi
        LOGIN_FOLDER="-w /home/nepi"
    fi

    echo "Will log in as user: ${LOGIN_USER}"

    #########################################
    # Connect to the Running Container

    if [[ "$NEPI_RUNNING" -eq 1 ]]; then
        echo "Logging into Running NEPI Container ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG} ID:${NEPI_RUNNING_ID}"
        echo "Logging in as ${LOGIN_USER}"
        sudo docker exec -it -u ${LOGIN_USER} ${LOGIN_FOLDER} $NEPI_RUNNING_ID /bin/bash #-c "su ${NEPI_USER}"
    else
        echo "No Running NEPI Contatainer to Log Into"
    fi
fi




