#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc wired aliases files and processes


export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ "$CONFIG_USER" == 'nepihost'  ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepihost/.bashrc
    ufile=/home/nepihost/.nepi_bash_utils
    afile=/home/nepihost/.nepi_docker_aliases
# elif [[ -f "/home/${CONFIG_USER}/.nepi_docker_aliases" ]]; then
#     bfile=/home/${CONFIG_USER}/.bashrc
#     ufile=/home/${CONFIG_USER}/.nepi_bash_utils
#     afile=/home/${CONFIG_USER}/.nepi_docker_aliases
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

######################################
echo ""
echo "UPDATING ETC WIRED ALIASES"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        NETMASK_CIDR="24" # e.g., 24 for 255.255.255.0

        echo "Updating Wired Alias IP Addresses"

        ###########################
        # NEPI_HOST UPDATE PROCESS

        # Update Network ETC Files
        if [[ "$NEPI_ALIAS_IPS" != "NONE" ]]; then
            echo "Adding Network alias ips in interfaces.d"
            sudo ip addr add ${NEPI_ALIAS_IPS}'/24' dev ${NEPI_WIRED_INTERFACE}
        fi 

        file=/etc/network/interfaces.d/nepi_user_ip_aliases
        echo "Updating Alias IP file ${file}"
        if [ ! -f "${file}" ]; then
            if [ -d "/etc/network/interfaces.d" ]; then
                sudo mkdir -p /etc/network/interfaces.d
            fi
            sudo cp -a ${ETC_FOLDER}/network/interfaces.d/nepi_user_ip_aliases $file
        fi
            
        sudo chmod +x -R /etc/network/interfaces.d
        sudo bash -c "cat /dev/null > $file"
        if [[ "$NEPI_ALIAS_IPS" != "NONE" ]]; then
            echo "Updating Alias IP Addresses"
            position=1
            alias_name=${NEPI_ALIAS_IPS}":"${position}


            sudo echo 'auto '${alias_name} | sudo tee -a $file
            sudo echo 'iface '${alias_name}' inet static' | sudo tee -a $file
            sudo echo '    address '${NEPI_ALIAS_IPS}'/24' | sudo tee -a $file
            sudo echo '' | sudo tee -a $file
        fi

        echo "Updated Alias IP file"
        sudo bash -c "cat $file"

        sudo systemctl restart networking
            
    fi    

fi


# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_WIRED_ALIASES_UPDATE"
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
