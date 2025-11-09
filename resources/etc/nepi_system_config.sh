#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file configigues an installed NEPI File System

echo "########################"
echo "NEPI SYSTEM CONFIG SETUP"
echo "########################"

CONFIG_USER=$USER

if [[ "$CONFIG_USER" -ne 'nepi' || "$CONFIG_USER" -ne 'nepihost' ]]; then
    echo "NEPI SYSTEM CONFIG SCRIPT must be run by either 'nepi' or 'nepihost' user"
    exit 1
fi

source /home/${CONFIG_USER}/.nepi_bash_utils
wait


SHOW_CONFIG_MENU=0
if [[ "$1" -eq 1 ]]; then
    SHOW_CONFIG_MENU=1
fi




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

CONFIG_FOLDER=/mnt/nepi_config/system_cfg/etc
CONFIG_FILE=${CONFIG_FOLDER}/nepi_system_config.yaml

# Load System Config File
source ${CONFIG_FOLDER}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${CONFIG_FOLDER}/load_system_config.sh"
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


if is_valid_cuda; then
    export NEPI_HAS_CUDA=1
    export NEPI_CUDA_VERSION=$(cuda_version)
else
    export NEPI_HAS_CUDA=0
    export NEPI_CUDA_VERSION=0
fi
update_yaml_value "NEPI_HAS_CUDA" $NEPI_HAS_CUDA $NEPI_SYS_CONFIG_FILE
update_yaml_value "NEPI_CUDA_VERSION" $NEPI_CUDA_VERSION $NEPI_SYS_CONFIG_FILE



# ########################################
# # Update NEPI System Config if needed


# min_docker_gb=$((NEPI_GB_CONTAINER * 3))

# check_drive=/mnt/nepi_config/docker_cfg
# check_space=$min_docker_gb
# if is_space_avail_gb $check_drive $check_space; then
#     if [[ "$NEPI_AB_FS" -nq 1 ]]; then
#         echo "Would you like to enable NEPI AB Backup/Recovery file system support"
#         enable_ab=$(ask_yes_no)
#         if [[ "$enable_ab" == 'yes' ]]; then
#             export NEPI_AB_FS=1
#         else
#             export NEPI_AB_FS=0
#         fi
#     fi
# fi

# if [[ -z $NEPI_AB_FS ]]; then
#     NEPI_AB_FS=0
# fi
# update_yaml_value "NEPI_AB_FS" $NEPI_AB_FS $NEPI_DOCKER_CONFIG_FILE




# update_settings=0

# echo ""
# PS3='Please enter your choice: '
# options=( "USE CURRENT SETTINGS" "View Settings" "Update Settings" "QUIT" )

# while true; do
#     #clear # Optional: Clear the screen before displaying the menu
#     select opt in "${options[@]}" ; do
#         case $opt in
#             "USE CURRENT SETTINGS")
#                 break 2 # Exit both the select and the while loop
#                 ;;
#             "View Settings" )
#                 print_config_file $SYSTEM_SYS_CONFIG_FILE
#                 echo ""
#                 break # Exit the select statement, re-display menu
#             ;;
#             "Update Settings")
#                 update_settings=1
#                 echo ""
#                 break 2 # Exit both the select and the while loop
#                 ;;
#             "QUIT")
#                 exit 0
#                 ;;
#             *)
#                 echo "Invalid option, please try again."
#                 ;;
#         esac
#     done
# done
# echo ""




# #########################################


# #####################################
# # Config Setup

# USE_ENABLE_AB_FS=0

# ## Check Selection
# echo ""
# echo "Will NEPI's AB Backup/Recovery Image System be enabled?"
# echo "NOTE: If enabled, NEPI Docker installation will require 3x hard-drive space"
# select ovw in "Yes" "No" "Quit"; do
#     case $ovw in
#         Yes ) USE_ENABLE_AB_FS=1; break;;
#         No ) USE_ENABLE_AB_FS=0; break;;
#         Quit ) exit 1
#     esac
# done
# USE_ENABLE_AB_FS=$nepi_in_container

# USE_EXTERNAL_IE_PATH=0

# echo ""
# echo "Will an external device be used for importing and exporting NEPI Docker Images ?"
# echo "NOTE: If enabled, NEPI Docker installation will require additional hard-drive space"
# select ovw in "Yes" "No" "Quit"; do
#     case $ovw in
#         Yes ) USE_EXTERNAL_IE_PATH=1; break;;
#         No ) USE_EXTERNAL_IE_PATH=0; break;;
#         Quit ) exit 1
#     esac
# done
# USE_EXTERNAL_IE_PATH=$nepi_in_container

