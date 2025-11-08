#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file runs script checks and setup processes


####################
# Init Variables

CONFIG_USER=$(id -un 1000)
if [[ "$CONFIG_USER" != 'nepi' || "$CONFIG_USER" != 'nepihost' ]]; then
    echo "This script must be run by user 'nepi' or 'nepihost'"
else


    if [[ -z "$SCRIPT_FOLDER" ]]; then
        SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
    fi

    ####################
    # Run Checks

    echo "Checking Requirements"

    sudo -v

    if command -v yq &>/dev/null; then
        : # Do nothing here
    else
        echo "Installing yq software"
        sudo add-apt-repository ppa:rmescandon/yq -y
        sudo apt update
        sudo apt install yq -y
    fi
    if command -v yq &>/dev/null; then
        : # Do nothing here
    else
        echo "EXITING"
        echo "yq application is not installed"
        echo "Connect to internet and rerun the script"
        exit 1
    fi

    # if [[ "$USER" != "$CONFIG_USER" ]]; then
    #     echo "This script must be run by user account ${CONFIG_USER}."
    #     echo "Log in as ${CONFIG_USER} and run again"
    #     exit 1
    # fi


    ##############
    # Initialize and Load NEPI SYSTEM CONFIG FILE

    SOURCE_CONFIG_FOLDER=$(dirname "$SCRIPT_FOLDER")/config
    SOURCE_CONFIG_FILE=${SOURCE_CONFIG_FOLDER}/nepi_system_config.yaml


    USER_CONFIG_FOLDER=/home/${CONFIG_USER}
    USER_CONFIG_FILE=${USER_CONFIG_FOLDER}/nepi_system_config.yaml
    USER_CONFIG_LOAD_FILE=${USER_CONFIG_FOLDER}/load_system_config.sh
    USER_CONFIG_EDIT_FILE=${USER_CONFIG_FOLDER}/nepi_system_config.sh


    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SOURCE_CONFIG_FOLDER
    if [[ ! -f "$USER_CONFIG_FILE" ]]; then
        sudo cp -r -p "${SOURCE_CONFIG_FOLDER}/nepi_system_config.yaml" ${USER_CONFIG_FILE}
    else
        sync_yaml_files ${SOURCE_CONFIG_FOLDER}/nepi_system_config.yaml ${USER_CONFIG_FILE}
    fi
    sudo cp -r -p "${SOURCE_CONFIG_FOLDER}/load_system_config.sh" ${USER_CONFIG_LOAD_FILE}
    sudo cp -r -p "${SOURCE_CONFIG_FOLDER}/nepi_system_config.sh" ${USER_CONFIG_EDIT_FILE}



    source $USER_CONFIG_LOAD_FILE
    if [[ "$1" -ne 0 ]]; then
        echo "Failed to find load config file at: ${USER_CONFIG_LOAD_FILE}"
        exit 1
    fi

    echo "Requirements check complete"
fi


