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


# This file configigues an installed NEPI File System


show_menu=$1
echo "GOT SHOW_CONFIG_MENU ${show_menu}"
SHOW_CONFIG_MENU=0
if [[ -n $show_menu ]]; then
    if [[ $show_menu -eq 1 ]]; then
        SHOW_CONFIG_MENU=1
    elif [[ $show_menu -eq 0 ]]; then
        SHOW_CONFIG_MENU=0
    fi
fi

echo "RUNNING SYSTEM CONFIG with SHOW_CONFIG_MENU: ${SHOW_CONFIG_MENU}"

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



ETC_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_SCRIPTS_FOLDER=${ETC_FOLDER}/scripts
echo "ETC_FOLDER ${ETC_FOLDER}"


# Load System Config File
source ${ETC_FOLDER}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
    
fi

USER_UTILS_SOURCE=/home/${CONFIG_USER}/.nepi_bash_utils
if [[ -f $USER_UTILS_SOURCE ]]; then
    source $USER_UTILS_SOURCE
fi

echo "########################"
echo "NEPI SYSTEM CONFIG SETUP"
echo "########################"






######################################
# echo ""
# echo "########################"
# echo "Backing Up Original System Folders If Needed"
# echo "########################"

# # First Backup original if needed

# back_ext=org
# overwrite=0

# ### Backup ETC folder if needed
# folder=/etc
# folder_back=${folder}.${back_ext}
# if [[ -d "$folder" ]]; then
#     #echo "Backing up ${folder} to ${folder_back}"
#     path_backup $folder $folder_back $overwrite
# fi

# ### Backup USR LIB SYSTEMD folder if needed
# folder=/usr/lib/systemd/system
# folder_back=${folder}.${back_ext}
# if [[ -d "$folder" ]]; then
#     #echo "Backing up ${folder} to ${folder_back}"
#     path_backup $folder $folder_back $overwrite
# fi

# ### Backup RUN SYSTEMD folder if needed
# folder=/run/systemd/system
# folder_back=${folder}.${back_ext}
# if [[ -d "$folder" ]]; then
#     #echo "Backing up ${folder} to ${folder_back}"
#     path_backup $folder $folder_back $overwrite
# fi

# ### Backup USR LIB SYSTEMD USER folder if needed
# folder=/usr/lib/systemd/user
# folder_back=${folder}.${back_ext}
# if [[ -d "$folder" ]]; then
#     #echo "Backing up ${folder} to ${folder_back}"
#     path_backup $folder $folder_back $overwrite
# fi




#########################################
# Define Folders
NEPI_CONFIG_PATH=/opt/nepi
NEPI_ETC_PATH=${NEPI_CONFIG_PATH}/etc
NEPI_SYS_CONFIG_FILE=${NEPI_ETC_PATH}/nepi_system_config.yaml


FACTORY_CONFIG_PATH=/mnt/nepi_config/factory_cfg
FACTORY_ETC_PATH=${SYSTEM_CONFIG_PATH}/etc

SYSTEM_CONFIG_PATH=/mnt/nepi_config/system_cfg
SYSTEM_ETC_PATH=${SYSTEM_CONFIG_PATH}/etc

SYSTEM_SYS_CONFIG_FILE=${SYSTEM_ETC_PATH}/nepi_system_config.yaml
SYSTEM_SYS_CONFIG_UPDATE_FILE=${SYSTEM_ETC_PATH}/nepi_system_config.sh
SYSTEM_USER_CONFIG_FILE=${SYSTEM_ETC_PATH}/user/user_config.yaml



# Load System Config File
source ${SYSTEM_ETC_PATH}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_ETC_PATH}/load_system_config.sh"
    exit 1
fi

NEPI_STATIC_IP_START=$NEPI_STATIC_IP
NEPI_DEVICE_ID_START=$NEPI_DEVICE_ID



# ########################################
# # Update NEPI System Config


#####################################
# Config Setup

if [[ -z $NEPI_VPN_ENABLED ]]; then
    NEPI_VPN_ENABLED=0
