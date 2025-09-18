#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs the NEPI Engine File System installation

echo "########################"
echo "NEPI CONFIG SETUP"
echo "########################"



###################

CONFIG_USER=nepi
NEPI_SYSTEM_CONFIG_SOURCE=$(dirname "$(pwd)")/config/nepi_system_config.yaml
NEPI_SYSTEM_PATH=/opt/nepi
NEPI_SYSTEM_CONFIG_DEST_PATH=/mnt/nepi_config/factory_cfg/etc
NEPI_SYSTEM_CONFIG_DEST=${NEPI_SYSTEM_CONFIG_DEST_PATH}/nepi_system_config.yaml


###################
# Copy ETC Files
###################
ETC_SOURCE_PATH=$(dirname "$(pwd)")/resources/etc
ETC_DEST_PATH=$NEPI_SYSTEM_CONFIG_DEST_PATH

echo ""
echo "Populating Factory ETC Folder from ${ETC_SOURCE_PATH} to ${ETC_DEST_PATH}"
sudo mkdir -p $ETC_DEST_PATH
sudo cp -R ${ETC_SOURCE_PATH}/* ${ETC_DEST_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $ETC_DEST_PATH
sudo chmod -R 775 $ETC_DEST_PATH


SCRIPTS_SOURCE_PATH=$(dirname "$(pwd)")/resources/scripts
SCRIPTS_DEST_PATH=${NEPI_SYSTEM_PATH}/scripts
echo ""
echo "Populating System Scripts Folder from ${SCRIPTS_SOURCE_PATH} to ${SCRIPTS_DEST_PATH}"
sudo mkdir -p $SCRIPTS_DEST_PATH
sudo cp -R ${SCRIPTS_SOURCE_PATH}/* ${SCRIPTS_DEST_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SCRIPTS_DEST_PATH
sudo chmod -R 775 $SCRIPTS_DEST_PATH

if [ -f "$NEPI_SYSTEM_CONFIG_DEST" ]; then
    ## Check Selection
    echo ""
    echo ""
    echo "Do You Want to OverWrite System Config: ${OP_SELECTION}"
    select ovw in "View_Original" "View_New" "Yes" "No" "Quit"; do
        case $ovw in
            View_Original ) print_config_file $NEPI_SYSTEM_CONFIG_DEST;;
            View_New )  print_config_file $NEPI_SYSTEM_CONFIG_SOURCE;;
            Yes ) OVERWRITE=1; break;;
            No ) OVERWRITE=0; break;;
            Quit ) exit 1
        esac
    done


    if [ "$OVERWRITE" -eq 1 ]; then
    echo "Updating NEPI CONFIG ${NEPI_SYSTEM_CONFIG_DEST} "
    sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${NEPI_SYSTEM_CONFIG_DEST}
    fi

else
    sudo mkdir -p $NEPI_SYSTEM_CONFIG_DEST_PATH
    sudo cp ${NEPI_SYSTEM_CONFIG_SOURCE} ${NEPI_SYSTEM_CONFIG_DEST}

fi

echo "Refreshing NEPI CONFIG from ${NEPI_SYSTEM_CONFIG_DEST} "
source ${NEPI_SYSTEM_CONFIG_DEST_PATH}/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${NEPI_SYSTEM_CONFIG_DEST_PATH}/load_system_config.sh"
    exit 1
fi

CONFIG_USER=$NEPI_USER
if [[ "$USER" != "$CONFIG_USER" ]]; then
    echo "This script must be run by user account ${CONFIG_USER}."
    echo "Log in as ${CONFIG_USER} and run again"
    exit 1
fi

#################################
# Create Nepi Required Folders
#################################

# # Run NEPI Docker Storage Config File
# SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
# source ${SCRIPT_FOLDER}/docker_storage_setup.sh
# if [ $? -eq 1 ]; then
#     echo "Failed to load ${SCRIPT_FOLDER}/nepi_storage_setup.sh"
#     exit 1
# fi



########################
# INSTALL NEPI SSH KEY
########################
CONFIG_USER=$USER
NEPI_SSH_DIR=/home/${CONFIG_USER}/ssh_keys
NEPI_SSH_FILE=nepi_engine_default_private_ssh_key

# Add nepi ssh key if not there
echo "Checking nepi ssh key file"
NEPI_SSH_PATH=${NEPI_SSH_DIR}/${NEPI_SSH_FILE}
NEPI_SSH_SOURCE=$(dirname "$(pwd)")/resources/ssh_keys/${NEPI_SSH_FILE}
if [ -e $NEPI_SSH_PATH ]; then
    echo "Found NEPI ssh private key ${NEPI_SSH_PATH} "
else
    echo "Installing NEPI ssh private key ${NEPI_SSH_PATH} "
    mkdir $NEPI_SSH_DIR
    cp $NEPI_SSH_SOURCE $NEPI_SSH_PATH
fi
sudo chmod 600 $NEPI_SSH_PATH
sudo chmod 700 $NEPI_SSH_DIR
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_SSH_DIR



#######################################
# Update SSH System
#######################################
echo " "
echo "Configuring SSH Keys"
# And default public key - Make sure all ownership and permissions are as required by SSH
sudo chown ${CONFIG_USER}:${CONFIG_USER} ${ETC_SOURCE_PATH}/ssh/authorized_keys
sudo chmod 0600 ${ETC_SOURCE_PATH}/ssh/authorized_keys

if [ ! -d "/home/${CONFIG_USER}/.ssh" ]; then
    sudo mkdir /home/${CONFIG_USER}/.ssh
fi

if [ -f "/home/${CONFIG_USER}/.ssh/authorized_keys" ]; then
    sudo rm /home/${CONFIG_USER}/.ssh/authorized_keys
fi
sudo cp ${ETC_SOURCE_PATH}/ssh/authorized_keys /home/${CONFIG_USER}/.ssh/authorized_keys
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.ssh/authorized_keys
sudo chmod 0600 /home/${CONFIG_USER}/.ssh/authorized_keys

sudo chmod 0700 /home/${CONFIG_USER}/.ssh
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.ssh

echo "Updating SSH service config"

sudo rm -r /etc/ssh/sshd_config
sudo cp ${ETC_SOURCE_PATH}/ssh/sshd_config /etc/ssh/sshd_config


if [[ "$NEPI_IN_CONTAINER" -eq 0 ]]; the
    # Unmask if needed  https://www.baeldung.com/linux/systemd-unmask-services
    service_name=sshd

    #service_file=$(sudo find /etc /usr/lib -name "${service_name}.service*")
    #if [[ "$service_file" != "" ]]; then
    #    sudo systemctl unmask ${service_name}
    #    sudo rm ${service_file}
    #    sudo systemctl daemon-reload
    #fi
    #sudo systemctl status ${service_name}
    sudo systemctl enable ${service_name}
    sudo systemctl restart ${service_name}
    #sudo systemctl status ${service_name}
fi


###########################################
# Install Modeprobe Conf
echo " "
echo "Configuring nepi_modprobe.conf"
etc_path=modprobe.d/nepi_modprobe.conf
sudo rm /etc/${etc_path}
sudo cp ${ETC_DEST_PATH}/${etc_path} /etc/${etc_path}

#############################################
# Set up some udev rules for plug-and-play hardware
echo " "
echo "Setting up udev rules"
    # IQR Pan/Tilt
sudo cp ${ETC_DEST_PATH}/udev/rules.d/* /etc/udev/rules.d/
    
##############################################
# Update the Desktop background image
echo ""
echo "Updating Desktop background image"
# Update the login screen background image - handled by a sys. config file
# No longer works as of Ubuntu 20.04 -- there are some Github scripts that could replace this -- change-gdb-background
#echo "Updating login screen background image"
#sudo cp ${NEPI_CONFIG}/usr/share/gnome-shell/theme/ubuntu.css ${NEPI_ETC}/ubuntu.css
#sudo ln -sf ${NEPI_ETC}/ubuntu.css /usr/share/gnome-shell/theme/ubuntu.css
gsettings set org.gnome.desktop.background picture-uri file:///${ETC_DEST_PATH}/nepi/nepi_wallpaper.png



#######################################
# Update NEPI ETC to OS System ETC Linked files
#######################################
if [[ "$NEPI_MANAGES_ETC" -eq 1 ]]; then
    echo "Updating NEPI ETC Sync Service"

    sudo systemctl stop lsyncd
    sudo cp -r ${ETC_SOURCE_PATH}/lsyncd /etc/
#     lsyncd_file=${SCRIPT_FOLDER}/etc/lsyncd/lsyncd.conf
#     function add_etc_sync(){
#         etc_sync=${NEPI_CONFIG}/docker_cfg/etc/${1}
#         etc_dest=/etc/${1}
#         echo "" | sudo tee -a $lsyncd_file
#         echo "sync {" | sudo tee -a $lsyncd_file
#         echo "    default.rsync," | sudo tee -a $lsyncd_file
#         echo '    source = "'${etc_sync}'/",' | sudo tee -a $lsyncd_file
#         echo '    target = "'${etc_dest}'/",' | sudo tee -a $lsyncd_file
#         echo "}" | sudo tee -a $lsyncd_file
#         echo " " | sudo tee -a $lsyncd_file
#     }
#     sudo chown -R ${USER}:${USER} ${lsyncd_file}

#     if [ "$NEPI_MANAGES_HOSTNAME" -eq 1 ]; then
#         add_etc_sync hosts
#         add_etc_sync hostname
#     fi

#     if [ "$NEPI_MANAGES_NETWORK" -eq 1 ]; then
#         add_etc_sync /network/interfaces.d
#         add_etc_sync network/interfaces
#         add_etc_sync dhcp/dhclient.conf
#         add_etc_sync wpa_supplicant
#     fi
    
#     if [ "$NEPI_MANAGES_TIME" -eq 1 ]; then
#         add_etc_sync ${etc_path}
        
#     fi

#     if [ "$NEPI_MANAGES_SSH" -eq 1 ]; then
#         add_etc_sync ssh/sshd_config
#     fi


#     # start the sync service
#     echo "Starting NEPI ETC Sycn service"
#     sudo systemctl start lsyncd    

fi


###############
# RUN ETC UPDATE SCRIPT
###############
echo "Updating NEPI Config files in ${ETC_DEST_PATH}"
source ${ETC_DEST_PATH}/update_etc_files.sh
if [ $? -eq 1 ]; then
    echo "Failed to update ETC folder ${ETC_DEST_PATH}"
    exit 1
fi



#########################################
# Setup NEPI Engine services
#########################################
NEPI_ETC=${NEPI_BASE}/etc
echo "Updating system env bash file"
sudo chmod +x ${NEPI_ETC}/sys_env.bash
sudo rm ${NEPI_BASE}/sys_env.bash
sudo cp ${NEPI_ETC}/sys_env.bash ${NEPI_BASE}/sys_env.bash


if [[ "$NEPI_IN_CONTAINER" -eq 0 ]]; then

    SYSTEMD_SERVICE_PATH=/etc/systemd/system
    echo ""
    echo "Setting up NEPI Engine Services"

    sudo chmod +x ${NEPI_ETC}/services/*
    sudo cp -a ${NEPI_ETC}/services/* ${SYSTEMD_SERVICE_PATH}/

    sudo systemctl enable nepi_engine
else

    sudo chmod +x ${NEPI_ETC}/etc/supervisor/conf.d/supervisord_nepi.conf
    sudo cp -a ${NEPI_ETC}/etc/supervisor/conf.d/supervisord_nepi.conf /etc/supervisor/conf.d/supervisord_nepi.conf

fi




#####################################
# Backup NEPI folders to catch final changes
#####################################
if [[ "$NEPI_MANAGES_ETC" -eq 1 ]]; then
    back_ext=nepi
    overwrite=1

    ### Backup ETC folder
    folder=/etc
    folder_back=${folder}.${back_ext}
    path_backup $folder $folder_back $overwrite

    ### Backup USR LIB SYSTEMD folder
    folder=/usr/lib/systemd/system
    folder_back=${folder}.${back_ext}
    path_backup $folder $folder_back $overwrite

    ### Backup RUN SYSTEMD folder
    folder=/run/systemd/system
    folder_back=${folder}.${back_ext}
    path_backup $folder $folder_back $overwrite

    ### Backup USR LIB SYSTEMD USER folder
    folder=/usr/lib/systemd/user
    folder_back=${folder}.${back_ext}
    path_backup $folder $folder_back $overwrite
fi

#sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_SYSTEM_PATH
##############################################
echo "NEPI Config Setup Complete"
##############################################

