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

# This script updates etc wired network files and processes

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

passed_ip=$2
if [[ -n $passed_ip ]]; then
NEPI_STATIC_IP=$passed_ip
fi

###############################
echo ""
echo "UPDATING ETC WIRED STATIC IP"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

  
        if ! systemctl is-active --quiet NetworkManager; then
                    echo "Updating Network Services"
                    echo ""
                    echo "########"
                    echo "Updating Network Services"

                    echo "Disabling ifupdown Networking Service"
                    sudo systemctl disable networking >/dev/null 2>&1
                    sudo systemctl stop networking >/dev/null 2>&1

                    echo "Disabling hostapd access point service"
                    sudo systemctl disable hostapd >/dev/null 2>&1
                    sudo systemctl stop hostapd >/dev/null 2>&1

                    echo "Configuring NetworkManager Service" 

                    sudo systemctl enable NetworkManager >/dev/null 2>&1
                    sudo systemctl restart NetworkManager >/dev/null 2>&1

                    sudo systemctl enable NetworkManager-dispatcher >/dev/null 2>&1
                    sudo systemctl restart NetworkManager-dispatcher >/dev/null 2>&1

                    sudo systemctl disable NetworkManager-wait-online >/dev/null 2>&1
                    sudo systemctl stop NetworkManager-wait-online >/dev/null 2>&1

                    if is_valid_ubuntu; then
                        echo "Enabling netplan Service" 
                        sudo systemctl enable netplan >/dev/null 2>&1
                        sudo systemctl restart netplan >/dev/null 2>&1
                    fi
                    sleep 3
        fi

        if systemctl is-active --quiet NetworkManager; then

            
            nepi_wired_interface=$NEPI_WIRED_INTERFACE
            if [[ -z $nepi_wired_interface ]]; then
                nepi_wired_interface="NONE"
            fi       
            # Check if Interface present, and update needed
            if ! ip link show ${nepi_wired_interface} &>/dev/null; then
                echo "${nepi_wired_interface} NOT FOUND."
            else
                echo "${nepi_wired_interface} exists."

                nepi_wired_name=$NEPI_WIRED_NAME
                if [[ -z $nepi_wired_name ]]; then
                    nepi_wired_name="NEPI_WIRED"
                fi                   
    
                # CLEAN NAME
                # CHECK NAME
                sudo nmcli connection add type ethernet con-name "$nepi_wired_name" ifname $nepi_wired_interface

                echo "Updating Network ${nepi_wired_name} Status IP Address"

                nepi_static_ip=$NEPI_STATIC_IP
                if [[ -z $nepi_static_ip ]]; then
                    echo "IP Address is Not Set."
                else
                    nepi_static_ip=$(fix_ipv4_netmask "$NEPI_STATIC_IP")
                    if is_valid_ipv4_netmask $nepi_static_ip; then
                            echo "Updating Network IP Address ${nepi_static_ip}"

                            nepi_wired_internet_enabled=$NEPI_WIRED_INTERNET_ENABLED
                            if [[ $nepi_wired_internet_enabled -eq 1 ]]; then
                           
                                nepi_gateway=$NEPI_GATEWAY_IP
                                if [[ "$nepi_gateway" == 'unknown' ]]; then
                                    local nepi_gateway=$(ip route | awk '/default/ {print $3; exit}')
                                    if [[ "$router_ip" == *"192.168"* ]]; then
                                        nepi_gateway=''
                                    fi
                                fi
                                echo "Using Gateway IP ${NEPI_GATEWAY_IP}"
                            else
                                nepi_gateway=''
                            fi

                            if is_valid_ipv4 $nepi_gateway 2> /dev/null; then
                                echo "Updating Network Gateway to ${nepi_gateway}"
                                cmd='sudo nmcli connection modify "'${nepi_wired_name}'" \
                                    ipv4.addresses '${nepi_static_ip}' \
                                    ipv4.dns 8.8.8.8,8.8.4.4 \
                                    ipv4.method manual \
                                    ipv4.gateway '${nepi_static_ip}

                            else
                                echo "No Gateway Provided"
                                cmd='sudo nmcli connection modify "'${nepi_wired_name}'" \
                                    ipv4.addresses '${nepi_static_ip}' \
                                    ipv4.dns 8.8.8.8,8.8.4.4 \
                                    ipv4.method manual '

                            fi

                            echo $cmd
                            eval "$cmd"     

                            cmd='sudo nmcli connection up "'${nepi_wired_name}'"'
                            #echo $cmd
                            eval "$cmd"     
                            echo ""
                            
                    fi
                fi
            fi
        fi  
    fi
fi

# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIRED_STATIC_UPDATE"
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
