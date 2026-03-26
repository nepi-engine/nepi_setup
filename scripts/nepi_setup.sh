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
## Redistributions in source code must retain this top-level comment block, 
## Along with any License Check related code and checks.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##
LITE_INSTALL=0
if [[ "$1" -eq 1 ]] 2>/dev/null; then
    LITE_INSTALL=$1
fi
# echo "LITE_INSTALL=${LITE_INSTALL}"

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

# Load System Config File
#echo "Loading NEPI SYSTEM CONFIG"
NEPI_SETUP_CONFIG_FILE=${RESOURCES_FOLDER}/etc/load_system_config.sh
NEPI_SYSTEM_CONFIG_FILE=/mnt/nepi_confg/system_cfg/etc/load_system_config.sh
if [[ -f $NEPI_SYSTEM_CONFIG_FILE ]]; then
    source ${NEPI_SYSTEM_CONFIG_FILE}
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SYSTEM_CONFIG_FILE}"
    fi
elif [[ -f $NEPI_SETUP_CONFIG_FILE ]]; then
    source ${NEPI_SETUP_CONFIG_FILE}
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SETUP_CONFIG_FILE}"
    fi
fi






#######################################################################################


echo "########################"
echo "NEPI CONFIG SETUP"
echo "########################"
# #####################################
# NEPI Config Setup
# #####################################

echo ""
echo "########################"
echo "Configuring NEPI ETC FILES"
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
sudo rm /etc/${etc_path} >/dev/null 2>&1
sudo cp ${SOURCE_ETC_PATH}/${etc_path} /etc/${etc_path}  >/dev/null 2>&1

