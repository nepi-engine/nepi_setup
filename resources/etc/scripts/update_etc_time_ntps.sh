#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc chrony time files and processes


export CONFIG_USER=$(id -un 1000)

if [[ -f "/home/nepi/.nepi_system_aliases" ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/homenepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ -f "/home/nepihost/.nepi_docker_aliases" ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepihost/.bashrc
    ufile=/home/nepihost/.nepi_bash_utils
    afile=/home/nepihost/.nepi_docker_aliases
elif [[ -f "/home/${CONFIG_USER}/.nepi_docker_aliases" ]]; then
    bfile=/home/${CONFIG_USER}/.bashrc
    ufile=/home/${CONFIG_USER}/.nepi_bash_utils
    afile=/home/${CONFIG_USER}/.nepi_docker_aliases
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


echo ""
echo "UPDATING ETC TIME NTP SOURCES"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    ###########################################
    if [[ "$NEPI_MANAGES_TIME" -eq 1 ]]; then
        # Install NTP Sources

        echo " "
        echo "Configuring chrony.conf"

        sudo systemctl stop chrony

        source_file=${ETC_FOLDER}/chrony/chrony.conf.blank
        file=/etc/chrony/chrony.conf
        echo "Updating etc file: ${file}"
        if [[ ! -d "/etc/chrony" ]]; then
            sudo mkdir /etc/chrony
        fi
        if [[ -f "${source_file}" ]]; then
            sudo cp -a ${source_file} $file
            sudo chown ${CONFIG_USER}:${CONFIG_USER} $file
      


            if [[ "$NEPI_NTP_IPS" != "NONE" &&  "$NEPI_NTP_IPS" != "None" ]]; then
                echo "Updating NEPI IP in ${file} with NTP Server ${NEPI_NTP_IPS}"
                # update with NTP IP address
APPEND_SECTION="#### NEPI NTP SOURCES #### 
allow ${NEPI_NTP_IPS%.*}/24 
server ${NEPI_NTP_IPS} iburst minpoll 2"
                sudo echo "$APPEND_SECTION" >> $file

            fi
        else
            echo "FAILED TO FIND SOURCE ${source_file}"
        fi  
        ###
        sudo systemctl restart chrony
    fi

fi

# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_TIME_NTPS_UPDATE"
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

