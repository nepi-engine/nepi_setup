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

CONFIG_USER=$(id -un)

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


# This file sets up nepi bash aliases and util functions
echo "########################"
echo "NEPI DEV PC SETUP"
echo "########################"


if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then

    NEPI_IN_CONTAINER=1
    NEPI_DEVICE_ID=device1
    NEPI_IP=192.168.179.103
    NEPI_HOST_USER=nepihost

    USER_CONFIG_FILE=/home/${CONFIG_USER}/nepi_system_config.yaml
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        echo "Updating NEPI CONFIG from File: ${USER_CONFIG_FILE} "
        load_yaml_file $USER_CONFIG_FILE 2>/dev/null
    fi

    NEPI_USER_CONFIGS=(
    NEPI_DEVICE_ID \
    NEPI_IP \
    NEPI_IN_CONAINTER \
    NEPI_HOST_USER \
    )

    function print_current_config(){
        echo ""
        echo "Current Settings"
        echo "---------------------"
        echo "NEPI_IP: ${NEPI_IP}"
        echo "NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
        echo "NEPI_HOST_USER: ${NEPI_HOST_USER}"
        echo ""
    }

    function udpate_config_file(){
        config_file=$1
        update_yaml_value "NEPI_IP" $NEPI_IP $config_file
        update_yaml_value "NEPI_DEVICE_ID" $NEPI_DEVICE_ID $config_file
        update_yaml_value "NEPI_HOST_USER" $NEPI_HOST_USER $config_file
    }


    #####################################
    # Update NEPI System Config if needed

    echo ""
    PS3=$'\n'"Please enter your choice by NUMBER: "
    options=(  "Update Static IP Address" "Update Device ID Name" "Update NEPI Host User" "CONTINUE" )

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



    ####################################################

    echo " "
    echo "################################# "
    echo "Updating SSH Keys"
    echo ""


    ###################
    # Check for default key

    NEPI_SSH_PKEY_SOURCE=${RESOURCES_FOLDER}/etc/ssh/ssh_keys/private_keys
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
    bfile=${file}.bak

    if [[ ! -f "$bfile" ]]; then
        path_backup $file $bfile
    fi

    sudo cp -a $bfile $file

    echo "Updating NEPI IP in ${file}"

    echo "${NEPI_IP} nepi" | sudo tee -a $file
    echo "${NEPI_IP} nepi-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${NEPI_IP} ${NEPI_HOST_USER}" | sudo tee -a $file
    echo "${NEPI_IP} ${NEPI_HOST_USER}-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${NEPI_IP} nepiadmin" | sudo tee -a $file
    echo "${NEPI_IP} nepiadmin-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${NEPI_IP} nepiuser" | sudo tee -a $file
    echo "${NEPI_IP} nepiuser-${NEPI_DEVICE_ID}" | sudo tee -a $file



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

    # export NEPI_USER=nepi
    # export NEPI_HOST_USER=nepihost

    # export NEPI_IP=192.168.179.103
    # export NEPI_DEVICE_ID=device1
    # export NEPI_RECOVERY_DEVICE_ID=device1
    # export NEPI_RECOVERY_IP=192.168.179.103
    # export NEPI_IN_CONTAINER=1


    # export NEPI_HOME=/home/$CONFIG_USER
    # export NEPI_BASE=/opt/nepi
    # export NEPI_ENGINE=${NEPI_BASE}/nepi_engine
    # export NEPI_STORAGE='/mnt/nepi_storage'
    # export NEPI_SYSTEM_CONFIG='/mnt/nepi_config/sytem_cfg'
    # export NEPI_DOCKER_CONFIG='/mnt/nepi_config/docker_cfg'


    # export NEPI_SSH_KEY_FILE=nepi_engine_default_private_ssh_key
    # export NEPI_SSH_KEY_PATH=/home/${CONFIG_USER}/ssh_keys/${NEPI_SSH_KEY_FILE}
    # export NEPI_SSH_KEY=$NEPI_SSH_KEY_PATH

    # export NEPI_TARGET_IP=$NEPI_IP
    # export NEPI_TARGET_USERNAME=$NEPI_USER
    # export NEPI_TARGET_SRC_DIR=${NEPI_STORAGE}/nepi_src

    # export NEPI_GITHUB_REPO=git@github.com:nepi-engine/nepi_engine_ws.git



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
    source $file
    wait



    echo " "
    echo "################################# "
    echo "Clearing Known Hosts"
    echo ""

    ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepi" >/dev/null 2>&1
    ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepihost" >/dev/null 2>&1



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



    #####################################
    echo " "
    echo "################################# "
    echo "NEPI DEV PC SETUP COMPLETE"
    echo "################################# "
    echo " "
    echo "To see a list of NEPI command line shortcuts run: nepihelp"
    echo " "

else

    echo "THIS SCRIPT CANNOT BE RUN BY USER nepi OR nepihost"

fi


