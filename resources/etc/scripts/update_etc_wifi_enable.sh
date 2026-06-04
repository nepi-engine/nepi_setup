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
## Redistributions in source code must retain this top-level comment block.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##

# This script updates etc wifi access point files and processes

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

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -v $1 ]]; then
    if [[ $1 -eq 0 ]]; then
        LOAD_NEPI_CONFIG=0
        #echo "Skipping NEPI System Config load"
    fi
fi

if [[ $LOAD_NEPI_CONFIG -eq 1 ]]; then
    # Load System Config File
    #echo "Loading NEPI SYSTEM CONFIG"
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi


system_config_file=${NEPI_CONFIG}/system_cfg/nepi_system_config.yaml

################################

echo ""
echo "UPDATING ETC WIFI ENABLE"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    needs_update=0

    if ! is_wifi_hw; then
        echo "No WiFi Hardware Detected"
    else
            nepi_wifi_interface=$NEPI_WIFI_INTERFACE
            if [[ "$NEPI_WIFI_INTERFACE" != 'NONE' ]]; then
                nepi_wifi_interface="unknown"
                nepi_wifi_interface=$NEPI_WIFI_INTERFACE
                if [[ -z $nepi_wifi_interface ]]; then
                    nepi_wifi_interface=$(netget_hw $nepi_wifi_name)
                    echo "Got wifi interface name and hardware  ${nepi_wifi_name}: ${nepi_wifi_interface}"
                    if [[ -z $nepi_wifi_interface ]]; then
                        nepi_wifi_interface="unknown"
                    fi   
                fi       

                dlist=$(nmcli -t -f DEVICE,TYPE device status | grep -E 'wifi' | grep  -v 'wifi-' | cut -d: -f1)
                if [[ -n $dlist && "$nepi_wifi_interface" != 'NONE' ]]; then
                    echo "Auto updating wifi interface hw option"
                    if [[ "$dlist" != *"$nepi_wifi_interface" ]]; then
                        echo "Got wifi interface hw options ${dlist}"
                        read -r nepi_wifi_interface _ <<< "$dlist"
                        echo "Updated wifi interface hw options ${nepi_wifi_interface}"
                        if [[ -f "$system_config_file" && "$NEPI_WIFI_INTERFACE" == "unknown" ]]; then
                            export NEPI_WIFI_INTERFACE=$nepi_wifi_interface
                            update_yaml_value "NEPI_WIFI_INTERFACE" $NEPI_WIFI_INTERFACE $system_config_file
                            needs_update=1
                        fi
                    else
                        nepi_wifi_interface="unknown"
                    fi
                fi
            fi
            echo "Using Wifi Interface ${nepi_wifi_interface}"


            wifi_enabled=$NEPI_WIFI_ENABLED
            if [[ -z $wifi_enabled ]]; then
                wifi_enabled=1
                if [[ -f "$system_config_file" ]]; then
                    export NEPI_WIFI_ENABLED=$wifi_enabled
                    update_yaml_value "NEPI_WIFI_ENABLED" $NEPI_WIFI_ENABLED $system_config_file
                    needs_update=1
                fi
            fi    
            echo "Using Wifi Enabled ${wifi_enabled}"


            if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then
                if netget_info $nepi_wifi_interface; then 
                    if [[ $wifi_enabled -eq 1 ]]; then
                        echo "Enabling WiFi ${wifi_enabled}"
                        netenable_wifi $nepi_wifi_interface
                    else
                        echo "Disabling WiFi ${wifi_enabled}"
                        netdisable_wifi $nepi_wifi_interface
                    fi
                fi
            fi
    fi
fi


# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIFI_ENABLE_UPDATE"
if [[ "$NEPI_IN_CONTAINER" -eq 1 ]]; then
    echo "Updating NEPI Docker Setting ${docker_config_setting}"
    docker_config_file=${NEPI_CONFIG}/docker_cfg/nepi_docker_config.yaml
    if [[ "$CONFIG_USER" == "$NEPI_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        update_val=1
        if [[ -f "$docker_config_file" ]]; then
            update_yaml_value $docker_config_setting $update_val $docker_config_file
        fi
    elif [[ "$CONFIG_USER" == "$NEPI_HOST_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        update_val=0
        if [[ -f "$docker_config_file" ]]; then
            update_yaml_value $docker_config_setting $update_val $docker_config_file
        fi
    fi
fi

