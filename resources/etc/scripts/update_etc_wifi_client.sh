#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc wifi client files and processes

if [[ "$(id -un 1000)" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ -f "/home/${USER}/.nepi_docker_aliases" ]]; then
    CONFIG_USER=${USER}
    bfile=/home/${USER}/.bashrc
    ufile=/home/${USER}/.nepi_bash_utils
    afile=/home/${USER}/.nepi_docker_aliases
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

###############################
echo ""
echo "UPDATING ETC WIFI CLIENT"


# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        if [[ "$NEPI_WIFI_ENABLED" -eq 1 ]]; then

               echo "Updating WiFi Client Settings Files"

                source_path=${NEPI_CONFIG}/system_cfg/etc/wpa_supplicant
                update_path=/etc/wpa_supplicant

                if [ -d "$source_path" ]; then

                    if [[ "$NEPI_WIFI_CLIENT_ENABLED" -eq 1 ]]; then



                        # WiFi Client Connect Update
                        # NEPI_WIFI_INTERFACE=wlan0
                        # NEPI_WIFI_CLIENT_ID=Plutarski_Lab
                        # NEPI_WIFI_CLIENT_PW=2065255002

                        # echo "Checking Client Network Availability"
                        # sudo iw dev ${NEPI_WIFI_INTERFACE} scan

                        WPA_SUPPLICANT_CONF_PATH=/etc/wpa_supplicant/wpa_supplicant.conf


                        echo "Killing existing DHCP clients"
                        sudo kill $(ps aux | grep 'dhclient' | awk '{print $2}') >/dev/null 2>&1

                        echo "Disabling WiFi Connection"
                        sudo ip link set ${NEPI_WIFI_INTERFACE} down        
                        wait


                        echo "Updating Client Connection Credetials file ${WPA_SUPPLICANT_CONF_PATH}"
                        sudo chmod +x -R /etc/network/interfaces.d
                        sudo bash -c "cat /dev/null > $WPA_SUPPLICANT_CONF_PATH"

                        if [[ "$NEPI_WIFI_CLIENT_ID" == "None" || "$NEPI_WIFI_CLIENT_ID" == "" ]]; then
                            NEPI_WIFI_CLIENT_ID="NONE"
                            NEPI_WIFI_CLIENT_PW="NONE"
                        fi

                        if [[ "$NEPI_WIFI_CLIENT_PW" == "None" || "$NEPI_WIFI_CLIENT_PW" == "" ]]; then
                            NEPI_WIFI_CLIENT_PW="NONE"
                        fi

                        if [[ "$NEPI_WIFI_CLIENT_ID" != "NONE" ]]; then
                            if [[ "$NEPI_WIFI_CLIENT_PW" == "NONE" ]]; then
                                sudo "network={ \n\tssid=${NEPI_WIFI_CLIENT_ID} \n\tkey_mgmt=NONE \n}" | sudo tee -a $WPA_SUPPLICANT_CONF_PATH
                            else
                                sudo wpa_passphrase "$NEPI_WIFI_CLIENT_ID" "$NEPI_WIFI_CLIENT_PW" | sudo tee -a $WPA_SUPPLICANT_CONF_PATH
                            fi
                        fi

                        echo "Updated Client Connection Credetials"
                        sudo bash -c "cat $WPA_SUPPLICANT_CONF_PATH"


                        echo "Enabling WiFi Client"
                        sudo ip link set ${NEPI_WIFI_INTERFACE} up 
                        wait

                        echo "Killing Existing Client Connections"
                        sudo killall wpa_supplicant
                        wait
                        sleep 1

                        echo "Updatig WPA Supplicant Settings"
                        sudo wpa_supplicant -B -i ${NEPI_WIFI_INTERFACE} -c $WPA_SUPPLICANT_CONF_PATH #>/dev/null 2>&1
                        wait
                        sleep 1

                        echo "Reseting WiFi Service"
                        sudo systemctl restart wpa_supplicant.service
                        #wait
                        #sudo systemctl status wpa_supplicant.service

                        # echo "Checking Client Connection Status"
                        # sudo iw ${NEPI_WIFI_INTERFACE} link

                        # echo "Reseting WiFi DHCP Client"
                        # sudo dhclient ${NEPI_WIFI_INTERFACE}
                        # wait
                        echo "Renewiung WiFi DHCP Client"
                        sudo dhclient -nw ${NEPI_WIFI_INTERFACE} 

                        echo "WiFi Client Updated"
                    else
                        echo "WiFi Client Disabled"
                    fi
                else
                    echo "FAILED TO FIND SOURCE ${source_path}"
                fi

        else
            echo "NEPI Wifi not enabled"
        fi
        
    fi

fi




# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIFI_CLIENT_UPDATE"
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

