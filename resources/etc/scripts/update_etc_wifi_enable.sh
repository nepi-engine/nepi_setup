#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc wifi access point files and processes


if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi
    source /home/nepi/.nepi_bash_utils
    wait
elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
    source /home/nepihost/.nepi_bash_utils
    wait
else
    echo ".nepi_bash_utils file not found"
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

echo ""
echo "UPDATING ETC WIFI ENABLE"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        echo "Disabling WiFi Adapter on interface ${NEPI_WIFI_INTERFACE}"
        sudo ip link set ${NEPI_WIFI_INTERFACE} down        
        if [[ "$NEPI_WIFI_ENABLED" -eq 1 ]]; then

            if ip link show ${NEPI_WIFI_INTERFACE} &>/dev/null; then
                echo "${NEPI_WIFI_INTERFACE} exists."

                if [[ "$NEPI_WIFI_ENABLED" -eq 1 ]]; then
                    echo "Enabling WiFi Adapter on interface ${NEPI_WIFI_INTERFACE}"
                    sudo ip link set ${NEPI_WIFI_INTERFACE} up 
                fi
            else
                echo "NEPI Wifi Interface ${NEPI_WIFI_INTERFACE} not found. Disabling WiFi support"
                config_setting="NEPI_WIFI_ENABLED"
                config_file=${ETC_FOLDER}/nepi_system_config.yaml
                update_val=0
                update_yaml_value $config_setting $update_val $config_file
                export NEPI_WIFI_ENABLED=0
            fi
        else
            echo "NEPI Wifi not enabled"
        fi
        
    fi

fi


# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIFI_ENABLE_UPDATE"
if [[ "$NEPI_IN_CONTAINER" -eq 1 ]]; then
    echo "Updating NEPI Docker Setting ${docker_config_setting}"
    docker_config_file=${NEPI_CONFIG}/docker_cfg/nepi_docker_config.yaml
    if [[ "$USER" == "$NEPI_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        update_val=1
        if [[ -f "$docker_config_file" ]]; then
            update_yaml_value $docker_config_setting $update_val $docker_config_file
        fi
    elif [[ "$USER" == "$NEPI_HOST_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        update_val=0
        if [[ -f "$docker_config_file" ]]; then
            update_yaml_value $docker_config_setting $update_val $docker_config_file
        fi
    fi
fi

