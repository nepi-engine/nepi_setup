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

sudo -v

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


# Load System Config File
#echo "Loading NEPI SYSTEM CONFIG"
#echo "Loading NEPI SYSTEM CONFIG"
NEPI_SETUP_CONFIG_SCRIPT=${RESOURCES_FOLDER}/etc/load_system_config.sh
NEPI_USER_CONFIG_SCRIPT=/home/${CONFIG_USER}/load_system_config.sh
if [[ ! -f $NEPI_USER_CONFIG_SCRIPT ]]; then
    cp $NEPI_SETUP_CONFIG_SCRIPT $NEPI_USER_CONFIG_SCRIPT
fi

NEPI_SETUP_CONFIG_PYTHON=${RESOURCES_FOLDER}/etc/load_system_config.py
NEPI_USER_CONFIG_PYTHON=/home/${CONFIG_USER}/load_system_config.py
if [[ ! -f $NEPI_USER_CONFIG_PYTHON ]]; then
    cp $NEPI_SETUP_CONFIG_PYTHON $NEPI_USER_CONFIG_PYTHON
fi

NEPI_SETUP_CONFIG_FILE=${RESOURCES_FOLDER}/etc/nepi_system_config.yaml
NEPI_USER_CONFIG_FILE=/home/${CONFIG_USER}/nepi_system_config.yaml
if [[ ! -f $NEPI_USER_CONFIG_FILE ]]; then
    cp $NEPI_SETUP_CONFIG_FILE $NEPI_USER_CONFIG_FILE
fi

if [[ -f $NEPI_USER_CONFIG_SCRIPT ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_USER_CONFIG_SCRIPT}"
    source ${NEPI_USER_CONFIG_SCRIPT}
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_USER_CONFIG_SCRIPT}"
    fi
fi

