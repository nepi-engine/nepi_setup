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
echo "Script Folder: ${SCRIPT_FOLDER}"
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

# Load System Config File
#echo "Loading NEPI SYSTEM CONFIG"
NEPI_SETUP_CONFIG_FILE=${RESOURCES_FOLDER}/etc/load_system_config.sh
NEPI_SYSTEM_CONFIG_FILE=/mnt/nepi_confg/system_cfg/etc/load_system_config.sh
if [[ -f $NEPI_SYSTEM_CONFIG_FILE ]]; then
    echo "Loading config from: ${NEPI_SYSTEM_CONFIG_FILE}"
    source ${NEPI_SYSTEM_CONFIG_FILE}
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SYSTEM_CONFIG_FILE}"
    fi
elif [[ -f $NEPI_SETUP_CONFIG_FILE ]]; then
    echo "Loading config from: ${NEPI_SYSTEM_CONFIG_FILE}"
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
    NEPI_SSH_KEY_PUB=$(cat $NEPI_SSH_KEY_PATH)
    NEPI_SSH_KEY_EMAIL="${NEPI_SSH_KEY_PUB##* }"
    




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
    

    nepi_mode=HOST
    export NEPI_MODE=$nepi_mode
    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_MODE=" "export NEPI_MODE=${nepi_mode}"

    nepi_ip=${NEPI_STATIC_IP%%/*}
    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IP=" "export NEPI_IP=${nepi_ip}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_DEVICE_ID=" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_HOST_USER=" "export NEPI_HOST_USER=${CONFIG_USER}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_SSH_KEY_FILE=" "export NEPI_SSH_KEY_FILE=${NEPI_SSH_KEY_FILE}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IN_CONTAINER=" "export NEPI_IN_CONTAINER=1"




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



        echo ' ' | sudo tee -a $NEPI_UTILS_FILE_DEST
        echo '##### Python Config #####' | sudo tee -a $NEPI_UTILS_FILE_DEST
        echo 'export NEPI_PYTHON='${NEPI_PYTHON} | sudo tee -a $NEPI_UTILS_FILE_DEST
        echo 'export PYTHONPATH='${NEPI_ENGINE}'/etc:${PYTHONPATH}' | sudo tee -a $NEPI_UTILS_FILE_DEST
        echo 'export PYTHONPATH='${NEPI_ENGINE}'/lib/nepi_drivers:${PYTHONPATH}' | sudo tee -a $NEPI_UTILS_FILE_DEST
        echo 'export PYTHONPATH=/usr/local/lib/python'${NEPI_PYTHON}'/site-packages:${PYTHONPATH}' | sudo tee -a $NEPI_UTILS_FILE_DEST
        echo 'export PYTHONPATH=/home/'${CONFIG_USER}'/.local/lib/python'${NEPI_PYTHON}'/site-packages:${PYTHONPATH}' | sudo tee -a $NEPI_UTILS_FILE_DEST
        if [[ "$CONFIG_USER" == 'nepi' ]]; then
            echo 'export SETUPTOOLS_USE_DISTUTILS=stdlib' | sudo tee -a $NEPI_UTILS_FILE_DEST
        fi


    cuda_version=$(get_cuda_version)

    if [[ ${cuda_version} != '0' ]]; then
        export NEPI_HAS_CUDA=1
        export NEPI_CUDA_VERSION=$cuda_version
    else
        export NEPI_HAS_CUDA=0
        export NEPI_CUDA_VERSION=0
    fi


    if [[ "$NEPI_HAS_CUDA" -eq 1 ]]; then
        

        CUDA_HOME=/usr/local/cuda-${NEPI_CUDA_VERSION}

            echo ' ' | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo '##### CUDA SETUP #####' | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo 'export CUDA_PATH='${CUDA_HOME} | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo 'export CUDA_HOME='${CUDA_HOME} | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo 'export CUPY_NVCC_GENERATE_CODE=current' | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo 'export LD_LIBRARY_PATH='${CUDA_HOME}'/lib64:$LD_LIBRARY_PATH' | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo 'export PATH='${CUDA_HOME}'/bin:${PATH}' | sudo tee -a $NEPI_UTILS_FILE_DEST
            echo 'export CUDA_VISIBLE_DEVICES=0' | sudo tee -a $NEPI_UTILS_FILE_DEST
    fi



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



    sudo chown ${CONFIG_USER}:${CONFIG_USER} $file
    sudo chmod 0644 $file

    echo ""
    echo "Sourcing updated bash files"
    source $file
    wait



    echo " "
    echo "################################# "
    echo "Clearing Known Hosts"
    echo ""
    sudo rm -r /home/${CONFIG_USER}/.ssh/known_hosts* >/dev/null 2>&1
    # ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepi" >/dev/null 2>&1
    # ssh-keygen -f "/home/${CONFIG_USER}/.ssh/known_hosts" -R "nepihost" >/dev/null 2>&1

    echo " "
    echo "################################# "
    echo "Emptying Trash"
    echo ""
    empty_trash




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