fi

NEPI_USER_CONFIGS=(
NEPI_USER_PW \
NEPI_HOST_PW \
NEPI_ADMIN_PW \
NEPI_STATIC_IP_INTERFACE \
NEPI_DEVICE_ID \
NEPI_DEVICE_MD \
NEPI_DEVICE_SN \
NEPI_STATIC_IP \
NEPI_GATEWAY_IP \
NEPI_ALIAS_IP_1 \
NEPI_ALIAS_IP_2 \
NEPI_NTP_IP \
NEPI_FS_AB \
NEPI_IMPORT_PATH \
NEPI_EXPORT_PATH \
NEPI_SSH_KEY \
NEPI_VPN_ENABLED
)

function update_current_config() {
    source ${SYSTEM_ETC_PATH}/load_system_config.sh
    CURRENT_NEPI_USER_PW="$NEPI_USER_PW"
    CURRENT_NEPI_HOST_PW="$NEPI_HOST_PW"
    CURRENT_NEPI_ADMIN_PW="$NEPI_ADMIN_PW"
    CURRENT_NEPI_DEVICE_ID="$NEPI_DEVICE_ID"
    CURRENT_NEPI_DEVICE_MD="$NEPI_DEVICE_MD"
    CURRENT_NEPI_DEVICE_SN="$NEPI_DEVICE_SN"
    CURRENT_NEPI_WIRED_INTERFACE="$NEPI_WIRED_INTERFACE"
    CURRENT_NEPI_STATIC_IP=$(fix_ipv4_netmask $NEPI_STATIC_IP)
    CURRENT_NEPI_GATEWAY_IP="$NEPI_GATEWAY_IP"
    CURRENT_NEPI_ALIAS_IP_1=$(fix_ipv4_netmask $NEPI_ALIAS_IP_1)
    CURRENT_NEPI_ALIAS_IP_2=$(fix_ipv4_netmask $NEPI_ALIAS_IP_2)
    CURRENT_NEPI_ALIAS_IP_3=$(fix_ipv4_netmask $NEPI_ALIAS_IP_3)
    CURRENT_NEPI_NTP_IP="$NEPI_NTP_IP"
    CURRENT_NEPI_ROS_IP="$NEPI_ROS_IP"
    CURRENT_NEPI_FS_AB="$NEPI_FS_AB"
    CURRENT_NEPI_IMPORT_PATH="$NEPI_IMPORT_PATH"
    CURRENT_NEPI_EXPORT_PATH="$NEPI_EXPORT_PATH"
    CURRENT_NEPI_SSH_KEY="$NEPI_SSH_KEY"   
    CURRENT_NEPI_VPN_ENABLED="$NEPI_VPN_ENABLED"
}     

function print_user_config(){
    config_file=${SYSTEM_SYS_CONFIG_FILE}
    if [ -f "$config_file" ]; then
        CONFIGN="#############################
        ## NEPI Config Settings ##
        #############################
        FILE=${config_file}"

        keys=($(yq e 'keys | .[]' ${config_file}))
        for key in "${keys[@]}"; do

            IF key in NEPI_USER_CONFIGS then

                value=$(yq e '.'"$key"'' $config_file)
                echo "${key}=${value}"
                CONFIGN="${CONFIGN}
                ${key}=${!key}"
        done
        echo $CONFIG
    else
        echo "Config file not found ${config_file}"
    fi
}

