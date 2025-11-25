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


if [[ -z "$1" ]]; then
    DEMO_INSTALL=0
else
    DEMO_INSTALL=$1
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


#######################################################################################

# #####################################
# NEPI Config Setup
# #####################################

echo ""
echo "########################"
echo "Configuring NEPI Managed Services"
echo "########################"

# Define Folders
SOURCE_INSTR_PATH=$(dirname "$SCRIPT_FOLDER")
SOURCE_ETC_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
SOURCE_SCRIPTS_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/scripts
SOURCE_SYS_CONFIG_FILE=${SOURCE_ETC_PATH}/nepi_system_config.yaml

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SOURCE_ETC_PATH
sudo chmod -R +x $SOURCE_ETC_PATH



NEPI_CONFIG_PATH=/opt/nepi

NEPI_ETC_PATH=${NEPI_CONFIG_PATH}/etc




systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    SYSTEMD_SERVICE_PATH=/etc/systemd/system

    echo ""
    echo "########"
    echo "Disable apport to avoid crash reports on a display"
    sudo systemctl disable apport  >/dev/null 2>&1
    sudo systemctl stop apport  >/dev/null 2>&1
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




echo ""
echo "########"
echo "Configuring Samba Service"


echo "Updating Samba ETC config file"
if [[ "$CONFIG_USER" == "nepi" ]]; then
    source_file=${SOURCE_ETC_PATH}/samba/smb.conf
else
    source_file=${SOURCE_ETC_PATH}/docker/samba/smb.conf4SERVICES_MANAGED
fi
dest_file=/etc/samba/smb.conf
if [[ -f "$source_file" ]]; then
    sudo cp -d $source_file $dest_file
fi



#################################
# Update Managed Service Settings

NEPI_INSTALL=DEMO
SERVICES_MANAGED=0
if [[ "$DEMO_INSTALL" -eq 0 ]]; then
    NEPI_INSTALL=PRODUCTION
    SERVICES_MANAGED=1
fi

echo "Updating NEPI Config File"

export NEPI_INSTALL=$NEPI_INSTALL
update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_HOSTNAME=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_HOSTNAME" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_NETWORK=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_NETWORK" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_TIME=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_TIME" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE


export NEPI_MANAGES_SSH=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_SSH" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_SHARE=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_SHARE" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_SOFTWARE=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_SOFTWARE" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE

export NEPI_MANAGES_DOCKER=$SERVICES_MANAGED
update_yaml_value "NEPI_MANAGES_DOCKER" $SERVICES_MANAGED $NEPI_SYS_CONFIG_FILE

