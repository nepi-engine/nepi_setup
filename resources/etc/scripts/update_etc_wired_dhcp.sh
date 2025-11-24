#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc wifi wired dhcp files and processes


sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi
if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then
    CONFIG_USER=nepihost
fi

bfile=/home/${CONFIG_USER}/.bashrc
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
if [[ -v "$1" ]]; then
    if [[ "$1" -eq 0 ]]; then
        LOAD_NEPI_CONFIG=0
    fi
fi

if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi




function nnet(){
    sudo -v
    nepi_ip=$(nipa)
    if [[ -z "$nepi_ip" ]]; then
      return 1
    else
      ping -c 1 -W 1 $nepi_ip > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo "Can't ping NEPI IP address: ${nepi_ip}"

        echo "Restarting Network"
        sudo systemctl restart networking
        wait
        ping -c 1 -W 1 $nepi_ip > /dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo "Failed to connect NEPI IP address: ${nepi_ip}"
        fi
      fi
    fi
}


#################################
echo ""
echo "UPDATING ETC WIRED DHCP"
# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 && "$NEPI_WIRED_DHCP_ENABLED" -eq 1 ]]; then


        if nnet; then
            # This file sets up nepi bash aliases and util functions
            # Check for internet connection by pinging a reliable public DNS server (e.g., Google's 8.8.8.8)
            # -c 1: Send only one ping packet
            # -W 1: Wait for 1 second for a response
            ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1

            # Check the exit status of the ping command
            # 0 indicates success (internet connection)
            # Non-zero indicates failure (no internet connection)
            if [ $? -ne 0 ]; then
            echo "No internet connection detected. Will try and connect"

            echo "Enabling DHCP internet connection"
            echo "Killing existing DHCP clients"
            sudo kill $(ps aux | grep 'dhclient' | awk '{print $2}') >/dev/null 2>&1
            echo "Renewing dhclient"
            sudo dhclient -nw
            sleep 2
            nnet # Restart network
            wait
            if ! pingi; then
                return 1
            fi
            fi
            sudo kill $(ps aux | grep 'dhclient' | awk '{print $2}') >/dev/null 2>&1
        fi


    fi  

fi

# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIRED_DHCP_UPDATE"
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