function print_current_config(){
    echo ""
    echo "######################"
    echo "Current Settings"
    echo "######################"
    echo "NEPI_USER_PW: ${CURRENT_NEPI_USER_PW}"
    echo "NEPI_HOST_PW: ${CURRENT_NEPI_HOST_PW}"
    echo "NEPI_ADMIN_PW: ${CURRENT_NEPI_ADMIN_PW}"
    echo "NEPI_DEVICE_ID: ${CURRENT_NEPI_DEVICE_ID}"
    echo "NEPI_DEVICE_MD: ${CURRENT_NEPI_DEVICE_MD}"
    echo "NEPI_DEVICE_SN: ${CURRENT_NEPI_DEVICE_SN}"
    echo "NEPI_WIRED_INTERFACE: ${CURRENT_NEPI_WIRED_INTERFACE}"
    echo "NEPI_STATIC_IP: ${CURRENT_NEPI_STATIC_IP}"
    echo "NEPI_GATEWAY_IP: ${CURRENT_NEPI_GATEWAY_IP}"
    echo "NEPI_ALIAS_IP_1: ${CURRENT_NEPI_ALIAS_IP_1}"
    echo "NEPI_ALIAS_IP_2: ${CURRENT_NEPI_ALIAS_IP_2}"
    echo "NEPI_ALIAS_IP_3: ${CURRENT_NEPI_ALIAS_IP_3}"
    echo "NEPI_NTP_IP: ${CURRENT_NEPI_NTP_IP}"
    echo "NEPI_ROS_IP: ${CURRENT_NEPI_ROS_IP}"
    echo "NEPI_FS_AB: ${CURRENT_NEPI_FS_AB}"
    echo "NEPI_IMPORT_PATH: ${CURRENT_NEPI_IMPORT_PATH}"
    echo "NEPI_EXPORT_PATH: ${CURRENT_NEPI_EXPORT_PATH}"
    echo "NEPI_SSH_KEY: ${CURRENT_NEPI_SSH_KEY}"
    echo "NEPI_VPN_ENABLED: ${CURRENT_NEPI_VPN_ENABLED}"
    echo ""
}


