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

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi
    source /home/nepi/.nepi_bash_utils
elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
    source /home/nepihost/.nepi_bash_utils
else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${SCRIPT_FOLDER})



SYS_BASH_FILE=/opt/nepi/etc/sys_env.bash

if [ ! -f ${SYS_BASH_FILE} ]; then
	echo "ERROR! Could not find ${SYS_BASH_FILE}"
else

    function update_value(){
    FILE=$1
    KEY=$2
    UPDATE=$3
    if [ -f "$FILE" ]; then
        if grep -q "$KEY" "$FILE"; then
        sed -i "/^$KEY/c\\$UPDATE" "$FILE"
        else
        echo "$UPDATE" | sudo tee -a $FILE
        fi
    else
        echo "File not found ${FILE}"
    fi
    }

    echo ""
    echo "Checking for Valid Config Settings"

    # CHECK FOR VALID DEVICE ID
    # Check for empty string
    if [ -z "$NEPI_DEVICE_ID" ]; then
        echo "ERROR! NEPI ID's can not be blank string."
        return 1
    fi
    # Check that first char is a letter
    if [[ ! "$NEPI_DEVICE_ID" =~ ^[a-zA-Z] ]]; then
        echo "ERROR! The first character or NEPI ID must be a letter."
        return 1
    fi
    # Check if input is only letters numbers and underscores with no spaces
    if [[ ! "$NEPI_DEVICE_ID" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "ERROR! NEPI ID's must be only letters, numbers, and underscores with no spaces."
        return 1
    fi

    # CHECK FOR VALID DEVICE MODEL NAME
    # Check for empty string
    if [ -z "$NEPI_DEVICE_MD" ]; then
        echo "ERROR! NEPI Device Model Name can not be blank string."
        return 1
    fi

    # CHECK FOR VALID DEVICE SN
    # Check for empty string
    if [ -z "$NEPI_DEVICE_SN" ]; then
        echo "ERROR! NEPI Serial Numbers can not be blank string."
        return 1
    fi
    # Check if serial number is valid 6 digit number
    if [[ ! "$NEPI_DEVICE_SN" =~ ^[0-9]{6}$ ]]; then
        echo "'ERROR! $NEPI_DEVICE_SN' is not a valid 6-digit number."
        return 1
    fi

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






    
