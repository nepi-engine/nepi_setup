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

sudo -v

export CONFIG_USER=$(id -un 1000)


if [[ "$CONFIG_USER" != 'nepi' && "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi' or 'nepihost'"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


echo "########################"
echo "NEPI CONFIG SETUP"
echo "########################"



echo "Checking Requirements"

# Check Valid Software
if command -v yq &>/dev/null; then
    : # Do nothing here
elif is_valid_internet; then
    echo "Installing yq software"
    sudo add-apt-repository ppa:rmescandon/yq -y
    sudo apt update
    sudo apt install yq -y
fi
if command -v yq &>/dev/null; then
    : # Do nothing here
else
    echo "EXITING"
    echo "yq application is not installed"
    echo "Connect to internet and rerun this script"
    exit 1
fi


#######################################################################################
echo ""
echo "#########"
echo " Updating NEPI Config Files"
echo ""

# Define Folders
SOURCE_INSTR_PATH=$(dirname "$SCRIPT_FOLDER")
SOURCE_ETC_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
SOURCE_SYS_CONFIG_FILE=${SOURCE_ETC_PATH}/nepi_system_config.yaml
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SOURCE_ETC_PATH
sudo chmod -R +x $SOURCE_ETC_PATH

SOURCE_NEPI_SCRIPTS_PATH=$(dirname "$SCRIPT_FOLDER")/resources/scripts
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SOURCE_NEPI_SCRIPTS_PATH
sudo chmod -R +x $SOURCE_NEPI_SCRIPTS_PATH

SOURCE_DOCKER_SCRIPTS_PATH=$(dirname "$SCRIPT_FOLDER")/resources/docker
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SOURCE_DOCKER_SCRIPTS_PATH
sudo chmod -R +x $SOURCE_DOCKER_SCRIPTS_PATH


NEPI_CONFIG_PATH=/opt/nepi

NEPI_ETC_PATH=${NEPI_CONFIG_PATH}/etc
NEPI_SYS_CONFIG_FILE=${NEPI_ETC_PATH}/nepi_system_config.yaml

NEPI_SCRIPTS_PATH=${NEPI_CONFIG_PATH}/scripts

NEPI_DOCKER_CONFIG_PATH=${NEPI_CONFIG_PATH}/docker_cfg
NEPI_DOCKER_CONFIG_FILE=${NEPI_DOCKER_CONFIG_PATH}/nepi_docker_config.yaml



###################
#  Sync and Load NEPI Config File

if [[ ! -d "$NEPI_CONFIG_PATH" ]]; then
    sudo mkdir -p $NEPI_CONFIG_PATH
fi
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_CONFIG_PATH

if [[ ! -f "$NEPI_SYS_CONFIG_FILE" ]]; then
    sudo cp -r -p "${SOURCE_ETC_PATH}/nepi_system_config.yaml" ${NEPI_SYS_CONFIG_FILE}
else
    sync_yaml_files ${SOURCE_ETC_PATH}/nepi_system_config.yaml ${NEPI_SYS_CONFIG_FILE}
fi




############
echo ""
echo "###########"
echo "Updating NEPI Config Folders"
echo ""

if [[ ! -d "$NEPI_CONFIG_PATH" ]]; then
    sudo mkdir -p $NEPI_CONFIG_PATH 
    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_CONFIG_PATH}
fi

#############

if [[ ! -d "$NEPI_ETC_PATH" ]]; then
    sudo mkdir -p $NEPI_ETC_PATH 
    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_ETC_PATH}
fi


if [[ ! -f "$NEPI_SYS_CONFIG_FILE" ]]; then
    sudo cp -p $SOURCE_SYS_CONFIG_FILE $NEPI_SYS_CONFIG_FILE
fi
SOURCE_PATH=${SOURCE_SYS_CONFIG_FILE}
UPDATE_PATH=${NEPI_SYS_CONFIG_FILE}
echo "Syncing NEPI System Config YAML File from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $SOURCE_PATH $UPDATE_PATH


