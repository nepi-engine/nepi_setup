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

LITE_INSTALL=$1


sudo -v


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $LITE_INSTALL
if [[ "$?" -ne 0 ]]; then
    return 
fi

echo "Running NEPI Setup in ${LITE_INSTALL},${NEPI_INSTALL}"

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
USER_CHECK_FILE=${SCRIPT_FOLDER}/nepi_user_check.sh
source $USER_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE
USER_UTILS_SOURCE=/home/${CONFIG_USER}/.nepi_bash_utils
if [[ -f $USER_UTILS_SOURCE ]]; then
    source $USER_UTILS_SOURCE
fi

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
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
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
if [[ ! -d '/etc/udev/rules.d' ]]; then
    sudo mkdir -p '/etc/udev/rules.d'
fi
sudo cp ${SOURCE_ETC_PATH}/udev/rules.d/* /etc/udev/rules.d/

echo ""
echo "########"
echo "Setting up Baumer GenTL Producers (Genicam support)"

if [ -d "/opt/baumer" ]; then
    sudo rm -r /opt/baumer >/dev/null 2>&1
fi
sudo cp -r ${SOURCE_ETC_PATH}/opt/baumer /opt/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/baumer

# if [ -d "mnt/nepi_config/system_cfg/etc/opt/baumer" ]; then
#     sudo rm -r mnt/nepi_config/system_cfg/etc/opt/baumer >/dev/null 2>&1
# fi


# Set up the shared object links in case they weren't copied properly when this repo was moved to target
NEPI_BAUMER_PATH=/opt/baumer/gentl_producers
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.15.2 $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.15
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.15 $NEPI_BAUMER_PATH/libbgapi2_usb.cti
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.15.2 $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.15
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.15 $NEPI_BAUMER_PATH/libbgapi2_gige.cti



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




echo ""
echo "########################"
echo "Updating NEPI Managed Services"
echo "########################"

################################
# Update ETC files if systemd is running (Not in Container)




if [[ "$LITE_INSTALL" -eq 1 ]]; then
    NEPI_INSTALL=LITE
    SERVICES_MANAGED=0
else
    NEPI_INSTALL=FULL
    SERVICES_MANAGED=1
fi
echo ""
echo "Running setup in ${NEPI_INSTALL} mode"
echo "NEPI MANAGES SERVICES ${SERVICES_MANAGED}"


    echo "Updating NEPI Config File"

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_HOSTNAME ))
    export NEPI_MANAGES_HOSTNAME=$NEPI_MANAGES_HOSTNAME
    update_yaml_value "NEPI_MANAGES_HOSTNAME" $NEPI_MANAGES_HOSTNAME $NEPI_SYS_CONFIG_FILE

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_NETWORK ))
    export NEPI_MANAGES_NETWORK=$NEPI_MANAGES_NETWORK
    update_yaml_value "NEPI_MANAGES_NETWORK" $NEPI_MANAGES_NETWORK $NEPI_SYS_CONFIG_FILE

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_TIME ))
    export NEPI_MANAGES_TIME=$NEPI_MANAGES_TIME
    update_yaml_value "NEPI_MANAGES_TIME" $NEPI_MANAGES_TIME $NEPI_SYS_CONFIG_FILE

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_SSH ))
    export NEPI_MANAGES_SSH=$NEPI_MANAGES_SSH
    update_yaml_value "NEPI_MANAGES_SSH" $NEPI_MANAGES_SSH $NEPI_SYS_CONFIG_FILE

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_SHARE ))
    export NEPI_MANAGES_SHARE=$NEPI_MANAGES_SHARE
    update_yaml_value "NEPI_MANAGES_SHARE" $NEPI_MANAGES_SHARE $NEPI_SYS_CONFIG_FILE

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_SOFTWARE ))
    export NEPI_MANAGES_SOFTWARE=$NEPI_MANAGES_SOFTWARE
    update_yaml_value "NEPI_MANAGES_SOFTWARE" $NEPI_MANAGES_SOFTWARE $NEPI_SYS_CONFIG_FILE

    NEPI_MANAGES_HOSTNAME=$(( SERVICES_MANAGED & NEPI_MANAGES_DOCKER ))
    export NEPI_MANAGES_DOCKER=$NEPI_MANAGES_DOCKER
    update_yaml_value "NEPI_MANAGES_DOCKER" $NEPI_MANAGES_DOCKER $NEPI_SYS_CONFIG_FILE

echo ""
echo "NEPI_MANAGES_HOSTNAME ${NEPI_MANAGES_HOSTNAME}"
echo "NEPI_MANAGES_NETWORK ${NEPI_MANAGES_NETWORK}"
echo "NEPI_MANAGES_TIME ${NEPI_MANAGES_TIME}"
echo "NEPI_MANAGES_SSH ${NEPI_MANAGES_SSH}"
echo "NEPI_MANAGES_SHARE ${NEPI_MANAGES_SHARE}"
echo "NEPI_MANAGES_SOFTWARE ${NEPI_MANAGES_SOFTWARE}"
echo "NEPI_MANAGES_DOCKER ${NEPI_MANAGES_DOCKER}"


systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then


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

        sudo ufw allow 123 >/dev/null 2>&1

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

        if [[ ! -f "/run/sshd" ]]; then
            sudo mkdir "/run/sshd"
        fi
        sudo chmod 0755 /run/sshd
        sudo chown root:root /run/sshd
        if [[ ! -f "/var/run/sshd" ]]; then
            sudo mkdir "/var/run/sshd"
        fi
        sudo chmod 0755 /var/run/sshd
        sudo chown root:root /var/run/sshd

        echo "Enabling ssh service"
        sudo systemctl enable sshd >/dev/null 2>&1        
        sudo systemctl start sshd

        sudo ufw allow 22 >/dev/null 2>&1
        sudo ufw allow 2222 >/dev/null 2>&1

    fi


    if [[ "$CONFIG_USER" != "nepi" ]]; then

        echo ""
        echo "########"
        echo "Updating Docker Service Config"
        echo ""


        echo "Stopping Docker Service"
        sudo systemctl stop docker
        sudo systemctl stop docker.socket       



        if [[ ! -f "/etc/docker/daemon.json.org" && -f "/etc/docker/daemon.json" ]]; then
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
        # echo "Setting Docker File Path to ${NEPI_DOCKER}"
        # echo "Updating docker file /etc/default/docker"
        # FILE=/etc/default/docker
        # UPDATE="DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4  -g ${NEPI_DOCKER}\""
        # echo $UPDATE
        # KEY=DOCKER_OPTS
        # sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"
        # KEY='#DOCKER_OPTS'
        # sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"


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

        sudo ufw allow 445 >/dev/null 2>&1
        sudo systemctl restart sshd

    fi

    #Open other required ports
    sudo ufw allow 137 >/dev/null 2>&1
    sudo ufw allow 138 >/dev/null 2>&1
    sudo ufw allow 139 >/dev/null 2>&1

    # Open ROS Ports
    sudo ufw allow 11311 >/dev/null 2>&1

    # Open RUI Ports
    sudo ufw allow 5003 >/dev/null 2>&1
    sudo ufw allow 9090 >/dev/null 2>&1
    sudo ufw allow 9091 >/dev/null 2>&1
    sudo ufw allow 9092 >/dev/null 2>&1


    # Enable Firewall
    # sudo ufw --force enable
    # echo "Enabled network firewall with ports"
    # echo $(sudo ufw status)




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

    if [[ ! -f "/run/sshd" ]]; then
        sudo mkdir "/run/sshd"
    fi
    sudo chmod 0755 /run/sshd
    sudo chown root:root /run/sshd
    if [[ ! -f "/var/run/sshd" ]]; then
        sudo mkdir "/var/run/sshd"
    fi
    sudo chmod 0755 /var/run/sshd
    sudo chown root:root /var/run/sshd

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
if [[ "$?" -eq 0 && -n $DISPLAY ]]; then

    if [[ $LITE_INSTALL -eq 0 ]]; then
        echo ""
        echo "########################"
        echo "Updating USER Desktop Files"
        echo "########################"
        echo ""
        echo "Running in FULL INSTALL mode"
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


        echo "Locating Chromium profile"
        if [[ -d "/home/${CONFIG_USER}/snap/chromium/common/chromium" ]]; then
            CHROMIUM_PROFILE="/home/${CONFIG_USER}/snap/chromium/common/chromium"
        elif [[ -d "/home/${CONFIG_USER}/.config/chromium" ]]; then
            CHROMIUM_PROFILE="/home/${CONFIG_USER}/.config/chromium"
        else
            echo "Chromium profile directory not found"
            return 1
        fi

        if [[ -n "$CHROMIUM_PROFILE" ]]; then

            if [[ -d ${CHROMIUM_PROFILE} ]]; then
                sudo rm -rf ${CHROMIUM_PROFILE}/Singleton* > /dev/null 2>&1
                sudo rm -rf /home/${CONFIG_USER}/.cache/chromium > /dev/null 2>&1
                echo "Updating Chromiun Settings in ${CHROMIUM_PROFILE}"

                sudo chown ${CONFIG_USER}:${CONFIG_USER} $CHROMIUM_PROFILE
                CHROMIUM_DEFAULT=${CHROMIUM_PROFILE}/Default
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $CHROMIUM_DEFAULT
                # Copy only the Bookmarks file
                BOOKMARK_FILE=${CHROMIUM_DEFAULT}/Bookmarks
                sudo cp -f "${SOURCE_ETC_PATH}/user/chromium/common/chromium/Default/Bookmarks" $BOOKMARK_FILE
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $BOOKMARK_FILE
                nepi_id=$(echo "$NEPI_IP" | cut -d '.' -f 4-)
                rui_ip="127.0.0.${nepi_id}"
                if is_valid_ipv4 $rui_ip; then
                    sed -i "s/localhost/$rui_ip/g" $BOOKMARK_FILE
                fi

                # Enable the Home button in Preferences without overwriting the whole file
                PREFS_FILE="$CHROMIUM_DEFAULT/Preferences"
                update_json_value "$PREFS_FILE" browser.show_home_button true
                update_json_value "$PREFS_FILE" bookmark_bar.show_on_all_tabs true
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $PREFS_FILE
            fi
        fi


    elif [[ $LITE_INSTALL -eq 1 ]]; then

        echo ""
        echo "########################"
        echo "Updating USER Desktop Files"
        echo "########################"
        echo ""
        echo "Running in LITE INSTALL mode"
        ##############################################
        # Update User Files
        echo ""
        echo "########"
        echo "Updating Desktop settings for user ${CONFIG_USER}"
        echo ""
        echo "Configuring default code editor"

        MIMEAPPS="/home/${CONFIG_USER}/.config/mimeapps.list"
        if sudo grep -q "text/x-python=.*code" "${MIMEAPPS}" 2>/dev/null; then
            echo "VS Code is already the default code editor"
        else
            read -p "VS Code is not set as the default code editor. Set it now? [y/N] " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                sudo mkdir -p /home/${CONFIG_USER}/.config
                if ! sudo grep -q "\[Default Applications\]" "${MIMEAPPS}" 2>/dev/null; then
                    echo "[Default Applications]" | sudo tee -a "${MIMEAPPS}" > /dev/null
                fi
                for mime in text/x-python text/plain text/x-shellscript application/x-shellscript text/x-csrc text/x-c++src text/x-yaml text/x-json; do
                    if ! sudo grep -q "^${mime}=" "${MIMEAPPS}" 2>/dev/null; then
                        sudo sed -i "/\[Default Applications\]/a ${mime}=code.desktop" "${MIMEAPPS}"
                    fi
                done
                sudo chown ${CONFIG_USER}:${CONFIG_USER} "${MIMEAPPS}"
                echo "VS Code set as default code editor"
            else
                echo "Skipping VS Code default setup"
            fi
        fi

        echo "Adding config and storage folders to files sidebar"
        sudo mkdir -p /home/${CONFIG_USER}/.config/gtk-3.0
        sudo touch /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks
        while IFS= read -r bm; do
            sudo grep -qxF "$bm" /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks || echo "$bm" | sudo tee -a /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks > /dev/null
        done < ${SOURCE_ETC_PATH}/user/config/gtk-3.0/bookmarks


        CURRENT_FAVS=$(sudo -u ${CONFIG_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${CONFIG_USER})/bus" gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "[]")
        if [[ "$CURRENT_FAVS" != *"chromium"* ]]; then
            echo "Adding Chromium to favourites"
            NEW_FAVS=$(echo "$CURRENT_FAVS" | sed "s/\]$/, 'chromium_chromium.desktop']/")
            gsettings set org.gnome.shell favorite-apps "$NEW_FAVS"
        else
            echo "Chromium already in favourites"
        fi


        echo "Locating Chromium profile"
        if [[ -d "/home/${CONFIG_USER}/snap/chromium/common/chromium" ]]; then
            CHROMIUM_PROFILE="/home/${CONFIG_USER}/snap/chromium/common/chromium"
        elif [[ -d "/home/${CONFIG_USER}/.config/chromium" ]]; then
            CHROMIUM_PROFILE="/home/${CONFIG_USER}/.config/chromium"
        else
            echo "Chromium profile directory not found"
            return 1
        fi

        if [[ -n "$CHROMIUM_PROFILE" ]]; then

            if [[ -d ${CHROMIUM_PROFILE} ]]; then
                sudo rm -rf ${CHROMIUM_PROFILE}/Singleton* > /dev/null 2>&1
                sudo rm -rf /home/${CONFIG_USER}/.cache/chromium > /dev/null 2>&1
                echo "Updating Chromiun Settings in ${CHROMIUM_PROFILE}"

                sudo chown ${CONFIG_USER}:${CONFIG_USER} $CHROMIUM_PROFILE
                CHROMIUM_DEFAULT=${CHROMIUM_PROFILE}/Default
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $CHROMIUM_DEFAULT
                # Copy only the Bookmarks file
                BOOKMARK_FILE=${CHROMIUM_DEFAULT}/Bookmarks
                sudo cp -f "${SOURCE_ETC_PATH}/user/chromium/common/chromium/Default/Bookmarks" $BOOKMARK_FILE
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $BOOKMARK_FILE
                nepi_id=$(echo "$NEPI_IP" | cut -d '.' -f 4-)
                rui_ip="127.0.0.${nepi_id}"
                if is_valid_ipv4 $rui_ip; then
                    sed -i "s/localhost/$rui_ip/g" $BOOKMARK_FILE
                fi

                # Enable the Home button in Preferences without overwriting the whole file
                PREFS_FILE="$CHROMIUM_DEFAULT/Preferences"
                update_json_value "$PREFS_FILE" browser.show_home_button true
                update_json_value "$PREFS_FILE" bookmark_bar.show_on_all_tabs true
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $PREFS_FILE
            fi
        fi

    fi

fi


echo ""
echo "########################"
echo "Cleaning Config System"
echo ""

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

