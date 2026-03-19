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

SHOW_CONFIG_MENU=0
if [[ "$1" -eq 1 ]]; then
    SHOW_CONFIG_MENU=1
elif [[ "$1" -eq 0 ]]; then
    SHOW_CONFIG_MENU=0
fi

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


# Load System Config File
source ${ETC_FOLDER}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
    
fi

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

echo "########################"
echo "NEPI SYSTEM CONFIG SETUP"
echo "########################"

echo "GOT SHOW_CONFIG_MENU ${SHOW_CONFIG_MENU}"




######################################
echo ""
echo "########################"
echo "Backing Up Original System Folders If Needed"
echo "########################"

# First Backup original if needed

back_ext=org
overwrite=0

### Backup ETC folder if needed
folder=/etc
folder_back=${folder}.${back_ext}
if [[ -d "$folder" ]]; then
    #echo "Backing up ${folder} to ${folder_back}"
    path_backup $folder $folder_back $overwrite
fi

### Backup USR LIB SYSTEMD folder if needed
folder=/usr/lib/systemd/system
folder_back=${folder}.${back_ext}
if [[ -d "$folder" ]]; then
    #echo "Backing up ${folder} to ${folder_back}"
    path_backup $folder $folder_back $overwrite
fi

### Backup RUN SYSTEMD folder if needed
folder=/run/systemd/system
folder_back=${folder}.${back_ext}
if [[ -d "$folder" ]]; then
    #echo "Backing up ${folder} to ${folder_back}"
    path_backup $folder $folder_back $overwrite
fi

### Backup USR LIB SYSTEMD USER folder if needed
folder=/usr/lib/systemd/user
folder_back=${folder}.${back_ext}
if [[ -d "$folder" ]]; then
    #echo "Backing up ${folder} to ${folder_back}"
    path_backup $folder $folder_back $overwrite
fi




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



# Load System Config File
source ${SYSTEM_ETC_PATH}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_ETC_PATH}/load_system_config.sh"
    exit 1
fi

NEPI_STATIC_IP_START=$NEPI_STATIC_IP
NEPI_DEVICE_ID_START=$NEPI_DEVICE_ID

###################
#  Upated NEPI Config Settings

systemctl&> /dev/null
res=$?
if [[ "$res" -eq 0  && "$CONFIG_USER" == 'nepihost' ]]; then
    export NEPI_IN_CONTAINER=1
elif [[ "$?" -eq 0  && "$CONFIG_USER" == 'nepi' ]]; then
    export NEPI_IN_CONTAINER=0
else
    export NEPI_IN_CONTAINER=1
fi
update_yaml_value "NEPI_IN_CONTAINER" $NEPI_IN_CONTAINER $SYSTEM_SYS_CONFIG_FILE

if [[ ${CONFIG_USER} != 'nepi' ]]; then
    export NEPI_HOST_USER=$CONFIG_USER
    update_yaml_value "NEPI_HOST_USER" $NEPI_HOST_USER $SYSTEM_SYS_CONFIG_FILE
    if [[ ${NEPI_HOST_USER} == "nepihost" ]]; then
        update_yaml_value "NEPI_HOST_PW" "encrypted" $SYSTEM_SYS_CONFIG_FILE
    fi
fi

# # This is updated by NEPI Container process
# if is_valid_cuda; then
#     export NEPI_HAS_CUDA=1
#     export NEPI_CUDA_VERSION=$(get_cuda_version)
# else
#     export NEPI_HAS_CUDA=0
#     export NEPI_CUDA_VERSION=0
# fi
# update_yaml_value "NEPI_HAS_CUDA" $NEPI_HAS_CUDA $SYSTEM_SYS_CONFIG_FILE
# update_yaml_value "NEPI_CUDA_VERSION" $NEPI_CUDA_VERSION $SYSTEM_SYS_CONFIG_FILE



# ########################################
# # Update NEPI System Config


