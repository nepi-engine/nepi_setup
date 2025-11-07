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
elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


UPDATE_PATH=/opt/nepi/nepi_engine/share/nepi_env/launch/nepi_base.launch
# UPDATE config file values
if [[ "$CONFIG_USER" == 'nepi' && -f "$UPDATE_PATH" ]]; then
    
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $UPDATE_PATH
    echo "Updating settings in ${UPDATE_PATH}"

    # UPDATE NEPI VERSION
    fw_version=$(cat /opt/nepi/nepi_engine/etc/fw_version.txt)
    if [[ -z "$fw_version" ]]; then
        fw_version=unknown
    else
        # Remove spaces
        fw_version="${fw_version// /}"
        # Remove dashes
        fw_version="${fw_version//-/}"
        # Lowercase
        fw_version="${fw_version,,}"
    fi
    update_yaml_value "NEPI_VERSION" $fw_version $UPDATE_PATH

    # UPDATE NEPI Python Vesion
    pyver=$(python3 --version | awk '{print $2}')
    if [[ -n "$pyver" ]]; then
        pyver="${pyver%.*}"
    else
        pyver=3
    fi
    update_yaml_value "NEPI_PYTHON" $pyver $UPDATE_PATH


    # UPDATE CUDA Info
    if is_valid_cuda; then
        hascuda=1
    else
        hascuda=0
    fi

    cudaver=$(is_valid_cuda)
    if [[ -n "$cudaver" ]]; then
        cudaver="${cudaver}"
    else
        cudaver=0
    fi
    update_yaml_value "NEPI_HAS_CUDA" $hascuda $UPDATE_PATH
    update_yaml_value "NEPI_CUDA_VERSION" $cudaver $UPDATE_PATH

    sw_desc="CUDA${cudaver//./p}"
    update_yaml_value "NEPI_SW_DESC" $sw_desc $UPDATE_PATH


    # UPDATE ROS VERSION
    rosver=${ROS_DISTRO}
    echo "Got ROS Version ${rosver}"
    if [[ -z "$rosver" ]]; then
        rosver=0
    fi
    echo "Updating NEPI_ROS to ${rosver}"
    update_yaml_value "NEPI_ROS" $rosver $UPDATE_PATH


    # UPDATE NEPI HW TYPE
    if is_valid_jetson; then
        narch=jetson
    elif is_valid_arm64; then
        narch=arm64
    elif is_valid_amd64; then
        narch=amd64
    else
        narch=uknown
    fi
    update_yaml_value "NEPI_HW_TYPE" $narch $UPDATE_PATH

else
    echo "Config file not found ${UPDATE_PATH}"
fi

# Update system config with latest nepi config file
if [[ "$ETC_FOLDER" != "/etc" && ! -z "$ETC_FOLDER" ]]; then

    SOURCE_PATH=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
    UPDATE_PATH=${ETC_FOLDER}/nepi_system_config.yaml  
    echo "Syncing NEPI System Config File from ${SOURCE_PATH} to ${UPDATE_PATH}"
    sudo cp -p $SOURCE_PATH $UPDATE_PATH
fi





    
