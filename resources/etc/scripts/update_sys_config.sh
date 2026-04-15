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

sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
fi
export CONFIG_USER=$CONFIG_USER

ufile=/home/${CONFIG_USER}/.nepi_bash_utils
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


echo ""
echo "Loading NEPI System Config"
source /mnt/nepi_config/system_cfg/etc/load_system_config.sh
if [[ "$?" -ne 0 ]]; then
    echo "ERROR! Failed to load system configuration values from /mnt/nepi_config/system_cfg/etc/load_system_config.sh"
    return 1
fi


##############################
echo "Got NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
echo "Got NEPI_DEVICE_MD: ${NEPI_DEVICE_MD}"
echo "Got NEPI_DEVICE_SN: ${NEPI_DEVICE_SN}"

# UPDATE config file values
UPDATE_PATH=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
if [[ "$CONFIG_USER" == 'nepi' && -f "$UPDATE_PATH" ]]; then
    
    echo "Updating NEPI System Config File: ${UPDATE_PATH}"
    ###########
    # UPDATE NEPI VERSION
    fw_version=$(cat /opt/nepi/nepi_engine/etc/fw_version.txt | tail -n1)
    fw_version=$(clean_version_string $fw_version)
    if [[ -z "$fw_version" ]]; then
        fw_version=0p0p0        
    fi
    echo "Updating NEPI_VERSION to ${fw_version}"
    update_yaml_value "NEPI_VERSION" $fw_version $UPDATE_PATH


    ###########
    # UPDATE NEPI Python Vesion
    pyver=$(python3 --version | awk '{print $2}')
    if [[ -n "$pyver" ]]; then
        pyver="${pyver%.*}"
    else
        pyver=3
    fi
    echo "Updating NEPI_PYTHON to ${pyver}"
    update_yaml_value "NEPI_PYTHON" $pyver $UPDATE_PATH


    ###########
    # UPDATE CUDA Info
    if is_valid_cuda; then
        hascuda=1
    else
        hascuda=0
    fi

    cudaver=$(get_cuda_version)
    if [[ -n "$cudaver" ]]; then
        cudaver="${cudaver}"
    else
        cudaver=0
    fi
    echo "Updating NEPI_HAS_CUDA to ${hascuda}"
    echo "Updating NEPI_CUDA_VERSION to ${cudaver}"
    update_yaml_value "NEPI_HAS_CUDA" $hascuda $UPDATE_PATH
    update_yaml_value "NEPI_CUDA_VERSION" $cudaver $UPDATE_PATH


    ###########
    sw_desc=$(get_sw_desc)
    if [[ -z "$sw_desc" ]]; then
        sw_desc="unknown"
    fi
    echo "Updating NEPI_SW_DESC to ${sw_desc}"
    update_yaml_value "NEPI_SW_DESC" $sw_desc $UPDATE_PATH


    ###########
    # UPDATE ROS VERSION
    rosver=${ROS_DISTRO}
    echo "Got ROS Version ${rosver}"
    if [[ -z $rosver ]]; then
        rosver=0
    fi
    echo "Updating NEPI_ROS to ${rosver}"
    update_yaml_value "NEPI_ROS" $rosver $UPDATE_PATH


    ###########
    # UPDATE NEPI HW TYPE
    hw_type=$(get_hw_type)
    if [[ -z "$hw_type" ]]; then
        hw_type="unknown"
    fi
    echo "Updating NEPI_HW_TYPE to ${hw_type}"
    update_yaml_value "NEPI_HW_TYPE" $hw_type $UPDATE_PATH



    sudo chown ${CONFIG_USER}:${CONFIG_USER} $UPDATE_PATH
    echo "Updated System Settings in ${UPDATE_PATH}"

else
    echo "Config file not found ${UPDATE_PATH}"
fi







    
