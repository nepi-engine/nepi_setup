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

skip_software=$1
if [[ $skip_software -eq 1 ]]; then
    SKIP_SOFTWARE=1
else
    SKIP_SOFTWARE=0
fi

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
else
    source $NEPI_UTILS_SOURCE
    sudo cp $NEPI_UTILS_SOURCE $USER_UTILS_SOURCE
    sudo chmod +x $USER_UTILS_SOURCE
    suod chmod ${CONFIG_USER}:${CONFIG_USER} $USER_UTILS_SOURCE
fi


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
        exit
    fi
fi

NEPI_IP_START=${NEPI_IP%%/*}
echo "Got Starting NEPI IP: ${NEPI_IP_START}"

##########################
NEPI_ARCH=unknown
if is_valid_jetson; then
    NEPI_ARCH=arm64
elif is_valid_rpi; then
    NEPI_ARCH=arm64
elif is_valid_arm64; then
    NEPI_ARCH=arm64
elif is_valid_amd64; then
    NEPI_ARCH=amd64
else
    arch_val=$(uname -m)
    echo "Arch ${arch_val} not supported yet"
    return 
fi

# This file sets up nepi bash aliases and util functions
echo "########################"
echo "NEPI REMOTE DEV SETUP"
echo "########################"

if [[ $SKIP_SOFTWARE -eq 0 ]]; then
    echo " "
    echo "################################# "
    echo "Installing System Required Software"
    echo ""

    sudo apt remove yq -y  2>/dev/null 

    VERSION=v4.16.2
    if [[ "$NEPI_ARCH" == 'arm64' ]]; then
        PLATFORM=linux_arm64
    fi
    if [[ "$NEPI_ARCH" == 'amd64' ]]; then
        PLATFORM=linux_amd64
    fi
    wget https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_${PLATFORM}.tar.gz -O - |\
        tar xz && sudo mv yq_${PLATFORM} /usr/bin/yq

    
    
    sudo apt update

    sudo apt install jq -y
    sudo apt install ncdu -y

    if command -v mount.cifs --help &>/dev/null; then
        echo "cifs-utils is installed."
    else
        echo "Installing cifs-utils"
        sudo apt install cifs-utils
    fi

    echo " "
    echo "################################# "
    echo "Installing Required Python Software"
    echo ""

    python3 -m pip install PyYAML
fi

echo "Starting NEPI Configuration for user ${CONFIG_USER}"
    
    echo ''

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
        echo "NEPI_DEVICE_IP: ${NEPI_IP%%/*}"
        echo "NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
        echo "NEPI_HOST_USER: ${NEPI_HOST_USER}"
        echo "NEPI_SSH_KEY_FILE: ${NEPI_SSH_KEY}"
        echo ""
    }

    function udpate_config_file(){
        config_file=$1
        update_text_value $config_file "export NEPI_IP=" "export NEPI_IP=${NEPI_IP}"
        export NEPI_IP="${NEPI_IP}"
        update_text_value $config_file "export NEPI_DEVICE_ID=" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"
        export NEPI_DEVICE_ID=$NEPI_DEVICE_ID
        update_text_value $config_file "export NEPI_HOST_USER=" "export NEPI_HOST_USER=${NEPI_HOST_USER}"
        export NEPI_HOST_USER=$NEPI_HOST_USER
        # update_text_value $config_file "export NEPI_SSH_KEY_FILE=" "export NEPI_SSH_KEY_FILE=${NEPI_SSH_KEY}"
        # export NEPI_SSH_KEY_FILE=$NEPI_SSH_KEY

    }
    
    echo "Bringin Up NEPI Configuration Menu"

    #####################################
    # Update NEPI System Config if needed

    echo ""
    PS3=$'\n'"Please enter your choice by NUMBER: "
    options=(  "Update Static IP Address" "Update Device ID Name" "Update NEPI Host User" "Sync With Remote NEPI Device" "CONTINUE" )

    while true; do
        #clear # Optional: Clear the screen before displaying the menu

        print_current_config
        COLUMNS=1
        select opt in "${options[@]}" ; do
            case $opt in

                "Update Static IP Address")
                    read -p $'\n'"Enter a new Static IP Address (Current = ${NEPI_IP%%/*}): " USER_INPUT
                    echo ""
                    if is_valid_ipv4 "$USER_INPUT"; then
                        export NEPI_STATIC_IP=${USER_INPUT}/24
                        export NEPI_IP=$USER_INPUT
                        echo ""
                        break # Exit the select statement, re-display menu
                    else
                        echo "Not A Valid IP Address"
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
                        echo "Not A Valid Device ID"
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
                "Sync With Remote NEPI Device")
                    echo ""
                    echo "Syncing NEPI Configs"
                    nepisync
                    echo ""
                    echo "Syncing NEPI Configs"
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


    echo "Updating NEPI CONFIG File: ${USER_UTILS_SOURCE} "
    if [[ -f "$USER_UTILS_SOURCE" ]]; then
        udpate_config_file $USER_UTILS_SOURCE
    fi

source $USER_UTILS_SOURCE

nepi_ip=${NEPI_IP%%/*}
echo "Updating with NEPI_IP ${NEPI_IP}"
network_id="$(echo "$nepi_ip" | cut -d'.' -f1-3)"
nepi_id=$(echo "$nepi_ip" | cut -d '.' -f 4-)


if [[ ${nepi_ip} != ${NEPI_IP_START} ]]; then
    echo ""
    echo "Your NEPI DEVICE IP address has changed from: ${NEPI_IP_START} to: ${nepi_ip}"

    remote_ip=${network_id}.5
    if ! ping -c 1 -W 1 ${remote_ip} > /dev/null 2>&1; then
        echo ""
        echo "Your Remote System's IP address needs to be updated"
        echo ""
        echo "Do you want to use the defualt Remote System IP ${remote_ip} for your device"
        choice=$(ask_yes_no)
        if [[ "$choice" == 'no' ]]; then
            valid_ip=0
            while [[ $valid_ip -eq 0 ]]; do
                echo ""
                read -p $'\n'"Enter a new Remote System IP Address (Current = ${REMOTE_IP}): " USER_INPUT
                echo ""
                if is_valid_ipv4 "$USER_INPUT"; then
                    export REMOTE_IP=$USER_INPUT
                    echo ""
                    valid_ip=1
                else
                    echo "Not A Valid IP Address"
                    echo ""
                fi         
            done
        else
            REMOTE_IP=$remote_ip
        fi  
        echo ""     
        if systemctl is-active --quiet NetworkManager; then
            slist=$(netlist_wired)
            if [[ "$slist" != *"$network_id"*  ]]; then

                if systemctl is-active --quiet NetworkManager; then
                    echo ""
                    echo "Do you want to update now?"
                    choice=$(ask_yes_no)
                    if [[ "$choice" == 'yes' ]]; then
                        echo ""
                        netset_custom "${REMOTE_IP}/24"
                        echo ""
                        echo "Updated Static IPs"
                        netlist_wired
                        sleep 3
                        # echo ""
                        # echo "Syncing NEPI Configs"
                        # nepisync
                    fi  
                    echo ""  
                fi
            fi
        else
            echo ""
            echo "Unable to update your systems Network Adapter automatically"   
            echo ""
            echo "Your PC's network adapter should be set to ${REMOTE_IP}"

        fi
    fi
fi


# echo ""
# echo "Loading Updated NEPI Config Settings" 
# source  $NEPI_USER_CONFIG_SCRIPT



SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
source ${SCRIPT_FOLDER}/remote_bash_setup.sh

 

echo ""
echo "Sourcing updated bash files"
source /home/${CONFIG_USER}/.bashrc
wait


echo ""
echo "Loading Updated NEPI Config Settings" 
source  $NEPI_USER_CONFIG_SCRIPT

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
systemctl&> /dev/null
if [[ "$?" -eq 0 && -n $DISPLAY ]]; then
    if [[ $SKIP_SOFTWARE -eq 0 ]]; then
        if [[ -n $DISPLAY ]]; then
            #####################################
            echo "########################"
            echo "Installing Desktop Utility Apps"
            echo ""

            SOURCE_ETC_PATH=$RESOURCES_FOLDER/etc

            # sudo apt update

            #######
            echo ""
            # if command -v mdview &>/dev/null; then
            #     echo "mdview is installed."
            # else
            #     echo "Installing mdview"
            #     sudo snap install mdview
            # fi

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



        #    echo "Configuring default code editor"
        #     CURRENT_DEFAULT=$(xdg-mime query default text/x-python 2>/dev/null)
        #     if [[ "$CURRENT_DEFAULT" == *"code"* ]]; then
        #         echo "VS Code is already the default code editor"
        #     else
        #         read -p "VS Code is not set as the default code editor. Set it now? [y/N] " response
        #         if [[ "$response" =~ ^[Yy]$ ]]; then
        #             sudo cp -r /home/${CONFIG_USER}/.config/mimeapps.list /home/${CONFIG_USER}/.config/mimeapps.list.org
        #             sudo cp -rf ${SOURCE_ETC_PATH}/user/mimeapps.list /home/${CONFIG_USER}/.config/mimeapps.list
        #             echo "VS Code set as default code editor"
        #         else
        #             echo "Skipping VS Code default setup"
        #         fi
        #     fi

        #     echo "Adding config and storage folders to files sidebar"
        #     sudo cp -rf ${SOURCE_ETC_PATH}/user/config/gtk-3.0/bookmarks  /home/${CONFIG_USER}/.config/gtk-3.0/bookmarks


        #     CURRENT_FAVS=$(sudo -u ${CONFIG_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${CONFIG_USER})/bus" gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "[]")
        #     if [[ "$CURRENT_FAVS" != *"chromium"* ]]; then
        #         echo "Adding Chromium to favourites"
        #         NEW_FAVS=$(echo "$CURRENT_FAVS" | sed "s/\]$/, 'chromium_chromium.desktop']/")
        #         gsettings set org.gnome.shell favorite-apps "$NEW_FAVS"
        #     else
        #         echo "Chromium already in favourites"
        #     fi
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

            #########################


            function add_chromium_bookmark() {
                local NAME="$1"
                local URL="$2"
                local BOOKMARKS_FILE="$3"
                
                # Check if jq is installed
                if ! command -v jq &> /dev/null; then
                    echo "Error: 'jq' is not installed. Please install it first."
                    return 1
                fi

                # Check if file exists
                if [ ! -f "$BOOKMARKS_FILE" ]; then
                    echo "Error: Chromium bookmarks file not found at $BOOKMARKS_FILE"
                    return 1
                fi
                sudo chmod 0700 $BOOKMARKS_FILE
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $BOOKMARKS_FILE
                # Create a temporary file to work on
                local TEMP_FILE=$(mktemp)

                # Use jq to append the new bookmark to the 'bookmark_bar' children array
                jq --arg name "$NAME" --arg url "$URL" \
                '.roots.bookmark_bar.children += [{
                    "date_added": (now * 1000000 | floor | tostring),
                    "id": (([.roots.bookmark_bar.children[].id | tonumber] | max + 1) | tostring),
                    "name": $name,
                    "type": "url",
                    "url": $url
                }]' "$BOOKMARKS_FILE" > "$TEMP_FILE"

                # Overwrite original file (keeping a backup is recommended)
                cp "$BOOKMARKS_FILE" "${BOOKMARKS_FILE}.bak"
                mv "$TEMP_FILE" "$BOOKMARKS_FILE"
                sudo chmod 0700 $BOOKMARKS_FILE
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $BOOKMARKS_FILE
                
                echo "Successfully added '$NAME' to Chromium bookmarks."
            }

            echo "Locating Chromium profile"
            if [[ -d "/home/${CONFIG_USER}/snap/chromium/common/chromium" ]]; then
                CHROMIUM_PROFILE="/home/${CONFIG_USER}/snap/chromium/common/chromium"
                sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/snap
            elif [[ -d "/home/${CONFIG_USER}/.config/chromium" ]]; then
                CHROMIUM_PROFILE="/home/${CONFIG_USER}/.config/chromium"
                sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}.config/chromium
            else
                CHROMIUM_FOLDER="/home/${CONFIG_USER}/snap/chromium/common/chromium"
                sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/snap
                if [[ ! -d CHROMIUM_FOLDER ]]; then
                    sudo mkdir -p ${CHROMIUM_FOLDER}/Default
                fi
                if [[ -d CHROMIUM_FOLDER ]]; then
                    CHROMIUM_PROFILE="${CHROMIUM_FOLDER}"
                fi
                
            fi

            if [[ -n "$CHROMIUM_PROFILE" ]]; then

                if [[ -d ${CHROMIUM_PROFILE} ]]; then
                    echo "Cleaning Chromium Profile ${CHROMIUM_PROFILE}"
                    sudo rm -rf ${CHROMIUM_PROFILE}/Singleton* > /dev/null 2>&1
                    #sudo rm -rf /home/${CONFIG_USER}/.cache/chromium > /dev/null 2>&1

                    echo "Updating Chromiun Settings in ${CHROMIUM_PROFILE}"
                    sudo chown ${CONFIG_USER}:${CONFIG_USER} $CHROMIUM_PROFILE
                    #sudo cp -r $CHROMIUM_PROFILE ${CHROMIUM_PROFILE}.org
                    CHROMIUM_DEFAULT=${CHROMIUM_PROFILE}/Default
                    sudo chown ${CONFIG_USER}:${CONFIG_USER} $CHROMIUM_DEFAULT
                    # Copy only the Bookmarks file
                    BOOKMARKS_FILE=${CHROMIUM_DEFAULT}/Bookmarks
                    if [[ ! -f $BOOKMARKS_FILE ]]; then
                        sudo cp -f "${SOURCE_ETC_PATH}/user/chromium/common/chromium/Default/Bookmarks" $BOOKMARKS_FILE
                    fi
                    if [[ -f $BOOKMARKS_FILE ]]; then
                        sudo chmod 0700 $BOOKMARKS_FILE
                        sudo chown ${CONFIG_USER}:${CONFIG_USER} $BOOKMARKS_FILE
                        if ! grep -qnw $BOOKMARKS_FILE -e "RUI-App" ; then
                            add_chromium_bookmark "RUI-App" "192.168.179.103:5003" $BOOKMARKS_FILE
                            add_chromium_bookmark "NEPI-Home" "https://nepi.com" $BOOKMARKS_FILE
                            add_chromium_bookmark "NEPI-GITHUB" "https://github.com/nepi-engine" $BOOKMARKS_FILE
                        fi
                        rui_ip=$nepi_ip
                        sed -i "s/localhost/$rui_ip/g" $BOOKMARKS_FILE
                        sudo chmod 0700 $BOOKMARKS_FILE
                        sudo chown ${CONFIG_USER}:${CONFIG_USER} $BOOKMARKS_FILE
                        echo "Updated Chromiun Bookmarks in ${BOOKMARKS_FILE}"
                    fi

                    # Enable the Home button in Preferences without overwriting the whole file
                    PREFS_FILE="$CHROMIUM_DEFAULT/Preferences"
                    if [[ ! -f $PREFS_FILE ]]; then
                        sudo cp -f "${SOURCE_ETC_PATH}/user/chromium/common/chromium/Default/Preferences" $PREFS_FILE
                    fi
                    if [[ -f $BOOKMARKS_FILE ]]; then
                        sudo chmod 0700 $PREFS_FILE
                        sudo chown ${CONFIG_USER}:${CONFIG_USER} $PREFS_FILE
                        update_json_value "$PREFS_FILE" browser.show_home_button true
                        update_json_value "$PREFS_FILE" bookmark_bar.show_on_all_tabs true
                        sudo chmod 0700 $PREFS_FILE
                        sudo chown ${CONFIG_USER}:${CONFIG_USER} $PREFS_FILE
                        echo "Updated Chromiun Preferences in ${PREFS_FILE}"
                    fi
                fi
            fi
        fi
    fi
fi


    #####################################
    echo " "
    echo "################################# "
    echo "NEPI DEV PC SETUP COMPLETE"
    echo "################################# "
    echo " "


    echo "Your NEPI DEVICE IP address is set to:" 
    echo "${NEPI_IP}"

    echo ""
    if pings; then
        echo "Your Dev device network adapter is set to ${REMOTE_IP}"
    else
        echo "Your Dev device network adapter should be set to ${REMOTE_IP}"
    fi
    if systemctl is-active --quiet NetworkManager; then
        echo "You can switch network adapter settings by typing:"
        echo "netsetnepi  OR   netsetauto  OR  netsetcustom 'ip_address/netmask'"   
    fi  

    echo " "
    echo "You can check your NEPI Device connection by typing:"
    echo "pingn   OR   ping ${nepi_ip}"

    echo " "
    echo "Your NEPI ssh key is set to ${NEPI_SSH_KEY}"
    echo "You can ssh into your NEPI Docker Host OS or running NEPI Docker Contatiner by typing:"
    echo "sshnh  OR   sshn"

    echo " "
    echo "You can connect to your NEPI Device's shared network drives by typing:"
    echo "nepistorage  OR   nepiconfig   to change to sharedrive drive"
    echo "nepistorage_open  OR   nepiconfig_open   to open file manager to sharedrive drive"

    echo " "
    echo "You can connect to your NEPI Device's RUI in a Chrome browser at:"
    echo "nepirui   OR   entering  http://${nepi_ip}:5003/  in a Chromium browser"

    echo " "
    echo "To see a list of available NEPI bash command line shortcuts run: nepihelp"
    echo " "





