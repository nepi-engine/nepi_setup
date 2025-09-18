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

#########################################
NEPI_DOCKER_CONFIG_PATH=${SCRIPT_FOLDER}/nepi_docker_config.yaml
#echo $NEPI_DOCKER_CONFIG_PATH

echo "Switcing NEPI ACTIVE CONTAINER from ${NEPI_ACTIVE_FS} to ${NEPI_INACTIVE_FS}"

### SET INACTIVE DATA AS ACTIVE DATA
update_yaml_value "NEPI_ACTIVE_FS" "${NEPI_INACTIVE_FS}" "${NEPI_DOCKER_CONFIG_PATH}"
update_yaml_value "NEPI_INACTIVE_FS" "${NEPI_ACTIVE_FS}" "${NEPI_DOCKER_CONFIG_PATH}"
update_yaml_value "NEPI_FS_SWITCH" 0 "${NEPI_DOCKER_CONFIG_PATH}"


source ${SCRIPT_FOLDER}/load_docker_config.sh


# echo "Clearing NEPI Volume /opt/nepi"
# rfolder=/opt/nepi
# if [ -f "$rfolder" ]; then
#     sudo rm -r ${rfolder}/*
# fi

########################
# Update NEPI Docker Variables from nepi_docker_config.yaml

########################

#######
# Start Switched Container
#  . ./start_nepi_docker


