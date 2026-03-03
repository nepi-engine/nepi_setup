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


# This file Creates and Imports a new NEPI Docker Image from a Running Container

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
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

    if [[ "$NEPI_RUNNING" -eq 1 ]]; then
        echo "Exporting Running NEPI Container ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG} ID:${NEPI_RUNNING_ID}"
        bash ${NEPI_DOCKER_CONFIG}/nepi_docker_export.sh #clean
        wait
        echo ""
        echo "Updating Docker Config File"
        bash ${DOCKER_FOLDER}/nepi_docker_update.sh
        wait        

        if [[ -f "$NEPI_EXPORT_FILE" ]]; then
            echo "Importing NEPI Docker Image ${NEPI_EXPORT_FILE}"
            bash ${NEPI_DOCKER_CONFIG}/nepi_docker_import.sh $NEPI_EXPORT_FILE
            wait
        else
            echo "Docker Image Failed to export to ${NEPI_EXPORT_FILE}"
        fi


    else
        echo "No Running NEPI Contatainer to Create Image From"
    fi
fi