if [[ "$SOURCE_ETC_PATH" != "/etc" && -n "$SOURCE_ETC_PATH" ]]; then

    SOURCE_PATH=$SOURCE_ETC_PATH
    UPDATE_PATH=$NEPI_ETC_PATH

    echo "Syncing ETC Folder from ${SOURCE_PATH} to ${UPDATE_PATH}"
    echo "Excluding nepi_system_config.yaml file"
    sudo rsync -arh --exclude='nepi_system_config.yaml' ${SOURCE_PATH}/ ${UPDATE_PATH}/

fi


# Install NEPI Sciprts

if [[ ! -d "$NEPI_SCRIPTS_PATH" ]]; then
    sudo mkdir -p $NEPI_SCRIPTS_PATH 
    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_SCRIPTS_PATH}
fi

SOURCE_PATH=${SOURCE_NEPI_SCRIPTS_PATH}
UPDATE_PATH=/opt/nepi/scripts
echo "Copying NEPI System Scripts Files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "$UPDATE_PATH" ]]; then
    sudo mkdir -p $UPDATE_PATH
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $UPDATE_PATH
fi
sudo cp -r ${SOURCE_PATH}/* ${UPDATE_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod +x ${UPDATE_PATH}/*


# Install Docker Sciprts

if [[ ! -d "$NEPI_SCRIPTS_PATH" ]]; then
    sudo mkdir -p $NEPI_SCRIPTS_PATH 
    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${NEPI_SCRIPTS_PATH}
fi

SOURCE_PATH=${SOURCE_DOCKER_SCRIPTS_PATH}
UPDATE_PATH=/opt/nepi/docker_cfg
echo "Copying NEPI Docker Scripts Files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -d "$UPDATE_PATH" ]]; then
    sudo mkdir -p $UPDATE_PATH
fi
sudo cp -r ${SOURCE_PATH}/* ${UPDATE_PATH}/
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod +x ${UPDATE_PATH}/*


################
# Update NEPI System Config Files

echo "Updating NEPI Config File Settings"



source $NEPI_CONFIG_LOAD_FILE
if [[ "$1" -ne 0 ]]; then
    echo "Failed to find load config file at: ${NEPI_CONFIG_LOAD_FILE}"
    exit 1
fi

###################
#  Upated NEPI Config File

echo "Updating NEPI Config File"

export NEPI_MANAGES_HOSTNAME=1
update_yaml_value "NEPI_MANAGES_HOSTNAME" 1 $NEPI_SYS_CONFIG_FILE


export NEPI_MANAGES_NETWORK=1
update_yaml_value "NEPI_MANAGES_NETWORK" 1 $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_TIME=1
update_yaml_value "NEPI_MANAGES_TIME" 1 $NEPI_SYS_CONFIG_FILE


export NEPI_MANAGES_SSH=1
update_yaml_value "NEPI_MANAGES_SSH" 1 $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_SHARE=1
update_yaml_value "NEPI_MANAGES_SHARE" 1 $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_SOFTWARE=1
update_yaml_value "NEPI_MANAGES_SOFTWARE" 1 $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_DOCKER=1
update_yaml_value "NEPI_MANAGES_DOCKER" 1 $NEPI_SYS_CONFIG_FILE

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

if [[ -z $NEPI_AB_FS ]]; then
    NEPI_AB_FS=0
fi
update_yaml_value "NEPI_AB_FS" $NEPI_AB_FS $NEPI_DOCKER_CONFIG_FILE



#######################################################################################

# Update Config Folders
echo ""
echo "Running Sync to Configs Script"
source /opt/nepi/etc/scripts/sync_to_configs.sh

#######################################################################################


# #####################################
# NEPI ENV SETUPS
# #####################################

echo ""
echo "########################"
echo "Configuring NEPI Managed Services"
echo "########################"

systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    SYSTEMD_SERVICE_PATH=/etc/systemd/system

    echo ""
    echo "########"
    echo "Disable apport to avoid crash reports on a display"
    sudo systemctl disable apport
    sudo systemctl stop apport
fi
etc_path=default/apport
sudo rm /etc/${etc_path}
sudo cp ${SOURCE_ETC_PATH}/${etc_path} /etc/${etc_path}  >/dev/null 2>&1

sudo rm /var/crash/* 2>/dev/null
 
echo ""
echo "########"
echo "Configuring nepi_modprobe.conf"
etc_path=modprobe.d/nepi_modprobe.conf
sudo rm /etc/${etc_path}
sudo cp ${SOURCE_ETC_PATH}/${etc_path} /etc/${etc_path}  >/dev/null 2>&1


echo ""
echo "########"
echo "Setting up udev rules"
    # IQR Pan/Tilt
sudo cp ${SOURCE_ETC_PATH}/udev/rules.d/* /etc/udev/rules.d/

echo ""
echo "########"
echo "Setting up Baumer GenTL Producers (Genicam support)"

if [ ! -d "/opt/baumer" ]; then
    sudo rm -r /opt/baumer
fi
sudo cp -r ${SOURCE_ETC_PATH}/opt/baumer /opt/baumer
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/baumer

# Set up the shared object links in case they weren't copied properly when this repo was moved to target
NEPI_BAUMER_PATH=${NEPI_ETC_PATH}/opt/baumer/gentl_producers
ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14.1 $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14
ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14 $NEPI_BAUMER_PATH/libbgapi2_usb.cti
ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14.1 $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14
ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14 $NEPI_BAUMER_PATH/libbgapi2_gige.cti



################################
# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    SYSTEMD_SERVICE_PATH=/etc/systemd/system



    echo ""
    echo "########"
    echo "Configuring Samba Service"

    if [[ "$CONFIG_USER" == "nepihost" ]]; then
        samba_file=${SOURCE_ETC_PATH}/docker/samba/smb.conf
    else
        samba_file=${SOURCE_ETC_PATH}/samba/smb.conf
    fi


    echo "Updating Samba ETC config file"
    if [ -f "/etc/samba/smb.conf" ]; then
        sudo rm -r /etc/samba/smb.conf
    fi
    sudo cp -d ${samba_file} /etc/samba/smb.conf


    echo "Restarting Samba Service"

    sudo systemctl enable smbd
    sudo systemctl restart smbd
    

    # echo "Updating Samba Users"
    # echo -e "$NEPI_USER_PW\n$NEPI_USER_PW" | sudo smbpasswd -a -s "$NEPI_USER" > /dev/null

    # echo -e "$NEPI_HOST_PW\n$NEPI_HOST_PW" | sudo smbpasswd -a -s "$NEPI_HOST_USER" > /dev/null
    # sudo usermod -a -G $NEPI_USER $NEPI_HOST_USER > /dev/null

    # echo -e "$NEPI_ADMIN_PW\n$NEPI_ADMIN_PW" | sudo smbpasswd -a -s "$NEPI_ADMIN_USER" > /dev/null
    # sudo usermod -a


    if [[ "$NEPI_MANAGES_TIME" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating Time Management service config"
        echo "Disable systemd-timesyncd time management"
        sudo systemctl disable systemd-timesyncd
        sudo systemctl stop systemd-timesyncd

        echo "Enabling chrony time service"
        sudo systemctl enable chrony
        sudo systemctl start chrony
    fi


    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating Network services"

        echo "Disabling NetworkManager Service" 
        sudo systemctl disable NetworkManager
        sudo systemctl stop NetworkManager

        echo "Disabling netplan Service" 
        sudo systemctl disable netplan
        sudo systemctl stop netplan
           
        echo "Enabling ifupdown networking service"
        sudo systemctl enable networking
        sudo systemctl start networking
        wait
        sleep 2
        source /opt/nepi/etc/scripts/update_etc_wired_static.sh


    fi


    if [[ "$NEPI_MANAGES_SSH" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating SSH service config"
        echo ""

        if [[ -f "/etc/ssh/sshd_config" ]]; then
            sudo rm -r /etc/ssh/sshd_config
        fi

        if [[ "$CONFIG_USER" == "nepihost" ]]; then
            sudo cp ${SOURCE_ETC_PATH}/docker/ssh/sshd_config /etc/ssh/sshd_config
        else
            sudo cp ${SOURCE_ETC_PATH}/ssh/sshd_config /etc/ssh/sshd_config
        fi

        echo "Installing nepi ssh key files for user ${CONFIG_USER}"
        if [ ! -d "/home/${CONFIG_USER}/.ssh" ]; then
            sudo mkdir /home/${CONFIG_USER}/.ssh
        fi 
        sudo cp ${SOURCE_ETC_PATH}/ssh/authorized_keys /home/${CONFIG_USER}/.ssh/authorized_keys
        sudo chmod 0600 /home/${CONFIG_USER}/.ssh/authorized_keys
        sudo chmod 0700 /home/${CONFIG_USER}/.ssh
        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.ssh

        echo "Installing nepi ssh key files for user ${NEPI_USER}"
        if [ ! -d "/home/${NEPI_USER}/.ssh" ]; then
            sudo mkdir /home/${NEPI_USER}/.ssh
        fi 
        sudo cp ${SOURCE_ETC_PATH}/ssh/authorized_keys /home/${NEPI_USER}/.ssh/authorized_keys
        sudo chmod 0600 /home/${NEPI_USER}/.ssh/authorized_keys
        sudo chmod 0700 /home/${NEPI_USER}/.ssh
        sudo chown -R ${NEPI_USER}:${NEPI_USER} /home/${NEPI_USER}/.ssh

        echo "Installing nepi ssh key files for user ${NEPI_ADMIN_USER}"
        if [ ! -d "/home/${NEPI_ADMIN_USER}/.ssh" ]; then
            sudo mkdir /home/${NEPI_ADMIN_USER}/.ssh
        fi 
        sudo cp ${SOURCE_ETC_PATH}/ssh/authorized_keys /home/${NEPI_ADMIN_USER}/.ssh/authorized_keys
        sudo chmod 0600 /home/${NEPI_ADMIN_USER}/.ssh/authorized_keys
        sudo chmod 0700 /home/${NEPI_ADMIN_USER}/.ssh
        sudo chown -R ${NEPI_ADMIN_USER}:${NEPI_ADMIN_USER} /home/${NEPI_ADMIN_USER}/.ssh

        sudo systemctl enable sshd
        sudo systemctl restart sshd
   
    fi


    if [[ "$CONFIG_USER" == "nepihost" &&  "$NEPI_MANAGES_DOCKER" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating Docker Service Config"
        echo ""


        echo "Stopping Docker Service"
        sudo systemctl stop docker
        sudo systemctl stop docker.socket       

        if [[ ! -f "/etc/docker/daemon.json.org" ]]; then
            sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.org
        fi
        
        sudo nvidia-ctk runtime configure --runtime=docker


        # Set docker service root location
        #https://stackoverflow.com/questions/44010124/where-does-docker-store-its-temp-files-during-extraction
        # https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169

        ## Update docker file
        echo "Setting Docker File Path to ${NEPI_DOCKER}"
        echo "Updating docker file /etc/default/docker"
        FILE=/etc/default/docker
        UPDATE="DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4  -g ${NEPI_DOCKER}\""
        echo $UPDATE
        KEY=DOCKER_OPTS
        sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"
        KEY='#DOCKER_OPTS'
        sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"


        ## Update docker service file
        echo "Updating docker file /usr/lib/systemd/system/docker.service"
        FILE=/usr/lib/systemd/system/docker.service


        KEY=RequiresMountsFor
        UPDATE="RequiresMountsFor=${NEPI_DOCKER}"

        if grep -q "${KEY}" $FILE; then
            echo "Updating Docker Required Mounts with ${UPDATE}"
            sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"
        else
            echo "Adding Docker Required Mounts with ${UPDATE}"
            sudo sed -i '/Requires=docker.socket/a\'${UPDATE} $FILE
        fi

        KEY=ExecStart
        UPDATE="ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --data-root=${NEPI_DOCKER}"
        echo $UPDATE
        sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"


        echo ""
        echo "Enabling Docker Service"
        sudo systemctl daemon-reload
        sudo systemctl start docker.socket
        sudo systemctl start docker
        

        #########Test Docker install###########
        #sudo systemctl status docker
        # sudo docker pull hello-world
        # sudo docker container run hello-world

        # #Some Debug Commands
        # sudo dockerd --debug
        # sudo cat /etc/docker/daemon.json

        # sudo systemctl stop docker
        # sudo systemctl stop docker.socket
        # sudo systemctl daemon-reload
        # sudo systemctl start docker.socket
        # sudo systemctl start docker
        # sudo systemctl status docker
        # sudo docker info
    fi





else

    echo ""
    echo "########"
    echo "Setting up Supervisor"
    echo ""

    sudo chmod +x ${NEPI_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf
    sudo cp -a ${NEPI_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf /etc/supervisor/conf.d/supervisord_nepi.conf

    echo "Restarting Supervisor Process"
    sudo supervisorctl reread
    sudo supervisorctl update
    # sudo supervisorctl status
    # sudo supervisorctl tail nepi_engine
    # sudo supervisorctl tail nepi_rui
    # sudo supervisorctl tail nepi_license
    # sudo supervisorctl tail nepi_ssh
    # sudo supervisorctl tail nepi_samba

fi



# #####################################
# NEPI ETC UPDATES
# #####################################

echo ""
echo "########################"
echo "Updating NEPI OS Config"
echo "########################"
echo ""
config_update_file=/mnt/nepi_config/system_cfg/etc/nepi_system_config.sh
echo "Running System Config Update Script: ${config_update_file}"
source $config_update_file


# #####################################
# NEPI Services Setup
# #####################################


# #####################################
# NEPI Services Setup
# #####################################


echo "##################################"
echo 'Setting Up NEPI Services'
echo "##################################"
echo ""

SYSTEMD_SERVICE_PATH=/etc/systemd/system
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    if [[ "$CONFIG_USER" == "nepihost" ]]; then
        #############################
        echo ""
        echo "############"
        echo "Setting Up NEPI Docker Service"
        echo ""
        
        sudo cp -a ${NEPI_ETC_PATH}/docker/services/nepi_docker.service ${SYSTEMD_SERVICE_PATH}/nepi_docker.service

        # sudo systemctl enable nepi_docker
        # sudo systemctl restart nepi_docker
    else

        echo ""
        echo "############"
        echo "Setting Up NEPI Engine Service"

        echo "Cofiguring NEPI Engine Service from ${NEPI_ETC_PATH}/services"
        sudo chmod +x ${NEPI_ETC_PATH}/services/*
        sudo cp -a ${NEPI_ETC_PATH}/services/* ${SYSTEMD_SERVICE_PATH}/
        sudo systemctl enable nepi_engine

        echo ""
        echo "############"
        echo "Setting Up NEPI License Service"


        # Set up nepi_check_license (license management, etc.)
        chmod +x /opt/nepi/etc/license/nepi_check_license.py
        gpg --import /opt/nepi/etc/license/nepi_license_management_public_key.gpg

        # Update ETC files if systemd is running (Not in Container)
        systemctl&> /dev/null
        if [[ "$?" -eq 0 ]]; then
            cp /opt/nepi/etc/services/nepi_check_license.service /etc/systemd/system/
            sudo systemctl enable nepi_check_license
        fi

        echo "***** nepi_check_license license manager is installed... you must still provide a valid license file in /mnt/nepi_storage/license *****"
    fi

fi




if [[ -n "$DISPLAY" ]]; then

    echo ""
    echo "########################"
    echo "Updating USER Desktop Files"
    echo "########################"
    echo ""
    ##############################################
    # Update User Files
    echo ""
    echo "########"
    echo "Updating Desktop settings for user ${CONFIG_USER}"
    echo ""


    # Clear the Desktop
    dfolder=/home/${CONFIG_USER}/Desktop
    if [[ -d "$dfolder" ]]; then
        if find "$dfolder" -maxdepth 0 -empty | read; then
            echo "Desktop folder cleaned"
        else
            sudo rm ${dfolder}/*
            echo "Desktop folder cleaned"
        fi
    fi
    xdg-user-dirs-update --set DESKTOP "$dfolder"


    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'chromium_chromium.desktop', \
        'org.gnome.Terminal.desktop', 'code.desktop', 'org.gnome.gedit.desktop', 'org.gnome.Screenshot.desktop', \
        'gnome-control-center.desktop']"

    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.desktop.session idle-delay 0

    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

    sudo cp -rf ${SOURCE_ETC_PATH}/user/mimeapps.list /home/${CONFIG_USER}/.config/mimeapps.list

    sudo cp -rf ${SOURCE_ETC_PATH}/user/nepi_wallpaper.png  /home/${CONFIG_USER}/
    gsettings set org.gnome.desktop.background picture-uri file:////home/${CONFIG_USER}/nepi_wallpaper.png

    echo "Updating Desktop Folder Bookmarks settings for user ${CONFIG_USER}"
    sudo cp -rf ${SOURCE_ETC_PATH}/user/config/gtk-3.0/bookmarks  /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks


    # ninet
    # echo "Installing Chromium Browser"
    # sudo snap remove --purge chromium
    # sudo snap install chromium
    # #sudo apt install chromium-browser -y
    # #chromium-browser --disable-features=DnsOverHttps

    echo "########"
    echo "Updating Chrome settings for user ${CONFIG_USER}"
    #sudo rm -rf /home/${CONFIG_USER}/.config/chromium/* 2>/dev/null
    #sudo rm -rf /home/${CONFIG_USER}/snap/chromium/* 2>/dev/null
    sudo cp -rf ${SOURCE_ETC_PATH/}/user/snap/chromium/common/chromium/Default/*  /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/

    sudo rm -rf /home/${CONFIG_USER}/.cache/chromium 2>/dev/null
    sudo rm -rf /home/${CONFIG_USER}/snap/.cache/chromium 2>/dev/null


    # Copy instructions to desktop
    instr_file=${SOURCE_INSTR_PATH}/NEPI_DOCKER_HOST_SETUP.md
    sudo cp -p $instr_file /home/${CONFIG_USER}/Desktop/
fi

# #####################################
# SYNC FROM SYSTEM CONFIG
# #####################################
echo ""
echo "########################"
echo "Syncing Config Files and Folders"
echo "########################"
echo ""
############
# Update Config Folders

source_config_path=/mnt/nepi_config/system_cfg
sync_to_config_folder 'factory_cfg' $source_config_path
sync_to_config_folder 'recovery_cfg' $source_config_path

source /opt/nepi/etc/scripts/sync_from_configs.sh


echo ""
echo "########################"
echo "Cleaning Config System"
echo "########################"


sudo rm -r ~/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r ~/.local/share/Trash/files/ 2>/dev/null
sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null

echo ""
echo "##################################"
echo 'NEPI Config Setup Complete'
echo "##################################"

# echo ""
# echo "*** REBOOT YOUR DEVICE ***"