function udpate_config_file(){
    echo "Updating nepi system config values in file ${SYSTEM_SYS_CONFIG_FILE}"
    update_yaml_value "NEPI_USER_PW" $CURRENT_NEPI_USER_PW $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_USER_PW" $CURRENT_NEPI_USER_PW $SYSTEM_USER_CONFIG_FILE
    update_yaml_value "NEPI_HOST_PW" $CURRENT_NEPI_HOST_PW $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_HOST_PW" $CURRENT_NEPI_HOST_PW $SYSTEM_USER_CONFIG_FILE
    update_yaml_value "NEPI_ADMIN_PW" $CURRENT_NEPI_ADMIN_PW $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_ADMIN_PW" $CURRENT_NEPI_ADMIN_PW $SYSTEM_USER_CONFIG_FILE
    update_yaml_value "NEPI_DEVICE_ID" $CURRENT_NEPI_DEVICE_ID $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_DEVICE_MD" $CURRENT_NEPI_DEVICE_MD $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_DEVICE_SN" $CURRENT_NEPI_DEVICE_SN $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_WIRED_INTERFACE" $CURRENT_NEPI_WIRED_INTERFACE $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_STATIC_IP" $CURRENT_NEPI_STATIC_IP $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_GATEWAY_IP" $CURRENT_NEPI_GATEWAY_IP $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_ALIAS_IP_1" $CURRENT_NEPI_ALIAS_IP_1 $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_ALIAS_IP_2" $CURRENT_NEPI_ALIAS_IP_2 $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_ALIAS_IP_3" $CURRENT_NEPI_ALIAS_IP_3 $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_NTP_IP" $CURRENT_NEPI_NTP_IP $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_ROS_IP" ${CURRENT_NEPI_STATIC_IP%%/*} $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_FS_AB" $CURRENT_NEPI_FS_AB $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_IMPORT_PATH" $CURRENT_NEPI_IMPORT_PATH $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_EXPORT_PATH" $CURRENT_NEPI_EXPORT_PATH $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_SSH_KEY" $CURRENT_NEPI_SSH_KEY $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_SSH_KEY" $CURRENT_NEPI_SSH_KEY $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_VPN_ENABLED" $CURRENT_NEPI_VPN_ENABLED $SYSTEM_SYS_CONFIG_FILE

}

#####################################
# Update NEPI System Config if needed
#####################################

if [ -f "$SYSTEM_SYS_CONFIG_FILE" ]; then
    update_current_config
    
    if [[ "$SHOW_CONFIG_MENU" -eq 1 && $LITE_INSTALL -eq 0 ]]; then
        echo "Configuring Setup Menu"

        echo ""
        PS3=$'\n'"Please enter your choice by NUMBER: "
        options=(   "VIEW ALL SETTINGS" "Update NEPI_USER_PW" "Update NEPI_HOST_PW" "Update NEPI_ADMIN_PW" \
                            "Update NEPI_DEVICE_ID" "Update NEPI_DEVICE_MD" "Update NEPI_DEVICE_SN" \
                            "Update NEPI_WIRED_INTERFACE" "Update NEPI_STATIC_IP" "Update NEPI_GATEWAY_IP" \
                            "Update NEPI_ALIAS_IP_1" "Update NEPI_ALIAS_IP_2"  "Update NEPI_ALIAS_IP_3" "Update NEPI_NTP_IP" \
                            "Update NEPI_FS_AB" "Update NEPI_IMPORT_PATH" "Update NEPI_EXPORT_PATH" "Update NEPI_SSH_KEY"\
                            "FACTORY RESET" "APPLY SETTINGS" )

        while true; do
            #clear # Optional: Clear the screen before displaying the menu

            print_current_config
            COLUMNS=1
            select opt in "${options[@]}" ; do
                case $opt in


                            "VIEW ALL SETTINGS")
                                print_yaml_file $SYSTEM_SYS_CONFIG_FILE
                                break # Exit the select statement, re-display menu
                                ;;
                            "Update NEPI_USER_PW")
                                read -p $'\n'"Enter a new password for 'nepi' user: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_pw "$USER_INPUT"; then
                                    CURRENT_NEPI_USER_PW=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                
                                else
                                    echo "Not A Valid Password"
                                fi           

                            ;;
                            "Update NEPI_HOST_PW")
                                read -p $'\n'"Enter a new password for 'nepihost' user: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_pw "$USER_INPUT"; then
                                    CURRENT_NEPI_HOST_PW=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Password"
                                fi           
                            ;;
                            "Update NEPI_ADMIN_PW")
                                read -p $'\n'"Enter a new password for 'nepiadmin' user: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_pw "$USER_INPUT"; then
                                    CURRENT_NEPI_HOST_PW=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Password"
                                fi           
                            ;;
                            "Update NEPI_DEVICE_ID")
                                read -p $'\n'"Enter a new Device ID Name: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_did "$USER_INPUT"; then
                                    CURRENT_NEPI_DEVICE_ID=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Device ID"
                                fi           
                                print_current_config
                                echo "Select Config to Update:"
                            ;;
                            "Update NEPI_DEVICE_MD")
                                read -p $'\n'"Enter a new Device Model Name: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_string "$USER_INPUT"; then
                                    CURRENT_NEPI_DEVICE_MD=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Device Model Name"
                                fi           

                            ;;
                        "Update NEPI_DEVICE_SN")
                                read -p $'\n'"Enter a new 6 digit Serial Number: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_sn "$USER_INPUT"; then
                                    CURRENT_NEPI_DEVICE_SN=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Serial Number Format"
                                fi
                                ;;
                            "Update NEPI_WIRED_INTERFACE")
                                read -p $'\n'"Enter a new Wired Interface name: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif [[ -n "$USER_INPUT" && "$USER_INPUT" != *" "* ]]; then
                                    CURRENT_NEPI_WIRED_INTERFACE=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Wired Interface name"
                                fi
                                ;;
                            "Update NEPI_STATIC_IP")
                                read -p $'\n'"Enter a new Static IP Address/Netmask: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_ipv4_netmask "$USER_INPUT"; then
                                    CURRENT_NEPI_STATIC_IP=$USER_INPUT
                                    CURRENT_NEPI_ROS_IP=${CURRENT_NEPI_STATIC_IP%%/*}
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid IP/Netmask Format"
                                fi
                                ;;
                            "Update NEPI_GATEWAY_IP")
                                read -p $'\n'"Enter a new Gateway IP Address, or Empty Line for None: " USER_INPUT
                                if [[ "${USER_INPUT}" == "" ]]; then
                                    USER_INPUT=None
                                fi
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_ipv4 "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_GATEWAY_IP=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid IP Format"
                                fi
                                ;;
                            "Update NEPI_ALIAS_IP_1")
                                read -p $'\n'"Enter a new Alias IP Address/Netmask, or Empty Line for None: " USER_INPUT
                                if [[ "${USER_INPUT}" == "" ]]; then
                                    USER_INPUT=None
                                fi
                                if is_valid_ipv4_netmask "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_ALIAS_IP_1=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid IP/Netmask Format"
                                fi
                                ;;
                            "Update NEPI_ALIAS_IP_2")
                                read -p $'\n'"Enter a new Alias IP Address/Netmask,, or Empty Line for None: " USER_INPUT
                                if [[ "${USER_INPUT}" == "" ]]; then
                                    USER_INPUT=None
                                fi
                                if is_valid_ipv4_netmask "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_ALIAS_IP_2=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid IP/Netmask Format"
                                fi
                                ;;
                            "Update NEPI_ALIAS_IP_3")
                                read -p $'\n'"Enter a new Alias IP Address/Netmask,, or Empty Line for None: " USER_INPUT
                                if [[ "${USER_INPUT}" == "" ]]; then
                                    USER_INPUT=None
                                fi
                                if is_valid_ipv4_netmask "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_ALIAS_IP_3=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid IP/Netmask Format"
                                fi
                                ;;
                            "Update NEPI_NTP_IP")
                                read -p $'\n'"Enter a new NTP Source IP Address, or Empty Line to Clear: " USER_INPUT
                                if [[ "${USER_INPUT}" == "" ]]; then
                                    USER_INPUT=None
                                fi
                                if is_valid_ipv4 "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_NTP_IP=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid IP Format"
                                fi
                                ;;

                            "Update NEPI_FS_AB")
                                read -p $'\n'"Enter 1 or 0 to enable or disable NEPI AB Backup Filesystem: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_bool "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_FS_AB=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Input"
                                fi
                                ;;

                            "Update NEPI_IMPORT_PATH")
                                read -p $'\n'"Enter a Valid NEPI image Import path: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_folder "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_IMPORT_PATH=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Input"
                                fi
                                ;;
                            "Update NEPI_EXPORT_PATH")
                                read -p $'\n'"Enter a Valid NEPI image Export path: " USER_INPUT
                                if [[ "$USER_INPUT" == '' ]]; then
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                elif is_valid_folder "$USER_INPUT" || [[ "${USER_INPUT}" == "None" ]]; then
                                    CURRENT_NEPI_EXPORT_PATH=$USER_INPUT
                                    echo ""
                                    break # Exit the select statement, re-display menu
                                else
                                    echo "Not A Valid Input"
                                fi

                                ;;
                            "Update NEPI_SSH_KEY")
                                ret=$(nepisshkey)
                                sel_error=$?
                                sel_file=$(echo $ret | awk '{print $NF}')
                                #echo "Got select SSH Key file error: ${sel_error}"
                                
                                if [[ $? -eq 0 && -n sel_file ]]; then
                                    echo ''
                                    echo "Got Selected SSH Key file: ${sel_file}"
                                    CURRENT_NEPI_SSH_KEY=$sel_file
                                fi     
                                break # Exit the select statement

                                ;;

                            # "Update NEPI_VPN_ENABLED")
                            #         vpn_version=$(get_openvpn_version)
                            #         if [[ -z $vpn_version ]]; then
                            #             vpn_version=0
                            #         fi    
                            #         if [[ "$vpn_version" == '0' ]]; then
                            #             echo "No VPN software installed"
                            #             break # Exit the select statement
                            #         fi                        
                            #         echo "Do you want to enable NEPI VPN service on your device"
                            #         choice=$(ask_yes_no)
                            #         if [[ "$choice" == 'yes' ]]; then
                            #             CURRENT_NEPI_VPN_ENABLED=1
                            #         else
                            #             CURRENT_NEPI_VPN_ENABLED=0
                            #         fi
                            #         break # Exit the select statement
                            #     ;;
                            "FACTORY RESET")
                                echo "ARE YOU SURE"
                                choice=$(ask_yes_no)
                                if [[ "$choice" == 'yes' ]]; then
                                    source_path ${FACTORY_ETC_PATH}
                                    dest_path ${SYSTEM_ETC_PATH}
                                    if [[ ! -d ${dest_path} && -d ${source_path} ]]; then
                                        sudo rm -r ${dest_path}/*
                                        sudo cp -r ${source_path}/* ${dest_path}/
                                    fi
                                    update_current_config
                                    break
                                else
                                    break
                                fi
                                ;;
                            "APPLY SETTINGS")
                                break 2 # Exit both the select and the while loop
                                ;;
                            *)
                                echo "Invalid option, please try again."
                                ;;
                        esac
                    done
            done
            echo ""
    elif [[ ${NEPI_MODE} == 'HOST' && $LITE_INSTALL -eq 1 && ${CURRENT_NEPI_SSH_KEY} == 'nepi_default_ssh_key' ]]; then
        echo "Creating a Custom NEPI SSH KEY"
        sudo rm /home/${CONFIG_USER}/.ssh/nepi_*
        ret=$(create_ssh_key)
        error=$?
        echo "Got select SSH Key file error: ${error}"
        key_file=$(echo $ret | awk '{print $NF}')
        echo "Got select SSH Key file: ${key_file}"
        
        if [[ $error -eq 0 && -n key_file ]]; then
            echo ''
            echo "Created Custom NEPI SSH KEY: ${key_file}"
            CURRENT_NEPI_SSH_KEY=$(basename $key_file)
        else
            echo "Failed to create Custom NEPI SSH KEY"
        fi     

    fi

    udpate_config_file

      
    systemctl &> /dev/null
    if [[ "$?" -eq 0 ]]; then
    vpn_version=$(get_openvpn_version)
        if [[ -z $vpn_version ]]; then
            vpn_version=0
        fi
        export NEPI_VPN_VERSION=$vpn_version
        update_yaml_value "NEPI_VPN_VERSION" $vpn_version $SYSTEM_SYS_CONFIG_FILE
    fi

    print_yaml_file $SYSTEM_SYS_CONFIG_FILE


    echo ""
    echo "########################"
    echo "Updating OS Configuration"
    echo "########################"
    echo ""


    ####################
    echo "Refreshing NEPI CONFIG from ${SYSTEM_ETC_PATH}/load_system_config.sh "
    source ${SYSTEM_ETC_PATH}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${SYSTEM_ETC_PATH}/load_system_config.sh"
        exit 1
    fi


    # systemctl &> /dev/null
    # if [[ "$?" -eq 0 ]]; then
    #     #################################################
    #     echo "Updating NEPI VPN Settings to ${NEPI_VPN_ENABLED} with version ${NEPI_VPN_VERSION}"

    #     if [[ ${NEPI_VPN_VERSION} != '0' ]]; then
    #         if [[ $NEPI_VPN_ENABLED -eq 1  ]]; then
    #             sudo systemctl start openvpn
    #         else
    #             sudo systemctl stop openvpn
    #         fi
    #     fi
    # fi




    #################################################
    echo "Updating NEPI ETC files in ${SYSTEM_ETC_PATH}"
    source ${SYSTEM_ETC_PATH}/update_etc_files.sh
    # if [ $? -eq 1 ]; then
    #     echo "Failed to update ETC folder ${ETC_NEPI_PATH}"
    #     exit 1
    # fi


    ####################
    echo "Syncing NEPI CONFIG from ${SYSTEM_ETC_PATH}"
    source ${SYSTEM_ETC_PATH}/scripts/nepi_system_sync.sh




    ETC_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
    ETC_SCRIPTS_FOLDER=${ETC_FOLDER}/scripts


    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        
    fi




    echo ""
    echo "##################################"
    echo 'NEPI System Config Setup Complete'
    echo "##################################"
    echo ""

    NEPI_STATIC_IP_END=$NEPI_STATIC_IP
    NEPI_DEVICE_ID_END=$NEPI_DEVICE_ID


    new_ip=${NEPI_STATIC_IP_END%%/*}
    new_submask=${new_ip%.*}
    new_addr=${new_ip##*.}
    host_ip="127.0.0.${new_addr}"
    rm_ip=${new_submask}.5

    echo "Your NEPI DEVICE IP address is set to:" 
    echo "${NEPI_STATIC_IP_END}"

    echo " "
    echo "You can connect to your NEPI Device's RUI in a Chrome browser on this device:"
    echo "nepirui   OR   entering  http://${host_ip}:5003/  in a Chromium browser"

    echo " "
    echo "You can connect to your NEPI Device's shared network drives by typing:"
    echo "nepistorage  OR   nepiconfig   to change to sharedrive drive"
    echo "nepistorageopen  OR   nepiconfigopen   to open file manager to sharedrive drive"

    echo " "
    echo "Your NEPI ssh key is set to ${NEPI_SSH_KEY}"
    if [[ ${NEPI_MODE} == 'HOST' ]]; then
        echo "You can ssh into your Running NEPI Docker contatiner by typing:"
        echo "sshn"
    fi

    echo ""
    echo "Your remote dev system network adapter should be set to "
    echo "${rm_ip}"

    echo " "
    echo "You can connect to your NEPI Device's RUI in a Chrome browser on a remote device:"
    echo "nepirui   OR   entering  http://${new_ip}:5003/  in a Chromium browser"

    echo " "
    echo "To see a list of available NEPI bash command line shortcuts run: nepihelp"
    echo " "


    if [[ "$SHOW_CONFIG_MENU" -eq 1 ]]; then

            if [[ ${NEPI_DEVICE_ID_END} != ${NEPI_DEVICE_ID_START} ]]; then
                echo ""
                echo "Your NEPI DEVICE ID has changed to: ${NEPI_DEVICE_ID}"
                echo ""
                echo "Rerun the 'nepiremotesetup' on any Remote Dev System to update the NEPI_DEVICE_ID env variable to: ${NEPI_DEVICE_ID}"
                echo ""
            fi

            if [[ ${NEPI_STATIC_IP_END} != ${NEPI_STATIC_IP_START} ]]; then
                remote_ip=${SSH_CLIENT%% *}
                remote_submask=${remote_ip%.*}
                remote_addr=${remote_ip##*.}

                echo ""
                echo "Your NEPI STATIC IP address has changed from: ${NEPI_STATIC_IP_START%%/*} to: ${NEPI_STATIC_IP_END%%/*}"
                echo ""
                echo "Rerun the 'nepiremotesetup' on any Remote Dev System to update the NEPI_IP env variable to: ${new_ip}"
                echo ""
                if systemctl is-active --quiet NetworkManager; then
                    echo "You can switch network adapter settings on this device between "
                    echo "  NEPI Static IP ${new_ip}, Automatic IP, or a Custom IP/Netmask by typing:"
                    echo "netnepi  OR   nepiauto   OR  netsetstatic <ip_address/netmask>"  
                    echo ''
                else

                    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
                        echo "Do you want to restart networking now?"
                        choice=$(ask_yes_no)
                        if [[ "$choice" == 'yes' ]]; then
                            sudo systemctl restart networking
                        else
                            echo "IP address will be appled on next reboot?"
                        fi    

                    else
                        sudo systemctl restart networking
                    fi
                fi
                # else
                #     sudo systemctl restart networking
            fi
    fi
else
    echo "${SYSTEM_ETC_PATH} Does not exist"
    echo ""
    echo "rebuild NEPI System Config using the command: nepibld"
    echo "then rerun the setup process using the command: nepisetup"
    # sudo mkdir -p $SYSTEM_ETC_PATH
    # sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${SYSTEM_SYS_CONFIG_FILE}
fi






