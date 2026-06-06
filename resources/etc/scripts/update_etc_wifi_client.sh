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

# This script updates etc wifi client files and processes

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


system_config_file=${NEPI_CONFIG}/system_cfg/etc/nepi_system_config.yaml

###############################
echo ""
echo "UPDATING ETC WIFI CLIENT"


# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

            if [[ "$NEPI_WIFI_ENABLED" -eq 1 ]]; then


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

                        dlist=$(nmcli -t -f DEVICE,TYPE device status | grep -E 'wifi' | cut -d: -f1)
                        if [[ -n $dlist && "$nepi_wifi_interface" != 'NONE' ]]; then
                            echo "Auto updating wifi interface hw option"
                            if [[ "$dlist" != *"$nepi_wifi_interface" ]]; then
                                echo "Got wifi interface hw options ${dlist}"
                                read -r nepi_wifi_interface _ <<< "$dlist"
                                echo "Updated wifi interface hw options ${nepi_wifi_interface}"
                                if [[ -f "$system_config_file" && "$NEPI_wifi_INTERFACE" == "unknown" ]]; then
                                    export NEPI_WIFI_INTERFACE=$nepi_wifi_interface
                                    update_yaml_value "NEPI_WIFI_INTERFACE" $NEPI_WIFI_INTERFACE $system_config_file
                                    needs_update=1
                                fi
                            else
                                nepi_wifi_interface="unknown"
                            fi
                        fi
                    fi
                    echo "Using wifi Interface ${nepi_wifi_interface}"


                    wifi_ssid=$NEPI_WIFI_CLIENT_ID
                    if [[ -z $wifi_ssid || "$wifi_ssid" == "None" ]]; then
                        wifi_ssid="NONE"
                        NEPI_WIFI_CLIENT_PW="NONE"
                    fi
                    echo "Using wifi ssid ${wifi_ssid}"

                    wifi_pw=$NEPI_WIFI_CLIENT_PW
                    if [[ -z wifi_pw || "$wifi_pw" == "None"  || "$wifi_pw" == 'encrypted' ]]; then
                        wifi_pw="NONE"
                    fi
                    echo "Using wifi pw ${wifi_pw}"

                    if [[ "$wifi_ssid" != "NONE" && "$wifi_pw" != "NONE" ]]; then
                            netconnect_wifi $wifi_ssid $wifi_pw $nepi_wifi_interface
                            update_yaml_value "NEPI_WIFI_CLIENT_ID" $wifi_ssid $system_config_file
                            update_yaml_value "NEPI_WIFI_CLIENT_PW" 'encrypted' $system_config_file

                    fi

            fi 
    fi

fi




# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIFI_CLIENT_UPDATE"
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

