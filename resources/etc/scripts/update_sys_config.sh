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
    ufile=/home/nepi/.nepi_bash_utils
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

# LOAD_NEPI_CONFIG=1
# if [[ -n "$1" ]]; then
#     LOAD_NEPI_CONFIG=$1
# fi

# if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v NEPI_USER ]]; then
#     # Load System Config File
#     source ${ETC_FOLDER}/load_system_config.sh
#     if [ $? -eq 1 ]; then
#         echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
#         exit 1
#     fi
# fi


##############################


UPDATE_PATH=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml

# UPDATE config file values
if [[ "$CONFIG_USER" == 'nepi' && -f "$UPDATE_PATH" ]]; then
    
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $UPDATE_PATH
    echo "Updating System Settings in ${UPDATE_PATH}"


    ###########
    # UPDATE NEPI VERSION
    fw_version=$(cat /opt/nepi/nepi_engine/etc/fw_version.txt)
    if [[ -z "$fw_version" ]]; then
        fw_version=0p0p0
    else
        # Remove spaces
        fw_version=$(clean_vesion_string $fw_version)
    fi
    update_yaml_value "NEPI_VERSION" $fw_version $UPDATE_PATH


    ###########
    # UPDATE NEPI Python Vesion
    pyver=$(python3 --version | awk '{print $2}')
    if [[ -n "$pyver" ]]; then
        pyver="${pyver%.*}"
    else
        pyver=3
    fi
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
    update_yaml_value "NEPI_HAS_CUDA" $hascuda $UPDATE_PATH
    update_yaml_value "NEPI_CUDA_VERSION" $cudaver $UPDATE_PATH


    ###########
    sw_desc=$(get_sw_desc)
    if [[ -z "$sw_desc" ]]; then
        sw_desc="unknown"
    fi
    update_yaml_value "NEPI_SW_DESC" $sw_desc $UPDATE_PATH


    ###########
    # UPDATE ROS VERSION
    rosver=${ROS_DISTRO}
    echo "Got ROS Version ${rosver}"
    if [[ -z "$rosver" ]]; then
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
    update_yaml_value "NEPI_HW_TYPE" $hw_type $UPDATE_PATH

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





    