sudo rm /var/crash/* 2>/dev/null

 
echo ""
echo "########"
echo "Configuring nepi_modprobe.conf"
etc_path=modprobe.d/nepi_modprobe.conf
sudo rm /etc/${etc_path} >/dev/null 2>&1
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
    sudo rm -r /opt/baumer >/dev/null 2>&1
fi
sudo cp -r ${SOURCE_ETC_PATH}/opt/baumer /opt/baumer
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/baumer

# Set up the shared object links in case they weren't copied properly when this repo was moved to target
NEPI_BAUMER_PATH=/opt/baumer/gentl_producers
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14.1 $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14 $NEPI_BAUMER_PATH/libbgapi2_usb.cti
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14.1 $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14 $NEPI_BAUMER_PATH/libbgapi2_gige.cti



#################################
# Update Managed Service Settings

####################################
# Run NEPI System Config Load if exists
NEPI_SYS_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
sudo chown $CONFIG_USER:$CONFIG_USER $NEPI_SYS_CONFIG_FILE

NEPI_SYS_CONFIG_LOAD=/mnt/nepi_config/system_cfg/etc/load_system_config.sh
if ! source_script $NEPI_SYS_CONFIG_LOAD; then
    script_error=$?
    echo "Script ${NEPI_SYS_CONFIG_LOAD} failed with error ${script_error}"
fi

if [[ "$NEPI_INSTALL" == "LITE" || "$LITE_INSTALL" -eq 1 ]]; then
    NEPI_INSTALL=LITE
    SERVICES_MANAGED=0
else
    NEPI_INSTALL=FULL
    SERVICES_MANAGED=1
fi


echo "Running setup in ${NEPI_INSTALL} mode"

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




echo ""
echo "########################"
echo "Updating NEPI Managed Services"
echo "########################"

################################
# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then



    if [[ "$NEPI_MANAGES_SHARE" -eq 1 ]]; then

        echo ""
        echo "########"
        echo "Configuring Samba Service"


        echo "Updating Samba ETC config file"
        if [[ "$CONFIG_USER" == "nepi" ]]; then
            source_file=${SOURCE_ETC_PATH}/samba/smb.conf
        else
            source_file=${SOURCE_ETC_PATH}/docker/samba/smb.conf
        fi

        dest_file=/etc/samba/smb.conf
        if [[ -f "$source_file" ]]; then
            sudo cp -d $source_file $dest_file
        fi


        SYSTEMD_SERVICE_PATH=/etc/systemd/system


        echo "Restarting Samba Service"

        sudo systemctl enable smbd
        sudo systemctl restart smbd
        

        echo "Updating Samba Users"
        if [[ ${NEPI_USER_PW} != 'encrypted' ]]; then
            echo -e "$NEPI_USER_PW\n$NEPI_USER_PW" | sudo smbpasswd -a -s "$NEPI_USER" > /dev/null
        # else
        #     sudo smbpasswd -a "$NEPI_USER"
        fi
        sudo usermod -a -G $NEPI_HOST_USER $NEPI_USER > /dev/null


        if [[ ${NEPI_HOST_PW} != 'encrypted' ]]; then
            echo -e "$NEPI_HOST_PW\n$NEPI_HOST_PW" | sudo smbpasswd -a -s "$NEPI_HOST_USER" > /dev/null
        # else
        #     sudo smbpasswd -a "$NEPI_HOST_USER"
        fi
        sudo usermod -a -G $NEPI_USER $NEPI_HOST_USER > /dev/null


        if [[ ${NEPI_ADMIN_PW} != 'encrypted' ]]; then
            echo -e "$NEPI_ADMIN_PW\n$NEPI_ADMIN_PW" | sudo smbpasswd -a -s "$NEPI_ADMIN_USER" > /dev/null
        # else
        #     sudo smbpasswd -a "$NEPI_ADMIN_USER"
        fi        
        sudo usermod -a -G $NEPI_HOST_USER $NEPI_ADMIN_USER > /dev/null

        sudo systemctl restart sshd
    fi


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
        wait
        sleep 2

        # echo "Updating Wired Static IP Addresses"
        # source /opt/nepi/etc/scripts/update_etc_wired_static.sh

        # echo "Updating Wired Alias IP Addresses"
        # source /opt/nepi/etc/scripts/update_etc_wired_aliases.sh

        echo "Restarting networking service"
        sudo systemctl restart networking

    fi

    if [[ "$NEPI_MANAGES_SSH" -eq 1 ]]; then
        echo ""
        echo "########"
        echo "Updating SSH Service Config"
        echo ""


        
        if [[ "$CONFIG_USER" != "nepi" ]]; then
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
        sudo systemctl start sshd

    fi


    if [[ "$CONFIG_USER" != "nepi" ]]; then

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

        
        if is_valid_cuda; then
            sudo nvidia-ctk runtime configure --runtime=docker
        fi

    fi

    if [[   "$NEPI_MANAGES_DOCKER" -eq 1 && "$CONFIG_USER" != "nepi" ]]; then
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
    
    fi

    if [[ "$CONFIG_USER" != "nepi" ]]; then

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
    echo "Updating SSH Service Config"
    echo ""
    source_file=${SOURCE_ETC_PATH}/ssh/sshd_config
    dest_file=/etc/ssh/sshd_config
    echo "Copying ${source_file} to ${dest_file}"
    sudo cp $source_file $dest_file


    ###################
    echo ""
    echo "########"
    echo "Setting up Supervisor"
    echo ""

    sudo chmod +x ${SOURCE_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf
    sudo cp -a ${SOURCE_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf /etc/supervisor/conf.d/supervisord_nepi.conf
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
echo "Updating NEPI SyStem Config"
echo "########################"
echo ""
sudo chown -R $CONFIG_USER:$CONFIG_USER /mnt/nepi_config/docker_cfg/
sudo chown -R $CONFIG_USER:$CONFIG_USER /mnt/nepi_config/system_cfg/

config_update_file=/mnt/nepi_config/system_cfg/etc/nepi_system_config.sh
SHOW_CONFIG_MENU=0
echo "Running System Config Update Script: ${config_update_file}"
bash $config_update_file $SHOW_CONFIG_MENU


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
    if [[ "$CONFIG_USER" != "nepi" ]]; then
        #############################
        echo ""
        echo "############"
        echo "Setting Up NEPI Docker Service"
        echo ""
        
        sudo cp -a ${SOURCE_ETC_PATH}/docker/services/nepi_docker.service ${SYSTEMD_SERVICE_PATH}/nepi_docker.service

        # sudo systemctl enable nepi_docker
        # sudo systemctl restart nepi_docker
    else

        echo ""
        echo "############"
        echo "Setting Up NEPI Engine Service"

        echo "Cofiguring NEPI Engine Service from ${SOURCE_ETC_PATH}/services"
        sudo chmod +x ${SOURCE_ETC_PATH}/services/*
        sudo cp -a ${SOURCE_ETC_PATH}/services/* ${SYSTEMD_SERVICE_PATH}/
        sudo systemctl enable nepi_engine

        echo ""
        echo "############"
        echo "Setting Up NEPI License Service"


        # Set up nepi_check_license (license management, etc.)
        chmod +x /opt/nepi/etc/license/nepi_check_license.py
        gpg --import /opt/nepi/etc/license/nepi_license_management_public_key.gpg

        sudo chown -R $(whoami) ~/.gnupg/
        sudo chmod 700 ~/.gnupg
        find ~/.gnupg -type d -exec sudo chmod 700 {} \;
        find ~/.gnupg -type f -exec sudo chmod 600 {} \;

        # Update ETC files if systemd is running (Not in Container)
        cp /opt/nepi/etc/services/nepi_check_license.service /etc/systemd/system/
        sudo systemctl enable nepi_check_license

        echo "***** nepi_check_license license manager is installed... you must still provide a valid license file in /mnt/nepi_storage/license *****"

        




    fi






elif [[ "$CONFIG_USER" == 'nepi' ]]; then

        echo ""
        echo "############"
        echo "Setting Up NEPI License Service"


        # Set up nepi_check_license (license management, etc.)
        chmod +x /opt/nepi/etc/license/nepi_check_license.py
        gpg --import /opt/nepi/etc/license/nepi_license_management_public_key.gpg

        sudo chown -R $(whoami) ~/.gnupg/
        sudo chmod 700 ~/.gnupg
        find ~/.gnupg -type d -exec sudo chmod 700 {} \;
        find ~/.gnupg -type f -exec sudo chmod 600 {} \;


fi


# #####################################
# SYNC FROM SYSTEM CONFIG
# #####################################
echo ""
echo "########################"
echo "Syncing Config Files and Folders"
echo "########################"
echo ""


echo ""
config_update_file=/mnt/nepi_config/system_cfg/etc/scripts/nepi_system_sync.sh
echo "Running System Config Sync Script: ${config_update_file}"
source $config_update_file





# #####################################
# UPDATE USER DESKTOP FILES
# #####################################

systemctl&> /dev/null
if [[ "$?" -eq 0  ]]; then

    if [[ $LITE_INSTALL -eq 0 ]]; then
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
                sudo rm ${dfolder}/* >/dev/null 2>&1
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


        echo "########"
        echo "Updating Chrome settings for user ${CONFIG_USER}"
        echo "Killing any running Chromium processes"
        sudo pkill -f chromium
        echo "Setting Chromium as Defualt Browser"
        xdg-settings set default-web-browser chromium-browser.desktop


        if [[ ! -d "/home/${CONFIG_USER}/snap/chromium/common/chromium/Default" ]]; then
            echo "Creating Chromium Defualt Folder"
            sudo mkdir -p /home/${CONFIG_USER}/snap/chromium/common/chromium/Default
        fi
        echo "Updating Chromium Defualt Files"
        sudo cp -rf ${SOURCE_ETC_PATH/}/user/snap/chromium/common/chromium/Default/*  /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/
        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER} /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/*

        echo "Cleaning Chromium Files"
        fix_chromium


    fi

    if [[ $LITE_INSTALL -eq 1 ]]; then

        echo "Configuring default code editor"
        CURRENT_DEFAULT=$(xdg-mime query default text/x-python 2>/dev/null)
        if [[ "$CURRENT_DEFAULT" == *"code"* ]]; then
            echo "VS Code is already the default code editor"
        else
            read -p "VS Code is not set as the default code editor. Set it now? [y/N] " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                sudo cp -rf ${SOURCE_ETC_PATH}/user/mimeapps.list /home/${CONFIG_USER}/.config/mimeapps.list
                echo "VS Code set as default code editor"
            else
                echo "Skipping VS Code default setup"
            fi
        fi

        echo "Adding config and storage folders to files sidebar"
        sudo cp -rf ${SOURCE_ETC_PATH}/user/config/gtk-3.0/bookmarks  /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks


        CURRENT_FAVS=$(sudo -u ${CONFIG_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${CONFIG_USER})/bus" gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "[]")
        if [[ "$CURRENT_FAVS" != *"chromium"* ]]; then
            echo "Adding Chromium to favourites"
            NEW_FAVS=$(echo "$CURRENT_FAVS" | sed "s/\]$/, 'chromium_chromium.desktop']/")
            gsettings set org.gnome.shell favorite-apps "$NEW_FAVS"
        else
            echo "Chromium already in favourites"
        fi

        echo "Locating Chromium profile"
        if [[ -d "/home/${CONFIG_USER}/snap/chromium/common/chromium/Default" ]]; then
            CHROMIUM_PROFILE="/home/${CONFIG_USER}/snap/chromium/common/chromium/Default"
        elif [[ -d "/home/${CONFIG_USER}/.config/chromium/Default" ]]; then
            CHROMIUM_PROFILE="/home/${CONFIG_USER}/.config/chromium/Default"
        else
            echo "Chromium profile directory not found"
            CHROMIUM_PROFILE=""
        fi

        if [[ -n "$CHROMIUM_PROFILE" ]]; then
            echo "Setting Chromium Bookmarks and enabling Home button"
            sudo mkdir -p "$CHROMIUM_PROFILE"

            # Copy only the Bookmarks file
            sudo cp -f "${SOURCE_ETC_PATH}/user/snap/chromium/common/chromium/Default/Bookmarks" \
                "$CHROMIUM_PROFILE/Bookmarks"
            sudo chown ${CONFIG_USER}:${CONFIG_USER} "$CHROMIUM_PROFILE/Bookmarks"

            # Enable the Home button in Preferences without overwriting the whole file
            PREFS_FILE="$CHROMIUM_PROFILE/Preferences"
            sudo python3 - "$PREFS_FILE" <<'PYEOF'
import json, sys, os
path = sys.argv[1]
data = {}
if os.path.isfile(path):
    with open(path, 'r') as f:
        try:
            data = json.load(f)
        except Exception:
            data = {}
data.setdefault('browser', {})['show_home_button'] = True
data['bookmark_bar'] = data.get('bookmark_bar', {})
data['bookmark_bar']['show_on_all_tabs'] = True
with open(path, 'w') as f:
    json.dump(data, f, indent=3)
PYEOF
            sudo chown ${CONFIG_USER}:${CONFIG_USER} "$CHROMIUM_PROFILE/Preferences"

            echo "Cleaning Chromium Files"
            fix_chromium
        fi

    fi

    #sudo rm -rf ~/.config/chromium/Singleton* 


    
fi


echo ""
echo "########################"
echo "Cleaning Config System"
echo ""


sudo rm -r  /home/${CONFIG_USER}/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r  /home/${CONFIG_USER}/.local/share/Trash/files/ 2>/dev/null
#sudo rm -r /tmp/* 2>/dev/null
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