# echo ""
# echo "#############################"
# echo "Updating Hardware and Software Settings" 
# echo ""

# arch_val=$(uname -m)
# if [[ "$arch_val" == "x86_64" ]]; then
#   NEPI_ARCH="amd64"
# elif [[ "$arch_val" == "aarch64" ]]; then
#   NEPI_ARCH="arm64"
# else
#   # Handle other potential architectures or set a default
#   NEPI_ARCH="unknown" 
#   echo "Warning: Unknown architecture detected: $arch_val"
# fi


# echo ""
# echo "#############################"
# echo "Updating NEPI Folder Settings"
# echo ""

# check=0
# nimg_size=20

# docker_min_gb=$nimg_size
# config_min_mb=200
# storage_min_gb=1

# if [[ "$USE_ENABLE_AB_FS" -eq 1 ]]; then
#     docker_min_gb=$((docker_min_gb + $nimg_size))
#     docker_min_gb=$((docker_min_gb + $nimg_size))
# else
#     docker_min_gb=$((docker_min_gb + $nimg_size))
# fi

# if [[ "$USE_EXTERNAL_IE_PATH" -eq 1 ]]; then
#     storage_min_gb=$nimg_size
# fi



# while [[ $check -eq 0 ]]
# do
#     check=1 
#     if [[ "$NEPI_MANAGES_DOCKER" -eq 1 ]]; then

#         if [[ ! -d ${NEPI_DOCKER} && $NEPI_IN_CONTAINER -eq 1 ]]; then
#             echo "Missing required folder: ${NEPI_DOCKER} with min size ${docker_min_gb} GB"
#             check=0
#         fi
#     fi

#     if [[ ! -d ${NEPI_CONFIG} ]]; then
#         echo "Missing required folder: ${NEPI_CONFIG} with min size ${config_min_mb} MB"
#         check=0
#     fi

#     if [[ ! -d ${NEPI_STORAGE} ]]; then
#         echo "Missing required folder: ${NEPI_STORAGE} with min size ${storage_min_gb} GB"
#         check=0
#     fi


#     # Define the minimum free space threshold in GB
#     MIN_FREE_SPACE_GB=$(($docker_min_gb + $config_min_gb + $storage_min_gb))

#     # Specify the mount point to check (e.g., '/', '/home', '/mnt/data')
#     MOUNT_POINT="/"

#     # Get the available space in 1-byte blocks and convert to GB
#     AVAILABLE_SPACE_BYTES=$(df -B1 --output=avail "$MOUNT_POINT" | tail -n 1)
#     AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE_BYTES / (1024 * 1024 * 1024)))

#     free_space=0
#     if [[ "$check" -eq 0 ]]; then
#         # Perform the comparison in the if statement
#         if (( AVAILABLE_SPACE_GB > MIN_FREE_SPACE_GB )); then
#             check=1
#         else
#             free_space=$(($MIN_FREE_SPACE_GB - $AVAILABLE_SPACE_GB))
#         fi
#     fi

#     if [[ "$check" -eq 0 ]]; then
#         echo "*****  NEPI DOCKER STORAGE SETUP FAILED ******"
#         echo ""
#         echo "There is not enough hard drive space available on your current file system partition"
#         echo "Options to proceed:"
#         echo
#         echo "    1) Rerun the script with different selected options"
#         echo
#         echo "    2) Free up ${free_space} GB on your current file system"
#         echo
#         echo "    3) Manually create the missing folders as individually mounted partitions with the minimum required space shown"
#         echo ""
#         echo "MAKE THE REQUIRED CHANGES AND RERUN THIS SCRIPT"
#         echo ""
#         echo "DO NOT PROCEED UNTIL THIS SCRIPT COMPLETES SUCCESSFULLY"
#         exit 1
#     fi
# done



# echo ""
# echo "#############################"
# echo "Updating Device IP Configuration" 
# echo ""


# NEPI_DOCKER_CONFIGS=(
# NEPI_DEVICE_ID \
# NEPI_IP
# )

# function print_current_config(){
#     echo ""
#     echo "Current Settings"
#     echo "---------------------"
#     echo "NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
#     echo "NEPI_IP: ${NEPI_IP}"
#     echo ""

# }

