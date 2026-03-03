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


# This file Switches a Running Containers
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

    ########################
    # Start Processes
    ########################

    if [[ $NEPI_AB_FS -eq 1 ]]; then
        NEPI_DOCKER_CONFIG_PATH=${DOCKER_FOLDER}/nepi_docker_config.yaml
        #echo $NEPI_DOCKER_CONFIG_PATH

        echo "Switcing NEPI ACTIVE CONTAINER from ${NEPI_ACTIVE_FS} to ${NEPI_INACTIVE_FS}"

        ### SET INACTIVE DATA AS ACTIVE DATA
        update_yaml_value "NEPI_ACTIVE_FS" "${NEPI_INACTIVE_FS}" "${NEPI_DOCKER_CONFIG_PATH}"
        update_yaml_value "NEPI_INACTIVE_FS" "${NEPI_ACTIVE_FS}" "${NEPI_DOCKER_CONFIG_PATH}"
        update_yaml_value "NEPI_FS_SWITCH" 0 "${NEPI_DOCKER_CONFIG_PATH}"

        ########################
        # Update Docker Config
        echo ""
        echo "Updating Docker Config File"
        bash ${DOCKER_FOLDER}/nepi_docker_update.sh
        wait
    fi

fi

