#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file Switches a Running Containers

sudo -v

CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


########################
# Update Docker Config
echo ""
echo "Updating Docker Config File"
bash ${SCRIPT_FOLDER}/nepi_docker_update.sh
wait
########################
# Load NEPI DOCKER
CONFIG_SOURCE=${SCRIPT_FOLDER}/nepi_docker_config.yaml
source ${SCRIPT_FOLDER}/load_docker_config.sh
if [[ "$?" -eq 1 ]]; then
    echo "Failed to load ${CONFIG_SOURCE}"

else


    ########################
    # Start Processes

    LOGIN_USER=$1
    if [[ -z "$LOGIN_USER" ]]; then
        LOGIN_USER=nepi
    fi

    echo "Will log in as user: ${LOGIN_USER}"

    #########################################
    # Connect to the Running Container

    if [[ "$NEPI_RUNNING" -eq 1 ]]; then
        echo "Logging into Running NEPI Container ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG} ID:${NEPI_RUNNING_ID}"
        echo "Logging in as ${LOGIN_USER}"
        sudo docker exec -it -u ${LOGIN_USER} $NEPI_RUNNING_ID /bin/bash #-c "su ${NEPI_USER}"
    else
        echo "No Running NEPI Contatainer to Log Into"
    fi
fi




