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

system_config_file=${NEPI_CONFIG}/system_cfg/nepi_system_config.yaml

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

            if [[ -d "/etc/network/interfaces.d" ]]; then
                sudo rm -r /etc/network/interfaces.d/* 2> /dev/null
            fi 

            needs_update=0


            nepi_wired_name=$NEPI_WIRED_NAME
            if [[ -z $nepi_wired_name ]]; then
                nepi_wired_name="NEPI_WIRED"
                if [[ -f "$system_config_file" ]]; then
                    export NEPI_WIRED_NAME=$nepi_wired_name
                    update_yaml_value "NEPI_WIRED_NAME" $NEPI_WIRED_NAME $system_config_file
                    needs_update=1
                fi
            fi    
            echo "Using Wired Name ${nepi_wired_name}"

            nepi_wired_interface=$NEPI_WIRED_INTERFACE
            if [[ "$NEPI_WIRED_INTERFACE" != 'NONE' ]]; then
                nepi_wired_interface="unknown"
                nepi_wired_interface=$NEPI_WIRED_INTERFACE
                if [[ -z $nepi_wired_interface ]]; then
                    nepi_wired_interface=$(netget_hw $nepi_wired_name)
                    echo "Got wired interface name and hardware  ${nepi_wired_name}: ${nepi_wired_interface}"
                    if [[ -z $nepi_wired_interface ]]; then
                        nepi_wired_interface="unknown"
                    fi   
                fi       

                dlist=$(nmcli -t -f DEVICE,TYPE device status | grep -E 'ethernet' | cut -d: -f1)
                if [[ -n $dlist && "$nepi_wired_interface" != 'NONE' ]]; then
                    echo "Auto updating wired interface hw option"
                    if [[ "$dlist" != *"$nepi_wired_interface" ]]; then
                        echo "Got wired interface hw options ${dlist}"
                        read -r nepi_wired_interface _ <<< "$dlist"
                        echo "Updated wired interface hw options ${nepi_wired_interface}"
                        if [[ -f "$system_config_file" && "$NEPI_WIRED_INTERFACE" == "unknown" ]]; then
                            export NEPI_WIRED_INTERFACE=$nepi_wired_interface
                            update_yaml_value "NEPI_WIRED_INTERFACE" $NEPI_WIRED_INTERFACE $system_config_file
                            needs_update=1
                        fi
                    else
                        nepi_wired_interface="unknown"
                    fi
                fi
            fi
            echo "Using Wired Interface ${nepi_wired_interface}"

            nepi_static_ip=$NEPI_STATIC_IP
            if ! is_valid_ipv4_netmask $nepi_static_ip >/dev/null 2>&1; then
                nepi_static_ip=$(fix_ipv4_netmask "$NEPI_STATIC_IP")
                if ! is_valid_ipv4_netmask $nepi_static_ip >/dev/null 2>&1; then
                    nepi_static_ip=192.168.179.103/24
                fi
                if [[ -f "$system_config_file" ]]; then
                    export NEPI_STATIC_IP=$nepi_static_ip
                    update_yaml_value "NEPI_STATIC_IP" $NEPI_STATIC_IP $system_config_file
                    needs_update=1
                fi
            fi
            echo "Using Static IP Address ${nepi_static_ip}"


            internet_enabled=$NEPI_WIRED_INTERNET_ENABLED
            if [[ -z $internet_enabled ]]; then
                internet_enabled=1
                if [[ -f "$system_config_file" ]]; then
                    export NEPI_WIRED_INTERNET_ENABLED=$internet_enabled
                    update_yaml_value "NEPI_WIRED_INTERNET_ENABLED" $NEPI_WIRED_INTERNET_ENABLED $system_config_file
                    needs_update=1
                fi
            fi    

            nepi_gateway_ip=$NEPI_GATEWAY_IP
            if ! is_valid_ipv4 $nepi_gateway_ip >/dev/null 2>&1; then
                if [[ $internet_enabled -eq 1 ]]; then
                    nepi_gateway_ip=$(netget_ip_router)
                fi
                if ! is_valid_ipv4 $nepi_gateway_ip >/dev/null 2>&1; then
                    new_ip="${nepi_static_ip%%/*}"
                    new_octet=1
                    nepi_gateway_ip="${new_ip%.*}.${new_octet}"
                fi
                if [[ -f "$system_config_file" ]]; then
                    export NEPI_GATEWAY_IP=$nepi_gateway_ip
                    update_yaml_value "NEPI_GATEWAY_IP" $NEPI_GATEWAY_IP $system_config_file
                    needs_update=1
                fi
            fi
            echo "Using Gateway ${nepi_gateway_ip}"
                

            if netget_info $nepi_wired_interface; then

                if ! netget_hw $nepi_wired_name; then
                    echo "Network ${nepi_wired_name} not configured"
                    echo "Will create ${nepi_wired_name} on ${nepi_wired_interface}"
                    netcreate_wired ${nepi_wired_name} ${nepi_wired_interface} ${nepi_static_ip} ${nepi_gateway_ip}

                fi  

                nepi_wired_interface=$(netget_hw $nepi_wired_name)
                if [[ -z $nepi_wired_interface ]]; then
                    echo "Network ${nepi_wired_name} not configured"
                else
                    echo "Network exists ${nepi_wired_name} on ${nepi_wired_interface}"
                    netset_wired ${nepi_static_ip} ${nepi_gateway_ip} ${nepi_wired_name}
                fi
            else
                echo "Skipping Network update ${nepi_wired_name} on ${nepi_wired_interface}"
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
