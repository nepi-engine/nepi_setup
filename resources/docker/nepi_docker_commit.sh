#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script Stops a Running NEPI Container

source /home/${USER}/.nepi_bash_utils
wait

# Load NEPI SYSTEM CONFIG
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=${SCRIPT_FOLDER}/etc
if [ -d "$ETC_FOLDER" ]; then
    echo "Failed to find ETC folder at ${ETC_FOLDER}"
    exit 1
fi
source ${ETC_FOLDER}/load_system_config.sh
wait
if [ $? -eq 1 ]; then
    echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
    exit 1
fi

# Load NEPI DOCKER
CONFIG_SOURCE=${SCRIPT_FOLDER}/nepi_docker_config.yaml
source ${SCRIPT_FOLDER}/load_docker_config.sh
wait
if [ $? -eq 1 ]; then
    echo "Failed to load ${CONFIG_SOURCE}"
    exit 1
fi

########################


########################
# Commit Running Command
########################
# Commit the Running Container
if [[ ! -v NEPI_RUNNING ]]; then
    if [[ ( -v NEPI_RUNNING && "$NEPI_RUNNING" -eq 1 ) ]]; then
        echo "Stopping Running NEPI Docker Process ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG} ID:${NEPI_RUNNING_ID}"
        dcommit $NEPI_RUNNING_ID ${1}:${2}
    else
        echo "No Running NEPI Contatainer to Commit"
    fi
else
    echo "Failed to Read NEPI Docker Config File"
    exit 1
fi 