# function udpate_config_file(){
#     config_file=$1
#     update_yaml_value "NEPI_IN_CONTAINER" $NEPI_IN_CONTAINER $config_file
#     update_yaml_value "NEPI_DEVICE_ID" $NEPI_DEVICE_ID $config_file
#     update_yaml_value "NEPI_IP" $NEPI_IP $config_file

# }

# #####################################
# # Update NEPI System Config if needed

# echo ""
# PS3='Please enter your choice: '
# options=( "USE CURRENT SETTINGS" "Update NEPI Device ID Name" "Update NEPI Static IP Address" "QUIT" )

# while true; do
#     #clear # Optional: Clear the screen before displaying the menu

#     print_current_config
#     select opt in "${options[@]}" ; do
#         case $opt in
#             "USE CURRENT SETTINGS")
#                 break 2 # Exit both the select and the while loop
#                 ;;
#             "Update NEPI Device ID Name")
#                 read -p "Enter a new Device Name (Default=device1): " USER_INPUT
#                 echo ""
#                 if is_valid_did "$USER_INPUT"; then
#                     export NEPI_DEVICE_ID=$USER_INPUT
#                 fi       
#                 echo ""
#                 break # Exit the select statement, re-display menu
#             ;;
#             "Update NEPI Static IP Address")
#                 read -p "Enter a new Static IP Address (Default=192.168.179.103): " USER_INPUT
#                 echo ""
#                 if is_valid_ipv4 "$USER_INPUT"; then
#                     export NEPI_IP=$USER_INPUT
#                 fi
#                 echo ""
#                 break # Exit the select statement, re-display menu
#                 ;;
#             "QUIT")
#                 exit 0
#                 ;;
#             *)
#                 echo "Invalid option, please try again."
#                 ;;
#         esac
#     done
# done
# echo ""


# echo "Running script with settings:"
# echo "----------------------------"
# print_current_config
# echo ""

# echo "Updating NEPI CONFIG from ${DOCKER_SYS_CONFIG_FILE} "
# udpate_config_file $DOCKER_SYS_CONFIG_FILE



# #####################################
# # Config Setup

# NEPI_USER_CONFIGS=(
# NEPI_IP_INTERFACE \
# NEPI_DEVICE_ID \
# NEPI_DEVICE_MD \
# NEPI_DEVICE_SN \
# NEPI_IP \
# NEPI_ALIAS_IPS \
# NEPI_NTP_IPS \
# NEPI_DHCP_ON_START \
# NEPI_AB_FS \
# NEPI_RECOVERY_ENABLED \
# NEPI_BOOT_TIME \
# NEPI_IMPORT_PATH \
# NEPI_EXPORT_PATH
# )


# CURRENT_NEPI_DEVICE_ID="$NEPI_DEVICE_ID"
# CURRENT_NEPI_DEVICE_MD="$NEPI_DEVICE_MD"
# CURRENT_NEPI_DEVICE_SN="$NEPI_DEVICE_SN"
# CURRENT_NEPI_IP="$NEPI_IP"
# CURRENT_NEPI_ALIAS_IPS="$NEPI_ALIAS_IPS"
# CURRENT_NEPI_NTP_IPS="$NEPI_NTP_IPS"
# CURRENT_NEPI_AB_FS="$NEPI_AB_FS"
# CURRENT_NEPI_IMPORT_PATH="$NEPI_IMPORT_PATH"
# CURRENT_NEPI_EXPORT_PATH="$NEPI_EXPORT_PATH"

# function print_user_config(){
#     config_file=${CONFIG_FILE}
#     if [ -f "$config_file" ]; then
#         CONFIGN="#############################
#         ## NEPI Config Settings ##
#         #############################
#         FILE=${config_file}"

#         keys=($(yq e 'keys | .[]' ${config_file}))
#         for key in "${keys[@]}"; do

#             IF key in NEPI_USER_CONFIGS then

#                 value=$(yq e '.'"$key"'' $config_file)
#                 echo "${key}=${value}"
#                 CONFIGN="${CONFIGN}
#                 ${key}=${!key}"
#         done
#         echo $CONFIG
#     else
#         echo "Config file not found ${config_file}"
#     fi
# }

