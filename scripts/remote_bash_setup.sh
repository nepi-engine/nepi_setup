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


echo " "
echo "################################# "
echo "Sourcing NEPI Bash Utils File"
echo ""

if [[ -n $REMOTE_IP ]]; then
    remote_ip=$REMOTE_IP
fi

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
USER_UTILS_SOURCE=/home/${CONFIG_USER}/.nepi_bash_utils
if [[ -f $USER_UTILS_SOURCE ]]; then
    source $USER_UTILS_SOURCE
else
    source $NEPI_UTILS_SOURCE
fi


echo " "
echo "################################# "
echo "Updating NEPI Config Files"
echo ""

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

#NEPI_IP=${NEPI_STATIC_IP%%/*}

if [[ -n $remote_ip ]]; then
    export REMOTE_IP=$remote_ip
else
    network_id="$(echo "$NEPI_IP" | cut -d'.' -f1-3)"
    remote_ip=${network_id}.5
    export REMOTE_IP=$remote_ip
fi



    #####################################
    echo " "
    echo "################################# "
    echo "Updating Bash Files"
    echo ""

    nepi_mode=REMOTE
    export NEPI_MODE=$nepi_mode
    
    sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}

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


    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_MODE=" "export NEPI_MODE=${nepi_mode}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IP=" "export NEPI_IP=${NEPI_IP}"

    update_text_value $NEPI_UTILS_FILE_DEST "export REMOTE_IP=" "export REMOTE_IP=${REMOTE_IP}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_DEVICE_ID=" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_HOST_USER=" "export NEPI_HOST_USER=${NEPI_HOST_USER}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IN_CONTAINER=" "export NEPI_IN_CONTAINER=${NEPI_IN_CONTAINER}"


    ##############
    echo "Installing NEPI Remote Dev Aliases file"

    NEPI_ALIASES_SOURCE=${RESOURCES_FOLDER}/bash/nepi_remote_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_remote_aliases
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

    sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}

    echo ""
    echo "Sourcing updated bash files"
    source /home/${CONFIG_USER}/.bashrc
    wait


    ####################################################
    nepisync
        

    echo " "
    echo "################################# "
    echo "Updating SSH Keys"
    echo ""

    
    if [[ -n $NEPI_SSH_KEY ]]; then
        NEPI_SSH_KEY_PATH=/home/${CONFIG_USER}/.ssh/${NEPI_SSH_KEY}
        if [[ -f $NEPI_SSH_KEY_PATH ]]; then
            NEPI_SSH_KEY_FILE=$NEPI_SSH_KEY
        else
            NEPI_SSH_KEY_FILE=nepi_default_ssh_key
        fi
    else
        NEPI_SSH_KEY_FILE=nepi_default_ssh_key
    fi    
    echo "Using NEPI_SSH_KEY ${NEPI_SSH_KEY}"
    NEPI_SSH_KEY_PATH=/home/${CONFIG_USER}/.ssh/${NEPI_SSH_KEY_FILE}
    NEPI_SSH_KEY_PUB=$(cat $NEPI_SSH_KEY_PATH)
    NEPI_SSH_KEY_EMAIL="${NEPI_SSH_KEY_PUB##* }"

    echo " "
    echo "################################# "
    echo "Setting up SSH Key ${NEPI_SSH_KEY_FILE}"
    echo ""

    nepisetkey $NEPI_SSH_KEY_FILE

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_SSH_KEY_FILE=" "export NEPI_SSH_KEY_FILE=${NEPI_SSH_KEY_FILE}"


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


    if [[ -n ${NEPI_IP} ]]; then
        nepi_ip="${NEPI_IP%%/*}"
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

    echo " "
    echo "################################# "
    echo "Cleaning Known Host for IP ${nepi_ip}"
    echo ""

    ssh-keygen -R $nepi_ip
    # sudo rm -r /home/${CONFIG_USER}/.ssh/known_hosts* >/dev/null 2>&1
    # ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepi" >/dev/null 2>&1
    # ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepihost" >/dev/null 2>&1


    #####################################
    echo " "
    echo "################################# "
    echo "NEPI REMOTE BASH SETUP COMPLETE"
    echo "################################# "
    echo " "



   