################################
# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    SYSTEMD_SERVICE_PATH=/etc/systemd/system


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
        sudo systemctl disable systemd-timesyncd  >/dev/null 2>&1
        sudo systemctl stop systemd-timesyncd  >/dev/null 2>&1

        echo "Enabling Chrony Time Services"
        sudo systemctl enable chrony
        sudo systemctl start chrony
    fi


    if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating Network Services"

        echo "Disabling NetworkManager Service" 
        sudo systemctl disable NetworkManager >/dev/null 2>&1
        sudo systemctl stop NetworkManager >/dev/null 2>&1

        echo "Disabling netplan Service" 
        sudo systemctl disable netplan >/dev/null 2>&1
        sudo systemctl stop netplan >/dev/null 2>&1
           
        echo "Enabling ifupdown Networking Service"
        sudo systemctl enable networking
        sudo systemctl start networking
        wait
        sleep 2
        source /opt/nepi/etc/scripts/update_etc_wired_static.sh


    fi


    if [[ "$NEPI_MANAGES_SSH" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating SSH Service Config"
        echo ""


        
        if [[ "$CONFIG_USER" == "nepihost" ]]; then
            source_file=${SOURCE_ETC_PATH}/docker/ssh/sshd_config 
        else
            source_file=${SOURCE_ETC_PATH}/ssh/sshd_config
        fi
        dest_file=/etc/ssh/sshd_config
        if [[ -f "$source_file" ]]; then
            sudo cp $source_file $dest_file
        fi

        echo "Enabling ssh service"
        sudo systemctl enable sshd >/dev/null 2>&1
        wait
        sleep 2
        echo "Updating ssh keys"
        source /opt/nepi/etc/scripts/update_etc_ssh_keys.sh
        
        sudo systemctl restart sshd

    fi


    if [[   "$NEPI_MANAGES_DOCKER" -eq 1 && "$CONFIG_USER" == "nepihost" ]]; then
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



    ###################
    echo ""
    echo "########"
    echo "Setting up Supervisor"
    echo ""

    sudo chmod +x ${NEPI_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf
    sudo cp -a ${NEPI_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf /etc/supervisor/conf.d/supervisord_nepi.conf
    sudo ln -sf /opt/nepi/scripts/nepi_start_all /nepi_start_all
    echo "Restarting Supervisor Process"
    sudo supervisorctl reread >/dev/null 2>&1
    sudo supervisorctl update >/dev/null 2>&1
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
        cp /opt/nepi/etc/services/nepi_check_license.service /etc/systemd/system/
        sudo systemctl enable nepi_check_license

        echo "***** nepi_check_license license manager is installed... you must still provide a valid license file in /mnt/nepi_storage/license *****"
    fi

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
sync_to_config_folder $source_config_path 'factory_cfg' 
sync_to_config_folder $source_config_path 'recovery_cfg' 

source /opt/nepi/etc/scripts/sync_from_configs.sh
source /opt/nepi/docker_cfg/nepi_docker_sync.sh




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


    # Updated the Desktop
    dfolder=/home/${CONFIG_USER}/Desktop
    if [[ -d "$dfolder" ]]; then
        if find "$dfolder" -maxdepth 0 -empty | read; then
            echo "Desktop folder cleaned"
        else
            sudo rm ${dfolder}/*
            echo "Desktop folder cleaned"
        fi
    fi

    sudo cp -rf ${SOURCE_ETC_PATH}/user/mimeapps.list /home/${CONFIG_USER}/.config/mimeapps.list
    sudo cp -rf ${SOURCE_ETC_PATH}/user/nepi_wallpaper.png  /home/${CONFIG_USER}/
    sudo cp -rf ${SOURCE_ETC_PATH}/user/config/gtk-3.0/bookmarks  /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks

    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}

    xdg-user-dirs-update --set DESKTOP "$dfolder"
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.desktop.session idle-delay 0
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
    gsettings set org.gnome.nautilus.preferences show-hidden-files true
    gsettings set org.gnome.desktop.background picture-uri file:////home/${CONFIG_USER}/nepi_wallpaper.png


    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'chromium_chromium.desktop', \
    'org.gnome.Terminal.desktop', 'code.desktop', 'org.gnome.gedit.desktop', 'org.gnome.Screenshot.desktop', \
    'gnome-control-center.desktop']"


    ###################

    echo "########"
    echo "Updating Chrome settings for user ${CONFIG_USER}"

    fix_chromium

    xdg-settings set default-web-browser chromium-browser.desktop

    sudo cp -rf ${SOURCE_ETC_PATH/}/user/snap/chromium/common/chromium/Default/*  /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER} /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/*


    #sudo rm -rf ~/.config/chromium/Singleton* 


    
fi


echo ""
echo "########################"
echo "Cleaning Config System"
echo ""


sudo rm -r  /home/${CONFIG_USER}/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r  /home/${CONFIG_USER}/.local/share/Trash/files/ 2>/dev/null
sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null

##########
sudo journalctl --vacuum-size=50M  # Limits journal size to 50MB
sudo journalctl --vacuum-time=7d   # Keeps logs for 7 days

echo ""
echo "##################################"
echo 'NEPI Setup Complete'
echo "##################################"

# echo ""
# echo "*** REBOOT YOUR DEVICE ***"