# function print_current_config(){
#     echo ""
#     echo "######################"
#     echo "Current Settings"
#     echo "######################"
#     echo "NEPI_DEVICE_ID: ${CURRENT_NEPI_DEVICE_ID}"
#     echo "NEPI_DEVICE_MD: ${CURRENT_NEPI_DEVICE_MD}"
#     echo "NEPI_DEVICE_SN: ${CURRENT_NEPI_DEVICE_SN}"
#     echo "NEPI_IP: ${CURRENT_NEPI_IP}"
#     echo "NEPI_ALIAS_IPS: ${CURRENT_NEPI_ALIAS_IPS}"
#     echo "NEPI_NTP_IPS: ${CURRENT_NEPI_NTP_IPS}"
#     echo "NEPI_AB_FS: ${CURRENT_NEPI_AB_FS}"
#     echo "NEPI_IMPORT_PATH: ${CURRENT_NEPI_IMPORT_PATH}"
#     echo "NEPI_EXPORT_PATH: ${CURRENT_NEPI_EXPORT_PATH}"
#     echo ""
#     echo "Select Config to Update:"
# }

# function udpate_config_file(){

#     update_yaml_value "NEPI_DEVICE_ID" $CURRENT_NEPI_DEVICE_ID $CONFIG_FILE
#     update_yaml_value "NEPI_DEVICE_MD" $CURRENT_NEPI_DEVICE_MD $CONFIG_FILE
#     update_yaml_value "NEPI_DEVICE_SN" $CURRENT_NEPI_DEVICE_ID $CONFIG_FILE
#     update_yaml_value "NEPI_IP" $CURRENT_NEPI_IP $CONFIG_FILE
#     update_yaml_value "NEPI_ALIAS_IPS" $CURRENT_NEPI_ALIAS_IPS $CONFIG_FILE
#     update_yaml_value "NEPI_NTP_IPS" $CURRENT_NEPI_NTP_IPS $CONFIG_FILE
#     update_yaml_value "NEPI_AB_FS" $CURRENT_NEPI_AB_FS $CONFIG_FILE
#     update_yaml_value "NEPI_IMPORT_PATH" $CURRENT_NEPI_IMPORT_PATH $CONFIG_FILE
#     update_yaml_value "NEPI_EXPORT_PATH" $CURRENT_NEPI_EXPORT_PATH $CONFIG_FILE

# }

# #####################################
# # Update NEPI System Config if needed
# #####################################

# if [ -f "$CONFIG_FILE" ]; then
#     print_current_config
    
#     select opt in  "VIEW SETTINGS" "APPLY SETTINGS" "Update NEPI_DEVICE_ID" "Update NEPI_DEVICE_MD" "Update NEPI_DEVICE_SN" "Update NEPI_IP" "Update NEPI_ALIAS_IPS" "Update NEPI_NTP_IPS" "Update NEPI_AB_FS" "Update NEPI_IMPORT_PATH" "Update NEPI_EXPORT_PATH" "QUIT"; do
#         case $opt in
#             "VIEW SETTINGS")
#                 print_config_file $CONFIG_FILE
#                 ;;
#             "APPLY SETTINGS")
#                 udpate_config_file
#                 break
#                 ;;
#             "Update NEPI_DEVICE_ID")
#                 read -p "Enter a new Device ID Name: " USER_INPUT
#                 if is_valid_did "$USER_INPUT"; then
#                     CURRENT_NEPI_DEVICE_ID=$USER_INPUT
#                 else
#                     echo "Not A Valid Device ID"
#                 fi           
#                 print_current_config
#             ;;
#             "Update NEPI_DEVICE_MD")
#                 read -p "Enter a new Device Model Name: " USER_INPUT
#                 if is_valid_string "$USER_INPUT"; then
#                     CURRENT_NEPI_DEVICE_MD=$USER_INPUT
#                 else
#                     echo "Not A Valid Device Model Name"
#                 fi           
#                 print_current_config
#             ;;
#            "Update NEPI_DEVICE_SN")
#                 read -p "Enter a new 6 digit Serial Number: " USER_INPUT
#                 if is_valid_ipv4 "$USER_INPUT"; then
#                     CURRENT_NEPI_IP=$USER_INPUT
#                 else
#                     echo "Not A Valid IP Format"
#                 fi
#                 print_current_config
#                 ;;
#             "Update NEPI_IP")
#                 read -p "Enter a new Static IP Address: " USER_INPUT
#                 if is_valid_ipv4 "$USER_INPUT"; then
#                     CURRENT_NEPI_IP=$USER_INPUT
#                 else
#                     echo "Not A Valid IP Format"
#                 fi