#####################################
# Config Setup

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
NEPI_EXPORT_PATH
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
    CURRENT_NEPI_FS_AB="$NEPI_FS_AB"
    CURRENT_NEPI_IMPORT_PATH="$NEPI_IMPORT_PATH"
    CURRENT_NEPI_EXPORT_PATH="$NEPI_EXPORT_PATH"
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
    echo "NEPI_FS_AB: ${CURRENT_NEPI_FS_AB}"
    echo "NEPI_IMPORT_PATH: ${CURRENT_NEPI_IMPORT_PATH}"
    echo "NEPI_EXPORT_PATH: ${CURRENT_NEPI_EXPORT_PATH}"
    echo ""
}


function udpate_config_file(){
    echo "Updating nepi system config values in file ${SYSTEM_SYS_CONFIG_FILE}"
    update_yaml_value "NEPI_USER_PW" $CURRENT_NEPI_USER_PW $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_HOST_PW" $CURRENT_NEPI_HOST_PW $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_ADMIN_PW" $CURRENT_NEPI_ADMIN_PW $SYSTEM_SYS_CONFIG_FILE
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
    update_yaml_value "NEPI_FS_AB" $CURRENT_NEPI_FS_AB $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_IMPORT_PATH" $CURRENT_NEPI_IMPORT_PATH $SYSTEM_SYS_CONFIG_FILE
    update_yaml_value "NEPI_EXPORT_PATH" $CURRENT_NEPI_EXPORT_PATH $SYSTEM_SYS_CONFIG_FILE

}

#####################################
# Update NEPI System Config if needed
#####################################

