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
echo "UPDATING ETC WIFI ACCESS POINT"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        if [[ "$NEPI_WIFI_ENABLED" -eq 1 ]]; then
            file=${ETC_FOLDER}/network/create_ap
            if [[ -f "$file" ]]; then

                sudo ${file} --stop ${NEPI_WIFI_INTERFACE}

                if [[ "$NEPI_WIFI_ACCESS_POINT_ENABLED" -eq 1 ]]; then
                    if [[ "$NEPI_WIFI_ACCESS_POINT_ID" != '' && "$NEPI_WIFI_ACCESS_POINT_ID" != 'NONE' ]]; then
                        if [[ "$NEPI_WIFI_ACCESS_POINT_PW" != '' && "$NEPI_WIFI_ACCESS_POINT_PW" != 'NONE' ]]; then
                            echo "Updating WiFi Access Point Settings Files with AP ID: ${NEPI_WIFI_ACCESS_POINT_ID}"
                            sudo ${file}  -n --redirect-to-localhost --isolate-clients --daemon \
                                    ${NEPI_WIFI_INTERFACE} \
                                    ${NEPI_WIFI_ACCESS_POINT_ID} \
                                    ${NEPI_WIFI_ACCESS_POINT_PW}
                        else
                            echo "WiFi Access Point Password not set"
                        fi
                    else
                        echo "WiFi Access Point ID not set"
                    fi
                else
                    echo "WiFi Access Point Disabled"
                fi
            else
                echo "NEPI Wifi Access Point Create file not found ${file}"
            fi

        else
            echo "NEPI Wifi not enabled"
        fi
        
    fi

fi


# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIFI_ACCESS_POINT_UPDATE"
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

