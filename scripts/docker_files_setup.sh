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
## Redistributions in source code must retain this top-level comment block, 
## Along with any License Check related code and checks.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    exit 1
fi


# This file configures a NEPI Docker installation environment


if [[ -z "$1" ]]; then
    DEMO_INSTALL=0
else
    DEMO_INSTALL=$1
fi

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepihost'"
    exit 1
fi

sudo -v


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


SOURCE_DOCKER_SCRIPTS_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/docker
SOURCE_DOCKER_CONFIG_FILE=${SOURCE_DOCKER_SCRIPTS_PATH}/nepi_docker_config.yaml

NEPI_CONFIG_PATH=/opt/nepi
NEPI_DOCKER_CONFIG_PATH=${NEPI_CONFIG_PATH}/docker_cfg
NEPI_DOCKER_CONFIG_FILE=${NEPI_DOCKER_CONFIG_PATH}/nepi_docker_config.yaml

############
# Install NEPI Docker Sciprts
SOURCE_PATH=${SOURCE_DOCKER_SCRIPTS_PATH}
UPDATE_PATH=/opt/nepi/docker_cfg

echo "Updating NEPI Folder ${UPDATE_PATH} from ${SOURCE_PATH}"
if [[ -n "$SOURCE_PATH" && "$SOURCE_PATH" != '/' ]]; then

    if [[ ! -d "$UPDATE_PATH" ]]; then
        sudo mkdir -p $UPDATE_PATH 
    fi
    sudo rm -r $UPDATE_PATH/*

    sudo rsync -arh  ${SOURCE_PATH}/ ${UPDATE_PATH}/
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod +x ${UPDATE_PATH}/*
fi


script_file=nepi_docker_sync.sh
script_path=$(dirname "${SCRIPT_FOLDER}")/resources/docker/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    exit 1
fi

####################################
# Run NEPI Bash Setup Script


script_file=nepi_files_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    exit 1
fi