if [ -f "$SYSTEM_SYS_CONFIG_FILE" ]; then
    update_current_config
    
    if [[ "$SHOW_CONFIG_MENU" -eq 1 ]]; then


    echo ""
    PS3=$'\n'"Please enter your choice by NUMBER: "
    options=(   "VIEW ALL SETTINGS" "Update NEPI_USER_PW" "Update NEPI_HOST_PW" "Update NEPI_ADMIN_PW" \
                        "Update NEPI_DEVICE_ID" "Update NEPI_DEVICE_MD" "Update NEPI_DEVICE_SN" \
                        "Update NEPI_WIRED_INTERFACE" "Update NEPI_STATIC_IP" "Update NEPI_GATEWAY_IP" \
                        "Update NEPI_ALIAS_IP_1" "Update NEPI_ALIAS_IP_2"  "Update NEPI_ALIAS_IP_3" "Update NEPI_NTP_IP" \
                        "Update NEPI_FS_AB" "Update NEPI_IMPORT_PATH" "Update NEPI_EXPORT_PATH" \
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
                            read -p $'\n'"Enter a new Static IP Address\Netmask: " USER_INPUT
                            if [[ "$USER_INPUT" == '' ]]; then
                                echo ""
                                break # Exit the select statement, re-display menu
                            elif is_valid_ipv4_netmask "$USER_INPUT"; then
                                CURRENT_NEPI_STATIC_IP=$USER_INPUT
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
                            read -p $'\n'"Enter a new Alias IP Address\Netmask, or Empty Line for None: " USER_INPUT
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
                            read -p $'\n'"Enter a new Alias IP Address\Netmask,, or Empty Line for None: " USER_INPUT
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
                            read -p $'\n'"Enter a new Alias IP Address\Netmask,, or Empty Line for None: " USER_INPUT
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
    fi

    udpate_config_file
else
    echo "${SYSTEM_ETC_PATH} Is Not a Directory"
    # sudo mkdir -p $SYSTEM_ETC_PATH
    # sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${SYSTEM_SYS_CONFIG_FILE}
fi



if [[ "$NEPI_MANAGES_SSH" -eq 1 ]]; then
    ###############
    # Check for available key options
    SYSTEM_SSH_AKEY_SOURCE=${SYSTEM_ETC_PATH}/ssh/ssh_keys/
    SYSTEM_SSH_AKEY_DEST=${SYSTEM_ETC_PATH}/ssh/authorized_keys
    sel_ssh_path="${SYSTEM_SSH_AKEY_SOURCE}/nepi_engine_default_authorized_keys"


    file_count=$(find "$SYSTEM_SSH_AKEY_SOURCE" -maxdepth 1 -type f | wc -l)
    if [[ "$file_count" -gt 1 ]]; then
        sel_ssh_file=$(select_file_from_folder $SYSTEM_SSH_AKEY_SOURCE | tail -n 1)
        if [[ -n "$sel_ssh_file"  ]]; then
            sel_ssh_path=${SYSTEM_SSH_AKEY_SOURCE}/${sel_ssh_file}
        fi
    fi

    if [[ -f "$sel_ssh_path" ]]; then
        NEPI_SSH_AKEY=$sel_ssh_path
    fi
    echo "Using SSH Key file: ${NEPI_SSH_AKEY}"
    export NEPI_SSH_AKEY=$NEPI_SSH_AKEY
    update_yaml_value "NEPI_SSH_AKEY" $NEPI_SSH_AKEY $SYSTEM_SYS_CONFIG_FILE
fi

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


if [[ "$NEPI_MANAGES_SSH" -eq 1 ]]; then
    ########################################
    # Update SSH Public Keys
    SYSTEM_SSH_AKEY_SOURCE=${SYSTEM_ETC_PATH}/ssh/ssh_keys/${NEPI_SSH_AKEY}
    SYSTEM_SSH_AKEY_DEST=${SYSTEM_ETC_PATH}/ssh/authorized_keys


    if [[ -f "$SYSTEM_SSH_AKEY_SOURCE" ]]; then
        echo "Updating NEPI SSH PUBLIC KEY FILE from: ${SYSTEM_SSH_AKEY_SOURCE}"
        sudo cp $SYSTEM_SSH_AKEY_SOURCE $SYSTEM_SSH_AKEY_DEST
        sudo chmod 0600 $SYSTEM_SSH_AKEY_DEST
    else
        echo "Can't find specified NEPI SSH Public Key file: ${SYSTEM_SSH_AKEY_SOURCE}"
        NEPI_SSH_AKEY=nepi_engine_default_authorized_keys
        SYSTEM_SSH_AKEY_SOURCE=${SYSTEM_ETC_PATH}/ssh/ssh_keys/${NEPI_SSH_AKEY}
        if [[ ! -f "$SYSTEM_SSH_AKEY_DEST" ]]; then
            echo "Installing NEPI Default SSH Public Key file: ${SYSTEM_SSH_AKEY_SOURCE}"
            sudo cp $SYSTEM_SSH_AKEY_SOURCE $SYSTEM_SSH_AKEY_DEST
            sudo chmod 0600 $SYSTEM_SSH_AKEY_DEST
            update_yaml_value "NEPI_SSH_AKEY" $NEPI_SSH_AKEY $SYSTEM_SYS_CONFIG_FILE
        else
            echo "Using existing NEPI SSH Public Key File: ${SYSTEM_SSH_AKEY_DEST}"
        fi
    fi


    echo "Updating NEPI SSH PRIVATE KEY FILES"

    NEPI_SSH_PKEY_SOURCE=${SYSTEM_ETC_PATH}/ssh/ssh_keys/private_keys
    NEPI_SSH_PKEY_DEST=/home/${CONFIG_USER}/ssh_keys

    if [[ ! -d "$NEPI_SSH_PKEY_DEST" ]]; then
        mkdir -p $NEPI_SSH_PKEY_DEST
    fi

    if [ ! -d $NEPI_SSH_PKEY_SOURCE ]; then
        echo "Failed to Find SSH Private Keys source folder: ${NEPI_SSH_PKEY_SOURCE} "
    else
        echo "Installing NEPI SSH Private Keys from: ${NEPI_SSH_PKEY_SOURCE} "
        sudo cp -p $NEPI_SSH_PKEY_SOURCE/* $NEPI_SSH_PKEY_DEST/
        sudo chmod 600 $NEPI_SSH_PKEY_DEST/*
    fi

    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_SSH_PKEY_DEST
fi



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


echo " "
echo "################################# "
echo "Updating ETC Hosts File"
echo ""


file=/etc/hosts
bfile=${file}.org

# file=${ETC_FOLDER}/hosts
# if [[ -f "${file}.blank" ]]; then
#     echo "Updating hosts file: ${file}"

# if [ -f "$file" ]; then
#     sudo cp -a ${file}.blank $file
# fi
                
if [[ ! -f $bfile ]]; then
    path_backup $file $bfile
fi

if [[ -f $bfile ]]; then
   cp $bfile $file 
fi

if [[ -n "${NEPI_STATIC_IP%%/*}" ]]; then
    nepi_ip="${NEPI_STATIC_IP%%/*}"
else
    nepi_ip=192.168.170.103
fi
if ! is_valid_ipv4 "${nepi_ip}"; then
    nepi_ip=192.168.170.103
fi

CUT_IP=$(echo "$nepi_ip" | cut -d '.' -f 4-)
nepi_ip=127.0.0.${CUT_IP}



echo "Updating NEPI IP in ${file}"

echo "${nepi_ip} nepi" | sudo tee -a $file
echo "${nepi_ip} nepi-${NEPI_DEVICE_ID}" | sudo tee -a $file
echo "${nepi_ip} ${NEPI_HOST_USER}" | sudo tee -a $file
echo "${nepi_ip} ${NEPI_HOST_USER}-${NEPI_DEVICE_ID}" | sudo tee -a $file
echo "${nepi_ip} nepiadmin" | sudo tee -a $file
echo "${nepi_ip} nepiadmin-${NEPI_DEVICE_ID}" | sudo tee -a $file
echo "${nepi_ip} nepiuser" | sudo tee -a $file
echo "${nepi_ip} nepiuser-${NEPI_DEVICE_ID}" | sudo tee -a $file

echo ""
echo "##################################"
echo 'NEPI System Config Setup Complete'
echo "##################################"
echo ""



NEPI_STATIC_IP_END=$NEPI_STATIC_IP
NEPI_DEVICE_ID_END=$NEPI_DEVICE_ID

if [[ "$SHOW_CONFIG_MENU" -eq 1 ]]; then
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        if [[ ${NEPI_DEVICE_ID_END} != ${NEPI_DEVICE_ID_START} ]]; then
            echo ""
            echo "Your NEPI DEVICE ID has changed to: ${NEPI_DEVICE_ID}"
            echo ""
            echo ""
            echo "UPDATE IP SETTINGS ON YOUR REMOTE PC IF REQUIRED BY:"
            echo ""
            echo "Rerun the 'nepisetup' to update the NEPI_DEVICE_ID env variable to: ${NEPI_DEVICE_ID}"
            echo ""
        fi

        if [[ ${NEPI_STATIC_IP_END} != ${NEPI_STATIC_IP_START} ]]; then
            remote_ip=${SSH_CLIENT%% *}
            remote_submask=${remote_ip%.*}
            remote_addr=${remote_ip##*.}
            new_ip=${NEPI_STATIC_IP_END%%/*}
            new_submask=${new_ip%.*}
            new_addr=${new_ip##*.}
            new_netmask=${NEPI_STATIC_IP_END#*/}
            pc_ip_netmask=${new_submask}'.'${remote_addr}'/'${new_netmask}
            echo ""
            echo "Your NEPI STATIC IP address has changed to: ${NEPI_STATIC_IP_END}"
            echo ""

            echo "UPDATE IP SETTINGS ON YOUR REMOTE PC IF REQUIRED BY:"
            echo ""
            if [[ ${remote_submask} != ${new_submask} ]]; then
                echo "Updating the IP address on your remote PC's network adapter to: ${pc_ip_netmask}"
                echo ""
            fi
            echo "Rerun the 'nepisetup' to update the NEPI_IP env variable to: ${NEPI_STATIC_IP_END%%/*}"
            echo ""

            echo "Do you want to restart networking now?"
            choice=$(ask_yes_no)
            if [[ "$choice" == 'yes' ]]; then
                nnet
            else
                echo "IP address will be appled on next reboot?"
            fi    

        fi
    else
        nnet
    fi
else
    nnet
fi



