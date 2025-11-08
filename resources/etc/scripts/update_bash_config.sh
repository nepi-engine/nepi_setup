#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates bash stored system values



SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${SCRIPT_FOLDER})


ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -n "$1" ]]; then
    LOAD_NEPI_CONFIG=$1
fi

if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases

elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_docker_aliases

else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 
source $ufile


echo ""
echo "UPDATING BASH VARIABLES"

if is_valid_did $NEPI_DEVICE_ID; then
    update_text_value $bfile "export NEPI_DEVICE_ID" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"
fi
if is_valid_ipv4 $NEPI_IP; then
    update_text_value $bfile "export NEPI_IP" "export NEPI_IP=${NEPI_IP}"
fi

sudo cp $bfile /root/.bashrc




    
