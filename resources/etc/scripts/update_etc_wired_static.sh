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

SYSTEM_SYS_CONFIG_FILE=${NEPI_CONFIG}/system_cfg/etc/nepi_system_config.yaml

###############################
echo ""
echo "UPDATING ETC WIRED STATIC IP"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then



        if systemctl is-active --quiet NetworkManager; then

            if [[ -d "/etc/network/interfaces.d" ]]; then
                sudo rm -r /etc/network/interfaces.d/* 2> /dev/null
            fi 
            sudo usermod -aG netdev ${CONFIG_USER} >/dev/null 2>&1


        
            echo "#########"
            echo "UPDATING WIRED INTERFACE SETTINGS"
            echo ""
            needs_update=0
            echo "Starting with Wired NEPI_WIRED_NAME}"
            nepi_wired_name=$NEPI_WIRED_NAME
            if [[ -z $nepi_wired_name ]]; then
                nepi_wired_name="NEPI_WIRED"
                export NEPI_WIRED_NAME=$nepi_wired_name
                needs_update=1
            fi    
            echo "Using Wired Name ${nepi_wired_name}"

            echo "Starting with Wired Interface ${NEPI_WIRED_INTERFACE}"
            nepi_wired_interface=$NEPI_WIRED_INTERFACE
            if [[ "$nepi_wired_interface" != 'NONE' ]]; then
                if ! netget_info $nepi_wired_interface; then 
                    dlist=$(nmcli -t -f DEVICE,TYPE device status | grep -E 'ethernet' | cut -d: -f1)
                    if [[ -n $dlist && "$nepi_wired_interface" != 'NONE' ]]; then
                        echo "Auto updating wired interface hw option"
                        if [[ "$dlist" != *"$nepi_wired_interface" ]]; then
                            echo "Got wired interface hw options ${dlist}"
                            read -r nepi_wired_interface _ <<< "$dlist"
                            echo "Updated wired interface hw options ${nepi_wired_interface}"
                            export NEPI_WIRED_INTERFACE=$nepi_wired_interface
                            needs_update=1
                        else
                            nepi_wired_interface="unknown"
                        fi
                    else
                        nepi_wired_interface="unknown"
                    fi
                fi
            fi
            echo "Using Wired Interface ${nepi_wired_interface}"


            nepi_rec_name="NEPI_RECOVERY"
            nepi_rec_ipn=192.168.179.103/24
            if netget_hw  ${nepi_rec_name}; then
                echo "NEPI Recovery Connection exists at ${nepi_rec_ipn}"
            else
                echo "Setting up NEPI Recovery Connection at ${nepi_rec_ipn}"
                while netget_hw  ${NEPI_WIRED_NAME}; do
                    net_hw=$(netget_hw  ${NEPI_WIRED_NAME})
                    echo "Deleting existing connection for ${NEPI_WIRED_NAME} on ${selected_hw}"
                    sudo nmcli connection delete $NEPI_WIRED_NAME
                done
                netcreate_wired ${nepi_rec_name} ${nepi_wired_interface} ${nepi_rec_ipn}
            fi

            internet_enabled=$NEPI_WIRED_INTERNET_ENABLED
            if [[ -z $internet_enabled ]]; then
                internet_enabled=1
                export NEPI_WIRED_INTERNET_ENABLED=$internet_enabled
                needs_update=1
            fi    
            echo "Using Internet Enabled ${internet_enabled}"

            nepi_static_ip=$NEPI_STATIC_IP
            if ! is_valid_ipv4_netmask $nepi_static_ip >/dev/null 2>&1; then
                nepi_static_ip=$(fix_ipv4_netmask "$NEPI_STATIC_IP")
                if ! is_valid_ipv4_netmask $nepi_static_ip >/dev/null 2>&1; then
                    nepi_static_ip=192.168.179.103/24
                fi
                export NEPI_STATIC_IP=$nepi_static_ip
                needs_update=1
            fi
            echo "Using Static IP Address ${nepi_static_ip}"


            nepi_gateway_ip=$NEPI_GATEWAY_IP
            if ! is_valid_ipv4 $nepi_gateway_ip >/dev/null 2>&1; then
                nepi_gateway_ip=NONE
                export NEPI_GATEWAY_IP=$nepi_gateway_ip
                needs_update=1

            fi
            echo "Using Gateway ${nepi_gateway_ip}"

            if [[ -f "$SYSTEM_SYS_CONFIG_FILE" && $needs_update -eq 1 ]]; then 
                update_yaml_value "NEPI_WIRED_NAME" $NEPI_WIRED_NAME $SYSTEM_SYS_CONFIG_FILE
                update_yaml_value "NEPI_WIRED_INTERFACE" $NEPI_WIRED_INTERFACE $SYSTEM_SYS_CONFIG_FILE
                update_yaml_value "NEPI_WIRED_INTERNET_ENABLED" $NEPI_WIRED_INTERNET_ENABLED $SYSTEM_SYS_CONFIG_FILE
                update_yaml_value "NEPI_STATIC_IP" $NEPI_STATIC_IP $SYSTEM_SYS_CONFIG_FILE
                update_yaml_value "NEPI_GATEWAY_IP" $NEPI_GATEWAY_IP $SYSTEM_SYS_CONFIG_FILE
            fi
                            

            if netget_info $nepi_wired_interface; then

                # if ! netget_hw $nepi_wired_name; then
                #     echo "Network ${nepi_wired_name} not configured"
                #     echo "Will create ${nepi_wired_name} on ${nepi_wired_interface}"
                #     netcreate_wired ${nepi_wired_name} ${nepi_wired_interface} ${nepi_static_ip} ${nepi_gateway_ip}

                # fi  

                # nepi_wired_interface=$(netget_hw $nepi_wired_name)
                # if [[ -z $nepi_wired_interface ]]; then
                #     echo "Network ${nepi_wired_name} not configured"
                # else
                #     echo "Network exists ${nepi_wired_name} on ${nepi_wired_interface}"
                #     netset_wired_ipn ${nepi_static_ip} ${nepi_gateway_ip} ${nepi_wired_name}
                # fi

                netcreate_wired ${nepi_wired_name} ${nepi_wired_interface} ${nepi_static_ip} ${nepi_gateway_ip} 
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
        if [[ -f "$docker_config_file" ]]; then
            update_val=0
            update_yaml_value $docker_config_setting $update_val $docker_config_file
            update_val=1
            update_yaml_value "NEPI_ETC_WIRED_ALIASES_UPDATE" $update_val $docker_config_file
        fi
    fi
fi
