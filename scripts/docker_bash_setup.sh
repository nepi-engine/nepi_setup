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
export LITE_INSTALL=$LITE_INSTALL
# echo "LITE_INSTALL=${LITE_INSTALL}"

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $1
if [[ "$?" -ne 0 ]]; then
    return 
fi


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



####################################
# Run NEPI Bash Setup Script

echo ""
echo "########################"
echo "NEPI Docker Bash Setup"
echo "########################"
echo ""


#############

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
    nepi_ip=${NEPI_STATIC_IP%%/*}
    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IP=" "export NEPI_IP=${nepi_ip}"

    echo "${nepi_ip} nepi" | sudo tee -a $file
    echo "${nepi_ip} nepi-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${nepi_ip} ${NEPI_HOST_USER}" | sudo tee -a $file
    echo "${nepi_ip} ${NEPI_HOST_USER}-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${nepi_ip} nepiadmin" | sudo tee -a $file
    echo "${nepi_ip} nepiadmin-${NEPI_DEVICE_ID}" | sudo tee -a $file
    echo "${nepi_ip} nepiuser" | sudo tee -a $file
    echo "${nepi_ip} nepiuser-${NEPI_DEVICE_ID}" | sudo tee -a $file



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
    
    nepi_ip=${NEPI_STATIC_IP%%/*}
    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IP=" "export NEPI_IP=${nepi_ip}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_DEVICE_ID=" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_HOST_USER=" "export NEPI_HOST_USER=${NEPI_HOST_USER}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_SSH_KEY_FILE=" "export NEPI_SSH_KEY_FILE=${NEPI_SSH_KEY_FILE}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IN_CONTAINER=" "export NEPI_IN_CONTAINER=1"

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


    # UPDATE NEPI Python Vesion
    pyver=$(python3 --version | awk '{print $2}')
    if [[ -n "$pyver" ]]; then
        pyver="${pyver%.*}"
    else
        pyver=3
    fi
    NEPI_PYTHON=$pyver

    if [[ ! -d /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages ]]; then
        sudo mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages
    fi
    #echo "Udating user python permissions"
    sudo chmod 755 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages





    ##############
    echo "Installing NEPI PC Aliases file"

    NEPI_ALIASES_SOURCE=${RESOURCES_FOLDER}/bash/nepi_docker_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_docker_aliases
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


################
echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0644 /home/${CONFIG_USER}/.profile



###############
echo "Fixing other system folder permissions"
if [[ ! -d "/media/${CONFIG_USER}" ]]; then
    sudo mkdir -p "/media/${CONFIG_USER}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /media/${CONFIG_USER}



echo ""
echo "########################"
echo "NEPI Docker Bash Setup Complete"
echo "########################"
echo ""

