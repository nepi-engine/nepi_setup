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

###############################
echo ""
echo "UPDATING ETC WIRED STATIC IP"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        echo "Updating Network Status IP Address"
  

        echo "Updating ifupdown Static IP"
        # Check if Interface present, and update needed
        if ip link show ${NEPI_WIRED_INTERFACE} &>/dev/null; then
            echo "${NEPI_WIRED_INTERFACE} exists."
            


            ##################
            echo "Updating /etc/network files"
            if [ -d "${ETC_FOLDER}/network" ]; then
                if [[ ! -d "/etc/network" ]]; then
                    sudo mkdir -p "/etc/network"
                fi
                sudo cp -a -r ${ETC_FOLDER}/network/* /etc/network/
            else
                echo "FAILED TO FIND SOURCE ${ETC_FOLDER}/network files"
            fi

            file=/etc/network/interfaces.d/nepi_static_ip
            if is_valid_ipv4 "$NEPI_IP" ]]; then
                if [[ -d "/etc/network/interfaces.d" ]]; then
                    echo "Updating Static IP file ${file}"
                    sudo chmod +x -R /etc/network/interfaces.d
                    sudo bash -c "cat /dev/null > $file"
                    sudo echo 'auto '${NEPI_WIRED_INTERFACE} | sudo tee -a $file
                    sudo echo 'iface '${NEPI_WIRED_INTERFACE}' inet static' | sudo tee -a $file
                    sudo echo '    address '${NEPI_IP}'/24' | sudo tee -a $file
                    if [[ "$NEPI_IP_GATEWAY" != "NONE" && "$NEPI_IP_GATEWAY" != "" ]]; then
                        echo "Adding IP Gateway ${NEPI_IP_GATEWAY}"
                        sudo echo '    gateway '${NEPI_IP_GATEWAY} | sudo tee -a $file
                    fi
                    echo "Updated Static IP file"
                    sudo bash -c "cat $file"

                    echo "NEPI Static IP address updated to ${NEPI_IP}"
                else
                    echo "Not A Valid IP Format ${NEPI_IP} "
                fi
            else
                echo "Not Updating provided IP. Not A Valid IP Format ${NEPI_IP} "
            fi


            ###########################
            cur_ips=($(ip -4 addr show dev ${NEPI_WIRED_INTERFACE} | grep "inet " | awk '{print $2}' | cut -d/ -f1))
            cur_ip=${cur_ips[0]}
            echo "Checking current IP ${cur_ip} against set IP ${NEPI_IP}"
            if [[ "${NEPI_IP}" != "${cur_ip}"  && -f "$file" ]]; then
                echo "Running networking ifup flush and ifdown processes"
                sudo ifdown ${NEPI_WIRED_INTERFACE} 2>/dev/null
                sudo ip addr flush ${NEPI_WIRED_INTERFACE}


                # # Tune ethernet interfaces for fast sensor throughput (especially important for genicam)
                # echo "Running pre-launch ethernet interface tuning"
                # sudo python3 /opt/nepi/nepi_engine/etc/nepi_env/tune_ethernet_interfaces.py


                sudo ifup ${NEPI_WIRED_INTERFACE}

                #sudo systemctl restart networking


            fi

            source ${ETC_SCRIPTS_FOLDER}/update_bash_config.sh
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
