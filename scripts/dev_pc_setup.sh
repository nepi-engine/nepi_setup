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
    exit 1
fi

# This file sets up nepi bash aliases and util functions



echo "########################"
echo "NEPI DEV PC SETUP"
echo "########################"

echo "Running Intitialization Scripts"


CONFIG_USER=$(id -un)

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_SOURCE_FOLDER=$(dirname "${SCRIPT_FOLDER}")/resources/etc

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



new_key=0





if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then

    if ! is_valid_internet >/dev/null 2>&1; then
        echo "No Internet Connection Detected.  Connect and rerun this script"
        exit 1
    fi

    #####################################
    # Script Functions

    NEPI_IN_CONTAINER=1
    NEPI_DEVICE_ID=device1
    NEPI_IP=192.168.179.103


    NEPI_USER_CONFIGS=(
    NEPI_DEVICE_ID \
    NEPI_IP \
    NEPI_IN_CONAINTER \
    )

    function print_current_config(){
        echo ""
        echo "Current Settings"
        echo "---------------------"
        echo "NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
        echo "NEPI_IP: ${NEPI_IP}"
        echo ""
    }

    function udpate_config_file(){
        config_file=$1
        update_yaml_value "NEPI_IN_CONTAINER" $NEPI_IN_CONTAINER $config_file
        update_yaml_value "NEPI_DEVICE_ID" $NEPI_DEVICE_ID $config_file
        update_yaml_value "NEPI_IP" $NEPI_IP $config_file

    }


    #####################################
    # Update NEPI System Config if needed

    nepi_in_container=1
    ## Check Selection
    echo ""
    echo "Is NEPI running in a container on your Host device. Defualt is: Yes"
    select ovw in "Yes" "No" "Quit"; do
        case $ovw in
            Yes ) nepi_in_container=1; break;;
            No ) nepi_in_container=0; break;;
            Quit ) exit 1
        esac
    done
    export NEPI_IN_CONTAINER=$nepi_in_container



    echo ""
    PS3='Please enter your choice: '
    options=( "USE CURRENT SETTINGS" "Update NEPI Device ID Name" "Update NEPI Static IP Address" "QUIT" )

    while true; do
        #clear # Optional: Clear the screen before displaying the menu

        print_current_config
        select opt in "${options[@]}" ; do
            case $opt in
                "USE CURRENT SETTINGS")
                    break 2 # Exit both the select and the while loop
                    ;;
                "Update NEPI Device ID Name")
                    read -p "Enter a new Device Name (Default=device1): " USER_INPUT
                    echo ""
                    if is_valid_did "$USER_INPUT"; then
                        export NEPI_DEVICE_ID=$USER_INPUT
                    fi       
                    echo ""
                    break # Exit the select statement, re-display menu
                ;;
                "Update NEPI Static IP Address")
                    read -p "Enter a new Static IP Address (Default=192.168.179.103): " USER_INPUT
                    echo ""
                    if is_valid_ipv4 "$USER_INPUT"; then
                        export NEPI_IP=$USER_INPUT
                    fi
                    echo ""
                    break # Exit the select statement, re-display menu
                    ;;
                "QUIT")
                    exit 0
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






    ####################################################


    echo " "
    echo "################################# "
    echo "Installing Required Software"
    echo ""

    if command -v yq &>/dev/null; then
        : # Do nothing here
    else
        echo ">>>>>>>>>>>>>>>"
        echo "Installing yq software"
        sudo add-apt-repository ppa:rmescandon/yq -y
        sudo apt update
        sudo apt install yq -y
    fi
    if command -v git &>/dev/null; then
        : # Do nothing here
    else
        echo ">>>>>>>>>>>>>>>"
        echo "Installing git software"
        sudo apt install git -y
        sudo apt install gitk -y
    fi

    #sudo apt install nmap -y

    if command -v snap &>/dev/null; then
        : # Do nothing here
    else
        echo ">>>>>>>>>>>>>>>"
        echo "Installing snap software"
        sudo apt install snap -y
    fi

    if command -v xclip &>/dev/null; then
        : # Do nothing here
    else
        echo ">>>>>>>>>>>>>>>"
        echo "Installing xclip software"
        sudo apt install xclip -y
    fi


    echo "########################"
    echo "Installing Utility Apps"
    echo ""


    ######
    if command -v code &> /dev/null; then
        echo "Chromium is installed and accessible."
    else
        echo ">>>>>>>>>>>>>>>"
        echo "Installing Chromium Browser"
        #sudo snap remove --purge chromium
        sudo snap install chromium
        #sudo apt install chromium-browser -y
        #chromium-browser --disable-features=DnsOverHttps

    fi


    if command -v mdview &>/dev/null; then
        : # Do nothing here
    else
        echo ">>>>>>>>>>>>>>>"
        echo "Installing mdview software"
        sudo snap install mdview
    fi

    ######
    if command -v code &> /dev/null; then
        echo "Visual Studio Code is installed and accessible."
    else
        echo ">>>>>>>>>>>>>>>"
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

    ####################################################

    echo " "
    echo "################################# "
    echo "Updating SSH Keys"
    echo ""


    ###################
    # Check for default key

    NEPI_SSH_PKEY_SOURCE=${ETC_SOURCE_FOLDER}/ssh/ssh_keys/private_keys
    NEPI_SSH_PKEY_DEST=/home/${CONFIG_USER}/ssh_keys
    if [ ! -d $NEPI_SSH_PKEY_SOURCE ]; then
        echo "FAILED TO FIND NEPI SOURCE KEYS FOLDER at: ${NEPI_SSH_PKEY_SOURCE} "
    else
        echo "Installing NEPI SSH Private Keys from: ${NEPI_SSH_PKEY_SOURCE} "
        if [[ ! -d "$NEPI_SSH_PKEY_DEST" ]]; then
            mkdir -p $NEPI_SSH_PKEY_DEST
        fi
        sudo chmod 0600 $NEPI_SSH_PKEY_SOURCE/*
        sudo cp -p $NEPI_SSH_PKEY_SOURCE/* /home/${CONFIG_USER}/ssh_keys/
    fi
    if [ -d "/home/${CONFIG_USER}/ssh_keys" ]; then
        sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/ssh_keys/*
    fi

    ###############
    echo "Checking for available key options"
    sel_ssh_file=$(select_file_from_folder $NEPI_SSH_PKEY_DEST | tail -n 1)

    echo $sel_ssh_file
    if [[ -n "$sel_ssh_file"  ]]; then
        sel_ssh_path=${NEPI_SSH_PKEY_DEST}/${sel_ssh_file}
        if [[ -f "$sel_ssh_path" ]]; then
            NEPI_SSH_FILE=$sel_ssh_file
            NEPI_SSH_SOURCE=$sel_ssh_path
            echo "Using SSH Key file: ${NEPI_SSH_SOURCE}"
            export NEPI_SSH_KEY_FILE=$NEPI_SSH_FILE
        fi
    else
        echo "No SSH Key Found"
        export NEPI_SSH_KEY_FILE=nepi_engine_default_private_ssh_key
    fi




    #################
    # Update Key Path
    sudo chmod 0700 $NEPI_SSH_PKEY_DEST
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_SSH_PKEY_DEST



    echo " "
    echo "################################# "
    echo "Updating ETC Hosts File"
    echo ""

    file=/etc/hosts
    bfile=${file}.org
    if [[ ! -f "$bfile" ]]; then
        path_backup $file $bfile
    fi

    sudo cp -a $bfile $file

    echo "Updating NEPI IP in ${file}"

    echo "${NEPI_IP} nepi" | sudo tee -a $file
    echo "${NEPI_IP} nepi-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${NEPI_IP} nepihost" | sudo tee -a $file
    echo "${NEPI_IP} nepihost-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${NEPI_IP} nepiadmin" | sudo tee -a $file
    echo "${NEPI_IP} nepiadmin-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${NEPI_IP} nepiuser" | sudo tee -a $file
    echo "${NEPI_IP} nepiuser-${NEPI_DEVICE_ID}" | sudo tee -a $file



    #####################################
    echo " "
    echo "################################# "
    echo "Updating Bash Files"
    echo ""

    echo "Updating NEPI aliases files with NEPI_IP: ${NEPI_IP}"
    BASHRC=/home/${CONFIG_USER}/.bashrc


    ##############
    echo "Installing NEPI Utils files"

    NEPI_UTILS_FILE_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
    NEPI_UTILS_FILE_DEST=/home/${CONFIG_USER}/.nepi_bash_utils

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_FILE_SOURCE
    sudo chmod 775 $NEPI_UTILS_FILE_SOURCE
    sudo cp -p $NEPI_UTILS_FILE_SOURCE $NEPI_UTILS_FILE_DEST

    NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_utils
    NEPI_UTILS_DEST=/home/${CONFIG_USER}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_SOURCE
    sudo chmod 775 $NEPI_UTILS_SOURCE
    sudo cp -R -p $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST/

    ##############
    NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_pc_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_pc_aliases
    echo "Installing NEPI aliases file from ${NEPI_ALIASES_SOURCE} to ${NEPI_ALIASES_DEST} "
    if [ -f "$NEPI_ALIASES_DEST" ]; then
        sudo rm $NEPI_ALIASES_DEST
    fi
    sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST

    #############
    echo "Updating user bashrc files"
    ### Backup CONFIG_USER BASHRC file if needed
    file=$BASHRC
    bfile=${BASHRC}.org
    path_backup $file $bfile

    sudo cp $bfile $BASHRC
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $BASHRC
    sudo chmod 775 $BASHRC

    # Add additional user bashrc statements
    # Add NEPI SETTINGS
    echo ' ' | sudo tee -a $BASHRC
    echo '##### NEPI SETTINGS #####' | sudo tee -a $BASHRC
    echo 'export NEPI_IP='${NEPI_IP} | sudo tee -a $BASHRC
    echo 'export NEPI_DEVICE_ID='${NEPI_DEVICE_ID} | sudo tee -a $BASHRC
    echo 'export NEPI_RECOVERY_DEVICE_ID=device1' | sudo tee -a $BASHRC
    echo 'export NEPI_RECOVERY_IP=192.168.179.103' | sudo tee -a $BASHRC
    echo 'export NEPI_IN_CONTAINER='${NEPI_IN_CONTAINER} | sudo tee -a $BASHRC
    echo 'export NEPI_SSH_KEY_FILE='${NEPI_SSH_KEY_FILE} | sudo tee -a $BASHRC


    if grep -qnw $BASHRC -e "##### Source NEPI Aliases #####" ; then
        : #echo "Already Done"
    else
        echo ' ' | sudo tee -a $BASHRC
        echo '##### Source NEPI Aliases #####' | sudo tee -a $BASHRC
        echo 'if [ -f '${NEPI_ALIASES_DEST}' ]; then' | sudo tee -a $BASHRC
        echo '    . '${NEPI_ALIASES_DEST} | sudo tee -a $BASHRC
        echo 'fi' | sudo tee -a $BASHRC
    fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ~/.bashrc
    sudo chmod 0644 ~/.bashrc

    echo ""
    echo "Sourcing updated bash files"
    source $BASHRC
    wait



    echo " "
    echo "################################# "
    echo "Clearing Known Hosts"
    echo ""

    ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepi" >/dev/null 2>&1
    ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepihost" >/dev/null 2>&1



fi







echo " "
echo "################################# "
echo "NEPI DEV PC SETUP COMPLETE"
echo "################################# "
echo " "
echo " "
echo "To see a list of NEPI command line shortcuts run: nepihelp"
