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

        echo "Updating Network Status IP Address"
  
        if ! systemctl is-active --quiet NetworkManager; then
                    echo ""
                    echo "########"
                    echo "Updating Network Services"

                    echo "Disabling ifupdown Networking Service"
                    sudo systemctl disable networking >/dev/null 2>&1
                    sudo systemctl stop networking >/dev/null 2>&1

                    ehco "Disabling hostapd access point service"
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
    
            # Check if Interface present, and update needed
            if ip link show ${NEPI_WIRED_INTERFACE} &>/dev/null; then
                echo "${NEPI_WIRED_INTERFACE} exists."
                
        
        
                    if [[ -n $nepi_static_ip ]]; then
                        nepi_static_ip=$(fix_ipv4_netmask "$NEPI_STATIC_IP")
                        if is_valid_ipv4_netmask $nepi_static_ip; then
                        

                                echo "Updating Network Adapter ${NEPI_WIRED_INTERFACE} with IP Address ${nepi_static_ip}"

                                nepi_gateway=$NEPI_GATEWAY_IP
                                if [[ "$nepi_gateway" == 'unknown' ]]; then
                                    local nepi_gateway=$(ip route | awk '/default/ {print $3; exit}')
                                    if [[ "$router_ip" == *"192.168"* ]]; then
                                        nepi_gateway=''
                                    fi
                                fi

                                if is_valid_ip $nepi_gateway; then
                                
                                cmd='sudo nmcli connection modify "'${nepi_wired_interface}'" \
                                    ipv4.addresses '${nepi_static_ip}' \
                                    ipv4.dns 8.8.8.8,8.8.4.4 \
                                    ipv4.method manual \
                                    ipv4.gateway '${nepi_static_ip}
                                else
                                cmd='sudo nmcli connection modify "'${nepi_wired_interface}'" \
                                    ipv4.addresses '${nepi_static_ip}' \
                                    ipv4.dns 8.8.8.8,8.8.4.4 \
                                    ipv4.method manual '
                                fi

                                echo $cmd
                                eval "$cmd"     

                                cmd='sudo nmcli connection up "'${nepi_wired_interface}'"'
                                #echo $cmd
                                eval "$cmd"     
                                echo ""
                                
                        fi
                    fi
                fi
            fi




            # echo "Updating ifupdown Static IP"
            # ##################
            # echo "Updating /etc/network files"
            # if [ -d "${ETC_FOLDER}/network" ]; then
            #     if [[ ! -d "/etc/network/interfaces.d" ]]; then
            #         sudo mkdir -p "/etc/network/interfaces.d"
            #     fi
            #     sudo cp ${ETC_FOLDER}/network/* /etc/network/ 2>/dev/null
            # else
            #     echo "FAILED TO FIND SOURCE ${ETC_FOLDER}/network files"
            # fi

            # file=/etc/network/interfaces.d/nepi_static_ip
            # echo "Fixing static ip ${NEPI_STATIC_IP}"
            # needs_update=0
            # nepi_static_ip=$(fix_ipv4_netmask "$NEPI_STATIC_IP")
            # if [[ "$?" -eq 2 ]]; then
            #     needs_update=1
            # fi
            
            # echo "Got fixed static ip ${nepi_static_ip}"
            # if is_valid_ipv4_netmask "$nepi_static_ip" ]]; then
            #     if [[ "$needs_update" -eq 1 ]]; then
            #         update_file=${ETC_FOLDER}/nepi_system_config.yaml
            #         echo "Updating NEPI System Config file ${file} with NEPI_STATIC_IP: ${nepi_static_ip}"
            #         update_yaml_value "NEPI_STATIC_IP" ${nepi_static_ip} $update_file
            #     fi


            #     if [[ -d "/etc/network/interfaces.d" ]]; then
            #         echo "Updating Static IP file ${file}"
            #         sudo chmod +x -R /etc/network/interfaces.d
            #         sudo bash -c "cat /dev/null > $file"
            #         sudo echo 'auto '${NEPI_WIRED_INTERFACE} | sudo tee -a $file
            #         sudo echo 'iface '${NEPI_WIRED_INTERFACE}' inet static' | sudo tee -a $file
            #         sudo echo '    address '${nepi_static_ip} | sudo tee -a $file
            #         if is_valid_ipv4 $NEPI_GATEWAY_IP  2>/dev/null; then
            #             sudo route add default gw $NEPI_GATEWAY_IP $NEPI_WIRED_INTERFACE
            #             echo "Adding IP Gateway ${NEPI_GATEWAY_IP}"
            #             sudo echo '    gateway '${NEPI_GATEWAY_IP} | sudo tee -a $file
            #         else
            #             echo "Not Updating provided Gateway IP. Not A Valid IP Format ${NEPI_GATEWAY_IP} "
            #         fi
            #         echo "Updated Static IP file"
            #         sudo bash -c "cat $file"
            #         echo "Updating Bash files"
            #         source ${ETC_SCRIPTS_FOLDER}/update_bash_config.sh

            #         echo "NEPI Static IP address updated to ${nepi_static_ip}"
            #     else
            #         echo "Folder /etc/network/interfaces.d not found"
            #     fi
            # else
            #     echo "Not Updating provided IP. Not A Valid IP Format ${nepi_static_ip} "
            # fi


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
