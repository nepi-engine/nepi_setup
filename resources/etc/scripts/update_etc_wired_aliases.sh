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

SYSTEM_SYS_CONFIG_FILE=${NEPI_CONFIG}/system_cfg/etc/nepi_system_config.yaml
######################################
echo ""
echo "UPDATING ETC WIRED ALIASES"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then

        nepi_wired_name=$NEPI_WIRED_NAME
        if [[ -z $nepi_wired_name ]]; then
            nepi_wired_name="NEPI_WIRED"
            if [[ -f "$SYSTEM_SYS_CONFIG_FILE" ]]; then
                export NEPI_WIRED_NAME=$nepi_wired_name
                update_yaml_value "NEPI_WIRED_NAME" $NEPI_WIRED_NAME $SYSTEM_SYS_CONFIG_FILE
                needs_update=1
            fi
        fi    
        echo "Checking Wired Alias IP Addresses on ${nepi_wired_name}"

        needs_update=0

        nepi_wired_interface=$(netget_hw $nepi_wired_name 2> /dev/null)
        if [[ -n $nepi_wired_interface ]]; then
            echo "Got interface for ${nepi_wired_name}: ${nepi_wired_interface}"
            pos=0
            purge_aliases=$(netget_wired_ip_aliases $nepi_wired_name)
            echo "Current Aliases: ${purge_aliases}"
            skip_udpate=1
            do_update=0
            for i in {1..10}; do
                alias_ip_var="NEPI_ALIAS_IP_"${i}
                needs_update=0
                ipn_alias=$(fix_ipv4_netmask "${!alias_ip_var}")
                if [[ "$?" -eq 2 ]]; then
                    needs_update=1
                fi
                
                
                if is_valid_ipv4_netmask $ipn_alias >/dev/null 2>&1; then
                    #echo "Checking alias_ip_alias ip var ${alias_ip_var} : ${ipn_alias}"

                    if [[ "$needs_update" -eq 1 ]]; then
                        update_file=${ETC_FOLDER}/nepi_system_config.yaml
                        update_yaml_value "${alias_ip_var}" $ipn_alias $update_file
                    fi
                    #position=$((i - 1)) 
                    #alias_name=${nepi_wired_interface}":"${position}

                    if [[ "$purge_aliases" != *"$ipn_alias"* ]]; then
                        echo "Adding Alias IP Alias ${ipn_alias}"
                        if netadd_ipn_alias $nepi_wired_interface $ipn_alias $skip_udpate; then
                            do_update=1
                        fi
                    else
                         echo "Allready IP Alias ${ipn_alias}"
                    fi
                    
                    purge_aliases="${purge_aliases/$ipn_alias/}"
                fi

            done

            for alias_ip in $purge_aliases; do
                alias_ipn=$(fix_ipv4_netmask $alias_ip)
                if is_valid_ipv4_netmask $alias_ipn; then
                    if [[ "$alias_ipn" != "$NEPI_STATIC_IP" ]]; then
                        echo "Removing Alias IP Address ${alias_ipn}"
                        if netremove_ipn_alias $nepi_wired_interface $alias_ipn $skip_udpate; then
                            do_update=1
                        fi
                    fi
                fi
            done

            if [[ $do_update -eq 1 ]]; then
                echo "Restarting Network"
                sudo nmcli connection up "$net_name"
            fi

        fi

           
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
