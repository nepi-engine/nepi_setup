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


if [[ -z "$1" ]]; then
    SHOW_CONFIG_MENU=0
else
    SHOW_CONFIG_MENU=$1
fi

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




echo "########################"
echo "NEPI SYSTEM CONFIG SETUP"
echo "########################"






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



###################
#  Upated NEPI Config Settings

systemctl&> /dev/null
if [[ "$?" -eq 1  && "$CONFIG_USER" == 'nepihost' ]]; then
    export NEPI_IN_CONTAINER=1
else
    export NEPI_IN_CONTAINER=0
fi
update_yaml_value "NEPI_IN_CONTAINER" $NEPI_IN_CONTAINER $NEPI_SYS_CONFIG_FILE



# # This is updated by NEPI Container process
# if is_valid_cuda; then
#     export NEPI_HAS_CUDA=1
#     export NEPI_CUDA_VERSION=$(get_cuda_version)
# else
#     export NEPI_HAS_CUDA=0
#     export NEPI_CUDA_VERSION=0
# fi
# update_yaml_value "NEPI_HAS_CUDA" $NEPI_HAS_CUDA $NEPI_SYS_CONFIG_FILE
# update_yaml_value "NEPI_CUDA_VERSION" $NEPI_CUDA_VERSION $NEPI_SYS_CONFIG_FILE



# ########################################
# # Update NEPI System Config if needed

