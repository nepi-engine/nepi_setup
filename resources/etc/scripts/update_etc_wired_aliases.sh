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

# This script updates etc wired aliases files and processes


sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    id -nu 1000
fi
export CONFIG_USER=$CONFIG_USER

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

######################################
echo ""
echo "UPDATING ETC WIRED ALIASES"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        echo "Checking Wired Alias IP Addresses"

        ###########################
        # NEPI_HOST UPDATE PROCESS

        file=/etc/network/interfaces.d/nepi_user_ip_aliases
        echo "Updating Alias IP file ${file}"
        if [ ! -f "${file}" ]; then
            if [ ! -d "/etc/network/interfaces.d" ]; then
                sudo mkdir -p /etc/network/interfaces.d
            fi
            sudo cp -a ${ETC_FOLDER}/network/interfaces.d/nepi_user_ip_aliases $file
        fi
        sudo chmod +x -R /etc/network/interfaces.d
        sudo bash -c "cat /dev/null > $file"


        pos=0
        for i in {1..10}; do
            alias_ip_var="NEPI_ALIAS_IP_"${i}
            needs_update=0
            ip_address=$(fix_ipv4_netmask "${!alias_ip_var}")
            if [[ "$?" -eq 2 ]]; then
                needs_update=1
            fi
            
            #echo "Checking alias_ip_alias ip var ${alias_ip_var} : ${ip_address}"
            if is_valid_ipv4_netmask $ip_address >/dev/null 2>&1; then

                echo "Updating Alias IP Address ${ip_address}"
                if [[ "$needs_update" -eq 1 ]]; then
                    update_file=${ETC_FOLDER}/nepi_system_config.yaml
                    update_yaml_value "${alias_ip_var}" $ip_address $update_file
                fi
                position=$((i - 1)) 
                alias_name=${NEPI_WIRED_INTERFACE}":"${position}


                sudo echo 'auto '${alias_name} | sudo tee -a $file
                sudo echo 'iface '${alias_name}' inet static' | sudo tee -a $file
                sudo echo '    address '${ip_address} | sudo tee -a $file
                sudo echo '' | sudo tee -a $file

                #echo "Pinging alias_ip_varlias ip var ${alias_ip_var} : ${ip_address}"
                if ping -c 1 "${ip_address%%/*}" >/dev/null 2>&1; then
                    : # DO NOTHING
                    #echo "Pinged alias_ip_varlias ip var ${alias_ip_var} : ${ip_address}"
                else
                    sudo ip addr add $ip_address dev ${NEPI_WIRED_INTERFACE}

                fi

            fi

        done

        echo "Updated Alias IP Aliases file"
        sudo bash -c "cat $file"

           
    fi    

fi


# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIRED_ALIASES_UPDATE"
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
