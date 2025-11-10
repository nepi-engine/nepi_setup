#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script syncs the current folders etc files to the system config folder

export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/homenepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ "$CONFIG_USER" == 'nepihost'  ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepihost/.bashrc
    ufile=/home/nepihost/.nepi_bash_utils
    afile=/home/nepihost/.nepi_docker_aliases
# elif [[ -f "/home/${CONFIG_USER}/.nepi_docker_aliases" ]]; then
#     bfile=/home/${CONFIG_USER}/.bashrc
#     ufile=/home/${CONFIG_USER}/.nepi_bash_utils
#     afile=/home/${CONFIG_USER}/.nepi_docker_aliases
else
    echo "NEPI Aliases bash file not found"
    exit 1
fi

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

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


###################
SYS_BASH_FILE=/opt/nepi/etc/sys_env.bash

if [ ! -f ${SYS_BASH_FILE} ]; then
	echo "ERROR! Could not find ${SYS_BASH_FILE}"
else

    echo ""
    echo "Updating nepi system bash file"
    echo "Using Device ID: ${NEPI_DEVICE_ID}"
    update_value ${SYS_BASH_FILE} "export DEVICE_ID" "export DEVICE_ID=${NEPI_DEVICE_ID}"
    echo "Using Device Model Name: ${NEPI_DEVICE_MD}"
    update_value ${SYS_BASH_FILE} "export DEVICE_TYPE" "export DEVICE_TYPE=${NEPI_DEVICE_MD}"
    echo "Using Device Serial Number: ${NEPI_DEVICE_SN}"
    update_value ${SYS_BASH_FILE} "export DEVICE_SN" "export DEVICE_SN=${NEPI_DEVICE_SN}"



    # Check if system hostname has changed
    if [[ "${HOSTNAME}" != "${NEPI_DEVICE_ID}" ]]; then
        echo "System Hostname has changed, Running ETC hostname update script"
        . /opt/nepi/etc/scripts/update_etc_hostname.sh
    fi

fi






    