NEPI_IP_START=${NEPI_STATIC_IP%%/*}
echo "Got Starting NEPI IP: ${NEPI_IP_START}"

if [[ -n $NEPI_STATIC_IP ]]; then
    export NEPI_DEVICE_ID=device1
    export NEPI_IP=${NEPI_STATIC_IP%%/*}
    export NEPI_HOST_USER=nepihost
    export NEPI_IN_CONTAINER=1
else
    export NEPI_DEVICE_ID=device1
    export NEPI_IP=192.168.179.103
    export NEPI_HOST_USER=nepihost
    export NEPI_IN_CONTAINER=1
fi



# This file sets up nepi bash aliases and util functions
echo "########################"
echo "NEPI DEV PC SETUP"
echo "########################"


    echo " "
    echo "################################# "
    echo "Updating SSH Keys"
    echo ""


    NEPI_SSH_KEY_SOURCE=${RESOURCES_FOLDER}/etc/ssh/ssh_keys
    NEPI_SSH_KEY_DEST=/home/${CONFIG_USER}/.ssh
    if [ ! -d $NEPI_SSH_KEY_SOURCE ]; then
        echo "FAILED TO FIND NEPI SOURCE KEYS FOLDER at: ${NEPI_SSH_KEY_SOURCE} "
    else
        echo "Installing NEPI SSH Private Keys from: ${NEPI_SSH_KEY_SOURCE} "
        if [[ ! -d "$NEPI_SSH_KEY_DEST" ]]; then
            mkdir -p $NEPI_SSH_KEY_DEST
        fi
        sudo chmod 0700 $NEPI_SSH_KEY_DEST
        sudo cp -p $NEPI_SSH_KEY_SOURCE/* ${NEPI_SSH_KEY_DEST}/
        sudo chmod 0600 $NEPI_SSH_KEY_DEST/*
        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_SSH_KEY_DEST/*
    fi

    if [[ -n $NEPI_SSH_KEY_FILE ]]; then
        NEPI_SSH_KEY_FILE=$NEPI_SSH_KEY_FILE
    else
        NEPI_SSH_KEY_FILE=nepi_default_ssh_key
    fi    
    NEPI_SSH_KEY_PATH=/home/${CONFIG_USER}/.ssh/${NEPI_SSH_KEY_FILE}


if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then


    NEPI_USER_CONFIGS=(
    NEPI_DEVICE_ID \
    NEPI_IP \
    NEPI_IN_CONAINTER \
    NEPI_HOST_USER \
    NEPI_SSH_KEY_FILE \
    )

    function print_current_config(){
        echo ""
        echo "Current Settings"
        echo "---------------------"
        echo "NEPI_IP: ${NEPI_IP}"
        echo "NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
        echo "NEPI_HOST_USER: ${NEPI_HOST_USER}"
        echo "NEPI_SSH_KEY_FILE: ${NEPI_SSH_KEY_FILE}"
        echo ""
    }

    function udpate_config_file(){
        config_file=$1
        update_yaml_value "NEPI_STATIC_IP" "${NEPI_IP}/24" $config_file
        export NEPI_STATIC_IP="${NEPI_IP}/24"
        update_yaml_value "NEPI_DEVICE_ID" $NEPI_DEVICE_ID $config_file
        export NEPI_DEVICE_ID=$NEPI_DEVICE_ID
        update_yaml_value "NEPI_HOST_USER" $NEPI_HOST_USER $config_file
        export NEPI_HOST_USER=$NEPI_HOST_USER
        update_yaml_value "NEPI_SSH_KEY" $NEPI_SSH_KEY $config_file
        export NEPI_SSH_KEY=$NEPI_SSH_KEY
    }


    #####################################
    # Update NEPI System Config if needed

    echo ""
    PS3=$'\n'"Please enter your choice by NUMBER: "
    options=(  "Update Static IP Address" "Update Device ID Name" "Update NEPI Host User" "Update NEPI SSH KEY FILE" "CONTINUE" )

    while true; do
        #clear # Optional: Clear the screen before displaying the menu

        print_current_config
        COLUMNS=1
        select opt in "${options[@]}" ; do
            case $opt in

                "Update Static IP Address")
                    read -p $'\n'"Enter a new Static IP Address (Current = ${NEPI_IP}): " USER_INPUT
                    echo ""
                    if is_valid_ipv4 "$USER_INPUT"; then
                        export NEPI_IP=$USER_INPUT
                        echo ""
                        break # Exit the select statement, re-display menu
                    else
                        echo "Not A Valid Password"
                    fi           
                    ;;
                "Update Device ID Name")
                    read -p $'\n'"Enter a new Device Name (Current = ${NEPI_DEVICE_ID}): " USER_INPUT
                    echo ""
                    if is_valid_did "$USER_INPUT"; then
                        export NEPI_DEVICE_ID=$USER_INPUT
                        echo ""
                        break # Exit the select statement, re-display menu
                    else
                        echo "Not A Valid Password"
                    fi          
                ;;
                "Update NEPI Host User")
                    read -p $'\n'"Enter the NEPI Host User Name (Current = ${NEPI_HOST_USER}): " USER_INPUT
                    echo ""
                    if is_valid_uid "$USER_INPUT"; then
                        export NEPI_HOST_USER=$NEPI_HOST_USER
                        echo ""
                        break # Exit the select statement, re-display menu
                    else
                        echo "Not A Valid User Name"
                    fi          
                ;;
                "Update NEPI Host User")
                    nepisshkey
                ;;


                "CONTINUE")
                    break 2 # Exit both the select and the while loop
                    ;;
                *)
                    echo "Invalid option, please try again."
                    ;;
            esac
        done
    done
    echo ""



    echo "Running script with settings:"
    echo "----------------------------"
    print_current_config
    echo ""

    USER_CONFIG_FILE=/home/${CONFIG_USER}/nepi_system_config.yaml
    echo "Updating NEPI CONFIG File: ${USER_CONFIG_FILE} "
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        udpate_config_file $USER_CONFIG_FILE
    fi





    #####################################
    echo " "
    echo "################################# "
    echo "Updating Bash Files"
    echo ""


    ##############
    echo "Setting up NEPI Bash Utils file"


    NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_utils
    NEPI_UTILS_DEST=/home/${CONFIG_USER}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_SOURCE
    sudo chmod 775 $NEPI_UTILS_SOURCE
    sudo cp -R -p $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST/

    NEPI_UTILS_FILE_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
    NEPI_UTILS_FILE_DEST=/home/${CONFIG_USER}/.nepi_bash_utils

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_FILE_SOURCE
    sudo chmod 775 $NEPI_UTILS_FILE_SOURCE
    sudo cp -p $NEPI_UTILS_FILE_SOURCE $NEPI_UTILS_FILE_DEST

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IP=" "export NEPI_IP=${NEPI_IP}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_DEVICE_ID=" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_HOST_USER=" "export NEPI_HOST_USER=${NEPI_HOST_USER}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_SSH_KEY_FILE=" "export NEPI_SSH_KEY_FILE=${NEPI_SSH_KEY_FILE}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IN_CONTAINER=" "export NEPI_IN_CONTAINER=${NEPI_IN_CONTAINER}"



    ##############
    echo "Installing NEPI PC Aliases file"

    NEPI_ALIASES_SOURCE=${RESOURCES_FOLDER}/bash/nepi_pc_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_pc_aliases
    echo "Installing NEPI aliases file from ${NEPI_ALIASES_SOURCE} to ${NEPI_ALIASES_DEST} "

    if [ -f "$NEPI_ALIASES_DEST" ]; then
        sudo rm $NEPI_ALIASES_DEST
    fi
    sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST
    sudo chmod 775 $NEPI_ALIASES_DEST




    ##############
    echo "Updating ${CONFIG_USER} user .bashrc file"

    BASHRC=/home/${CONFIG_USER}/.bashrc
    file=$BASHRC
    bfile=${BASHRC}.bak

    if [[ ! -f "$file"  ]]; then
        cp /etc/skel/.bashrc $file
    fi

    if [[ ! -f $bfile ]]; then
        path_backup $file $bfile
    fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $file
    sudo chmod 775 $file


    # Add NEPI Aliases
    if grep -qnw $file -e "##### Source NEPI Aliases #####" ; then
        if grep -qnw $file -e "NEPI_ALIASES_FILE=" ; then
            update_text_value $file "NEPI_ALIASES_FILE=" "NEPI_ALIASES_FILE=${NEPI_ALIASES_DEST}"
        fi
    else
        echo ' ' | sudo tee -a $file
        echo '##### Source NEPI Aliases #####' | sudo tee -a $file
        echo 'NEPI_ALIASES_FILE='${NEPI_ALIASES_DEST} | sudo tee -a $file
        echo 'if [ -f ${NEPI_ALIASES_FILE} ]; then' | sudo tee -a $file
        echo '    . ${NEPI_ALIASES_FILE}' | sudo tee -a $file
        echo 'fi' | sudo tee -a $file
    fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ~/.bashrc
    sudo chmod 0644 ~/.bashrc

    echo ""
    echo "Sourcing updated bash files"
    source /home/${CONFIG_USER}/.bashrc
    wait


    ####################################################
    echo " "
    echo "################################# "
    echo "Setting up SSH Key ${NEPI_SSH_KEY_FILE}"
    echo ""

    nepisetkey $NEPI_SSH_KEY_FILE
    ssh-add -l


    echo " "
    echo "################################# "
    echo "Updating ETC Hosts File"
    echo ""


    file=/etc/hosts
    tfile=${file}.tmp
                    
    if [[ -f $tfile ]]; then
        sudo rm $tfile
    fi

    sudo cp $file $tfile 


    if [[ -n ${NEPI_STATIC_IP} ]]; then
        nepi_ip="${NEPI_STATIC_IP%%/*}"
    else
        nepi_ip=192.168.170.103
    fi
    if ! is_valid_ipv4 "${nepi_ip}"; then
        nepi_ip=192.168.170.103
    fi

    echo "Updating NEPI IP in ${tfile}"
    sudo sed -i "/${nepi_ip}/d" "$tfile"
    sudo sed -i "/${NEPI_DEVICE_ID}/d" "$tfile"
    sudo sed -i "/nepi/d" "$tfile"
    sudo sed -i "/nepiadmin/d" "$tfile"
    sudo sed -i "/nepihost/d" "$tfile"


    echo "${nepi_ip} ${NEPI_DEVICE_ID}" | sudo tee -a $tfile
    echo "${nepi_ip} nepi" | sudo tee -a $tfile
    echo "${nepi_ip} nepi-${NEPI_DEVICE_ID}" | sudo tee -a $tfile
    echo "${nepi_ip} nepihost" | sudo tee -a $tfile
    echo "${nepi_ip} nepihost-${NEPI_DEVICE_ID}" | sudo tee -a $tfile
    echo "${nepi_ip} nepiadmin" | sudo tee -a $tfile
    echo "${nepi_ip} nepiadmin-${NEPI_DEVICE_ID}" | sudo tee -a $tfile
    echo "${nepi_ip} nepiuser" | sudo tee -a $tfile
    echo "${nepi_ip} nepiuser-${NEPI_DEVICE_ID}" | sudo tee -a $tfile

    sudo cp $tfile $file >/dev/null 2>&1

    if [[ -f $tfile ]]; then
        sudo rm $tfile >/dev/null 2>&1
    fi

    cat /etc/hosts    

    echo " "
    echo "################################# "
    echo "Clearing Known Hosts"
    echo ""

    sudo rm -r /home/${CONFIG_USER}/.ssh/known_hosts* >/dev/null 2>&1sb
    # ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepi" >/dev/null 2>&1
    # ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepihost" >/dev/null 2>&1



    #####################################
    echo " "
    echo "################################# "
    echo "Configuring NTP Server"
    echo ""

    if dpkg -l | grep ntp >/dev/null 2>&1; then
        echo "NTP application installed"
    else
        
        if ! dpkg -l | grep chrony >/dev/null 2>&1; then
            echo "Installing NTP application"
            sudo apt-get install chrony
        fi
        echo "Installing NTP application"
        sudo apt-get install ntp
    fi
    sudo service ntp start
    ntpq -p


    # echo " "
    # echo "################################# "
    # echo "Configuring NEPI Shared Drive Folders"
    # echo ""
    # shdrive=/mnt/nepi_share_storage
    # if [[ ! -e $shdrive ]]; then
        
    #     sudo mkdir $shdrive
    # fi
    # sudo chown ${CONFIG_USER}:${CONFIG_USER} $shdrive

    # shdrive=/mnt/nepi_share_config
    # if [[ ! -e $shdrive ]]; then
    #     sudo mkdir $shdrive
    # fi
    # sudo chown ${CONFIG_USER}:${CONFIG_USER} $shdrive

if [[ -n "$DISPLAY" ]]; then
    #####################################
    echo "########################"
    echo "Installing Desktop Utility Apps"
    echo ""

    # sudo apt update

    #######
    echo ""
    if command -v mdview &>/dev/null; then
        echo "mdview is installed."
    else
        echo "Installing mdview"
        sudo snap install mdview
    fi

    if command -v chromium-browser &>/dev/null; then
        echo "Chromium is installed."
    else
        # Check for an alternative common name if the first one fails
        if command -v chromium &>/dev/null; then
            echo "Chromium is installed."
        else
            echo "Installing Chromium Browser"
            #sudo snap remove --purge chromium
            sudo snap install chromium
            #sudo apt install chromium-browser -y
            #chromium-browser --disable-features=DnsOverHttps
        fi
    fi

    if command -v code &> /dev/null; then
        echo "Visual Studio Code is installed and accessible."
    else
        echo ""
        echo "Installing visual code editor"
        
        if [[ "$NEPI_ARCH" == 'arm64' ]]; then
            curl -L https://aka.ms/linux-arm64-deb > code_arm64.deb
            sudo apt install ./code_arm64.deb
            wait
            sudo rm code_arm64.deb
        elif [[ "$NEPI_ARCH" == 'amd64' ]]; then
            sudo snap install code --channel=edge --classic
        fi
    fi


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
            rui_ip=$NEPI_IP
            find . -type f -exec perl -i -pe 's||${rui_ip}|g' {} +

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

            # echo "Cleaning Chromium Files"
            # fix_chromium
        fi


fi
    if command -v mount.cifs &>/dev/null; then
        echo "cifs-utils is installed."
    else
        echo "Installing cifs-utils"
        sudo apt install cifs-utils
    fi



    #####################################
    echo " "
    echo "################################# "
    echo "NEPI DEV PC SETUP COMPLETE"
    echo "################################# "

    NEPI_IP_END=$NEPI_IP
    network_id="$(echo "$NEPI_IP_END" | cut -d'.' -f1-3)"
    nepi_id=$(echo "$NEPI_IP_END" | cut -d '.' -f 4-)
    rec_ip=${network_id}.5

    if [[ ${NEPI_IP_END} != ${NEPI_IP_START} ]]; then

            slist=$(netliststatic)
            if [[ "$slist" != *"$network_id"*  ]]; then
                echo ""
                echo "Your NEPI IP address has changed from: ${NEPI_IP_START} to: ${NEPI_IP_END}"
                if systemctl is-active --quiet NetworkManager; then
                echo ""
                echo "Do you want to update now?"
                choice=$(ask_yes_no)
                if [[ "$choice" == 'yes' ]]; then
                    echo ""
                    netsetstatic "${rec_ip}/24"
                    echo "###################"
                    echo "Updated Static IPs"
                    netliststatic
                    echo "###################"
                    echo ""
                fi  
                echo ""  

            fi
        fi
    fi

    echo "Your NEPI DEVICE IP address is set to:" 
    echo "${NEPI_IP_END}"

    echo ""
    echo "Your PC's network adapter should be set to:"
    echo "${rec_ip}"

    echo " "
    echo "You can check your NEPI Device connection by typing:"
    echo "ping ${NEPI_IP}   OR   pingn"

    echo " "
    echo "You can ssh into your NEPI Devices nepi Docker host OR nepi Docker contatiner by typing:"
    echo "sshnh  OR   ssh"

    echo " "
    echo "You can connect to your NEPI Device's shared network drives by typing:"
    echo "nepistorage  OR   nepiconfig"

    echo " "
    echo "You can connect to your NEPI Device's RUI in a Chrome browser at:"
    echo "http://${NEPI_IP}:5003/   OR   typing: nepirui"

    echo " "
    echo "To see a list of NEPI command line shortcuts run: nepihelp"
    echo " "

else

    echo "THIS SCRIPT CANNOT BE RUN BY USER nepi OR nepihost"

fi