if [[ "$SHOW_CONFIG_MENU" -eq 1 ]]; then



    #####################################
    # Config Setup

    NEPI_USER_CONFIGS=(
    NEPI_USER_PW \
    NEPI_HOST_PW \
    NEPI_ADMIN_PW \
    NEPI_IP_INTERFACE \
    NEPI_DEVICE_ID \
    NEPI_DEVICE_MD \
    NEPI_DEVICE_SN \
    NEPI_IP \
    NEPI_ALIAS_IPS \
    NEPI_NTP_IPS \
    NEPI_AB_FS \
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
        CURRENT_NEPI_IP="$NEPI_IP"
        CURRENT_NEPI_ALIAS_IPS="$NEPI_ALIAS_IPS"
        CURRENT_NEPI_NTP_IPS="$NEPI_NTP_IPS"
        CURRENT_NEPI_AB_FS="$NEPI_AB_FS"
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
        echo "NEPI_IP: ${CURRENT_NEPI_IP}"
        echo "NEPI_ALIAS_IPS: ${CURRENT_NEPI_ALIAS_IPS}"
        echo "NEPI_NTP_IPS: ${CURRENT_NEPI_NTP_IPS}"
        echo "NEPI_AB_FS: ${CURRENT_NEPI_AB_FS}"
        echo "NEPI_IMPORT_PATH: ${CURRENT_NEPI_IMPORT_PATH}"
        echo "NEPI_EXPORT_PATH: ${CURRENT_NEPI_EXPORT_PATH}"
        echo ""
        echo "Select Config to Update:"
    }

    function udpate_config_file(){
        update_yaml_value "NEPI_USER_PW" $CURRENT_NEPI_USER_PW $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_HOST_PW" $CURRENT_NEPI_ADMIN_PW $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_ADMIN_PW" $CURRENT_NEPI_ADMIN_PW $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_DEVICE_ID" $CURRENT_NEPI_DEVICE_ID $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_DEVICE_MD" $CURRENT_NEPI_DEVICE_MD $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_DEVICE_SN" $CURRENT_NEPI_DEVICE_ID $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_IP" $CURRENT_NEPI_IP $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_ALIAS_IPS" $CURRENT_NEPI_ALIAS_IPS $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_NTP_IPS" $CURRENT_NEPI_NTP_IPS $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_AB_FS" $CURRENT_NEPI_AB_FS $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_IMPORT_PATH" $CURRENT_NEPI_IMPORT_PATH $SYSTEM_SYS_CONFIG_FILE
        update_yaml_value "NEPI_EXPORT_PATH" $CURRENT_NEPI_EXPORT_PATH $SYSTEM_SYS_CONFIG_FILE

    }

    #####################################
    # Update NEPI System Config if needed
    #####################################

    if [ -f "$SYSTEM_SYS_CONFIG_FILE" ]; then
        update_current_config
        print_current_config
        
        select opt in "APPLY SETTINGS" "VIEW SETTINGS" "Update NEPI_USER_PW" "Update NEPI_HOST_PW" "Update NEPI_ADMIN_PW" \
                "Update NEPI_DEVICE_ID" "Update NEPI_DEVICE_MD" "Update NEPI_DEVICE_SN" \
                "Update NEPI_IP" "Update NEPI_ALIAS_IPS" "Update NEPI_NTP_IPS" \
                "Update NEPI_AB_FS" "Update NEPI_IMPORT_PATH" "Update NEPI_EXPORT_PATH" \
                "FACTORY RESET" "QUIT" \
                ; do
            case $opt in
                "APPLY SETTINGS")
                    udpate_config_file
                    break
                    ;;
                "VIEW SETTINGS")
                    print_yaml_file $SYSTEM_SYS_CONFIG_FILE
                    ;;
                "Update NEPI_USER_PW")
                    read -p "Enter a new password for 'nepi' user: " USER_INPUT
                    if is_valid_pw "$USER_INPUT"; then
                        CURRENT_NEPI_USER_PW=$USER_INPUT
                    else
                        echo "Not A Valid Password"
                    fi           
                    print_current_config
                ;;
                "Update NEPI_HOST_PW")
                    read -p "Enter a new password for 'nepihost' user: " USER_INPUT
                    if is_valid_pw "$USER_INPUT"; then
                        CURRENT_NEPI_HOST_PW=$USER_INPUT
                    else
                        echo "Not A Valid Password"
                    fi           
                    print_current_config
                ;;
                "Update NEPI_ADMIN_PW")
                    read -p "Enter a new password for 'nepiadmin' user: " USER_INPUT
                    if is_valid_pw "$USER_INPUT"; then
                        CURRENT_NEPI_HOST_PW=$USER_INPUT
                    else
                        echo "Not A Valid Password"
                    fi           
                    print_current_config
                ;;
                "Update NEPI_DEVICE_ID")
                    read -p "Enter a new Device ID Name: " USER_INPUT
                    if is_valid_did "$USER_INPUT"; then
                        CURRENT_NEPI_DEVICE_ID=$USER_INPUT
                    else
                        echo "Not A Valid Device ID"
                    fi           
                    print_current_config
                ;;
                "Update NEPI_DEVICE_MD")
                    read -p "Enter a new Device Model Name: " USER_INPUT
                    if is_valid_string "$USER_INPUT"; then
                        CURRENT_NEPI_DEVICE_MD=$USER_INPUT
                    else
                        echo "Not A Valid Device Model Name"
                    fi           
                    print_current_config
                ;;
               "Update NEPI_DEVICE_SN")
                    read -p "Enter a new 6 digit Serial Number: " USER_INPUT
                    if is_valid_ipv4 "$USER_INPUT"; then
                        CURRENT_NEPI_IP=$USER_INPUT
                    else
                        echo "Not A Valid IP Format"
                    fi
                    print_current_config
                    ;;
                "Update NEPI_IP")
                    read -p "Enter a new Static IP Address: " USER_INPUT
                    if is_valid_ipv4 "$USER_INPUT"; then
                        CURRENT_NEPI_IP=$USER_INPUT
                    else
                        echo "Not A Valid IP Format"
                    fi

                    ;;
                "Update NEPI_ALIAS_IPS")
                    read -p "Enter a new Alias IP Address, or Empty Line to Clear: " USER_INPUT
                    if [[ "${USER_INPUT}" == "" ]]; then
                        USER_INPUT=None
                    fi
                    if is_valid_ipv4 "$USER_INPUT" || "${USER_INPUT}" == "None"; then
                        CURRENT_NEPI_ALIAS_IPS=$USER_INPUT
                    else
                        echo "Not A Valid IP Format"
                    fi
                    print_current_config
                    ;;
                "Update NEPI_NTP_IPS")
                    read -p "Enter a new NTP Source IP Address, or Empty Line to Clear: " USER_INPUT
                    if [[ "${USER_INPUT}" == "" ]]; then
                        USER_INPUT=None
                    fi
                    if is_valid_ipv4 "$USER_INPUT" || "${USER_INPUT}" == "None"; then
                        CURRENT_NEPI_NTP_IPS=$USER_INPUT
                    else
                        echo "Not A Valid IP Format"
                    fi
                    print_current_config
                    ;;

                "Update NEPI_AB_FS")
                    read -p "Enter 1 or 0 to enable or disable NEPI AB Backup Filesystem: " USER_INPUT
                    if is_valid_bool "$USER_INPUT" || "${USER_INPUT}" == "None"; then
                        CURRENT_NEPI_AB_FS=$USER_INPUT
                    else
                        echo "Not A Valid Input"
                    fi
                    print_current_config
                    ;;

                "Update NEPI_IMPORT_PATH")
                    read -p "Enter a Valid NEPI image Import path: " USER_INPUT
                    if is_valid_folder "$USER_INPUT" || "${USER_INPUT}" == "None"; then
                        CURRENT_NEPI_IMPORT_PATH=$USER_INPUT
                    else
                        echo "Not A Valid Input"
                    fi
                    print_current_config
                    ;;
                "Update NEPI_EXPORT_PATH")
                    read -p "Enter a Valid NEPI image Export path: " USER_INPUT
                    if is_valid_folder "$USER_INPUT" || "${USER_INPUT}" == "None"; then
                        CURRENT_NEPI_EXPORT_PATH=$USER_INPUT
                    else
                        echo "Not A Valid Input"
                    fi
                    print_current_config
                    ;;
                "FACTORY RESET")
                    echo "ARE YOU SURE"
                    choice=$(ask_yes_no)
                    if [[ "$choice" == 'yes' ]]; then
                        source ${SYSTEM_ETC_PATH}/load_system_config.sh
                        update_current_config
                        udpate_config_file
                        print_current_config
                        break
                    else
                        print_current_config
                    fi
                    ;;
                "QUIT")
                    exit 0
                    ;;
                *)
                    print_current_config
                    ;;
            esac
        done
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
            NEPI_SSH_AKEY=$sel_ssh_file
        fi
        echo "Using SSH Key file: ${NEPI_SSH_AKEY}"
        export NEPI_SSH_AKEY=$NEPI_SSH_AKEY
        update_yaml_value "NEPI_SSH_AKEY" $NEPI_SSH_AKEY $NEPI_SYS_CONFIG_FILE
    fi


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
            update_yaml_value "NEPI_SSH_AKEY" $NEPI_SSH_AKEY $NEPI_SYS_CONFIG_FILE
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
source /opt/nepi/etc/scripts/sync_from_configs.sh



#################
echo ""
echo "UPDATING BASH VARIABLES"

bfile=/home/${USER}/.bashrc
if is_valid_did $NEPI_DEVICE_ID; then
    update_text_value $bfile "export NEPI_DEVICE_ID" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"
fi
if is_valid_ipv4 $NEPI_IP; then
    update_text_value $bfile "export NEPI_IP" "export NEPI_IP=${NEPI_IP}"
fi


# ###############
# echo ""
# echo "########################"
# echo "Fixing NEPI Folder Permissions"
# echo "########################"
# echo ""
# echo "Fixing Permissions in: /mnt/nepi_config"
# sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
# sudo chmod 775 /mnt/nepi_config

# echo "Fixing Permissions in: /mnt/nepi_storage"
# sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_storage
# sudo chmod -R 775 /mnt/nepi_storage



echo ""
echo "##################################"
echo 'NEPI System Config Setup Complete'
echo "##################################"
echo ""