#                 ;;
#             "Update NEPI_ALIAS_IPS")
#                 read -p "Enter a new Alias IP Address, or Empty Line to Clear: " USER_INPUT
#                 if [[ "${USER_INPUT}" == "" ]]; then
#                     USER_INPUT=None
#                 fi
#                 if is_valid_ipv4 "$USER_INPUT" || "${USER_INPUT}" == "None"; then
#                     CURRENT_NEPI_ALIAS_IPS=$USER_INPUT
#                 else
#                     echo "Not A Valid IP Format"
#                 fi
#                 print_current_config
#                 ;;
#             "Update NEPI_NTP_IPS")
#                 read -p "Enter a new NTP Source IP Address, or Empty Line to Clear: " USER_INPUT
#                 if [[ "${USER_INPUT}" == "" ]]; then
#                     USER_INPUT=None
#                 fi
#                 if is_valid_ipv4 "$USER_INPUT" || "${USER_INPUT}" == "None"; then
#                     CURRENT_NEPI_NTP_IPS=$USER_INPUT
#                 else
#                     echo "Not A Valid IP Format"
#                 fi
#                 print_current_config
#                 ;;

#             "Update NEPI_AB_FS")
#                 read -p "Enter 1 or 0 to enable or disable NEPI AB Backup Filesystem: " USER_INPUT
#                 if is_valid_bool "$USER_INPUT" || "${USER_INPUT}" == "None"; then
#                     CURRENT_NEPI_AB_FS=$USER_INPUT
#                 else
#                     echo "Not A Valid Input"
#                 fi
#                 print_current_config
#                 ;;

#             "Update NEPI_IMPORT_PATH")
#                 read -p "Enter a Valid NEPI image Import path: " USER_INPUT
#                 if is_valid_folder "$USER_INPUT" || "${USER_INPUT}" == "None"; then
#                     CURRENT_NEPI_IMPORT_PATH=$USER_INPUT
#                 else
#                     echo "Not A Valid Input"
#                 fi
#                 print_current_config
#                 ;;
#             "Update NEPI_EXPORT_PATH")
#                 read -p "Enter a Valid NEPI image Export path: " USER_INPUT
#                 if is_valid_folder "$USER_INPUT" || "${USER_INPUT}" == "None"; then
#                     CURRENT_NEPI_EXPORT_PATH=$USER_INPUT
#                 else
#                     echo "Not A Valid Input"
#                 fi
#                 print_current_config
#                 ;;
#             "QUIT")
#                 exit 0
#                 ;;
#             *)
#                 print_current_config
#                 ;;
#         esac
#     done
# else
#     echo "${CONFIG_FOLDER} Is Not a Directory"
#     # sudo mkdir -p $CONFIG_FOLDER
#     # sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${CONFIG_FILE}
# fi






echo ""
echo "########################"
echo "Updating OS Configuration"
echo "########################"
echo ""

#############
# Define Folders
NEPI_CONFIG_PATH=/opt/nepi
NEPI_ETC_PATH=${NEPI_CONFIG_PATH}/etc
NEPI_SYS_CONFIG_FILE=${NEPI_ETC_PATH}/nepi_system_config.yaml

FACTORY_CONFIG_PATH=/mnt/nepi_config/factory_cfg
FACTORY_ETC_PATH=${FACTORY_CONFIG_PATH}/etc
FACTORY_SYS_CONFIG_FILE=${FACTORY_ETC_PATH}/nepi_system_config.yaml

SYSTEM_CONFIG_PATH=/mnt/nepi_config/system_cfg
SYSTEM_ETC_PATH=${SYSTEM_CONFIG_PATH}/etc
SYSTEM_SYS_CONFIG_FILE=${SYSTEM_ETC_PATH}/nepi_system_config.yaml
SYSTEM_SYS_CONFIG_UPDATE_FILE=${SYSTEM_ETC_PATH}/nepi_system_config.sh

USER_SYS_CONFIG_FILE=/home/${CONFIG_USER}/nepi_system_config.yaml


####################
echo "Refreshing NEPI CONFIG from ${SYSTEM_ETC_PATH}/load_system_config.sh "
source ${SYSTEM_ETC_PATH}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_ETC_PATH}/load_system_config.sh"
    exit 1
fi

###########################################
# USERS UPDATES
echo "Updating User Configurations"
source ${ETC_FOLDER}/scripts/update_etc_users.sh $LOAD_NEPI_CONFIG

echo "Updating NEPI ETC files in ${SYSTEM_ETC_PATH}"
source ${SYSTEM_ETC_PATH}/update_etc_files.sh
# if [ $? -eq 1 ]; then
#     echo "Failed to update ETC folder ${ETC_NEPI_PATH}"
#     exit 1
# fi


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

echo "*** UPDATES APPLIED ON NEXT REBOOT ***"
echo ""
