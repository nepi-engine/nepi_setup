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
NEPI_SYSTEM_CONFIG_FILE=/home/${CONFIG_USER}/load_system_config.sh
if [[ -f $NEPI_SYSTEM_CONFIG_FILE ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SYSTEM_CONFIG_FILE}"
    source ${NEPI_SYSTEM_CONFIG_FILE}
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SYSTEM_CONFIG_FILE}"
    fi
elif [[ -f $NEPI_SETUP_CONFIG_FILE ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SETUP_CONFIG_FILE}"
    source ${NEPI_SETUP_CONFIG_FILE}
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SETUP_CONFIG_FILE}"
    fi
fi

echo "########################"
echo "NEPI BASH SETUP"
echo "########################"



    #####################################
    echo " "
    echo "################################# "
    echo "Updating Bash Files"
    echo ""


    ##############
    echo "Setting up NEPI Bash Utils file"


    NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_utils
    NEPI_UTILS_DEST=/home/${CONFIG_USER}

    echo "Copying ${NEPI_UTILS_SOURCE} to ${NEPI_UTILS_DEST}/"
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_SOURCE
    sudo chmod 775 $NEPI_UTILS_SOURCE
    sudo cp -R -p $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST/

    NEPI_UTILS_FILE_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
    NEPI_UTILS_FILE_DEST=/home/${CONFIG_USER}/.nepi_bash_utils

    echo "Copying ${NEPI_UTILS_FILE_SOURCE} to ${NEPI_UTILS_FILE_DEST}/"

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_FILE_SOURCE
    sudo chmod 775 $NEPI_UTILS_FILE_SOURCE
    sudo cp -p $NEPI_UTILS_FILE_SOURCE $NEPI_UTILS_FILE_DEST


    nepi_ip=${NEPI_STATIC_IP%%/*}
    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IP=" "export NEPI_IP=${nepi_ip}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_DEVICE_ID=" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_HOST_USER=" "export NEPI_HOST_USER=${NEPI_HOST_USER}"

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_SSH_KEY_FILE=" "export NEPI_SSH_KEY_FILE=${NEPI_SSH_KEY_FILE}"


    systemctl&> /dev/null
    res=$?
    if [[ "$res" -eq 0 ]]; then
        export NEPI_IN_CONTAINER=0
    else
        export NEPI_IN_CONTAINER=1
    fi

    update_text_value $NEPI_UTILS_FILE_DEST "export NEPI_IN_CONTAINER=" "export NEPI_IN_CONTAINER=${NEPI_IN_CONTAINER}"


    # export NEPI_USER=nepi
    # export NEPI_HOST_USER=nepihost

    # export NEPI_IP=192.168.179.103
    # export NEPI_DEVICE_ID=device1
    # export NEPI_RECOVERY_ID=device1
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




    echo ' ' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo '##### System Config #####' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo '#export CMAKE_POLICY_VERSION_MINIMUM=3.5' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo 'export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}' | sudo tee -a $NEPI_UTILS_FILE_DEST

    echo 'if [[ -f "/usr/lib/aarch64-linux-gnu/libgomp.so.1" ]]; then' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo '   LIB1=/usr/lib/aarch64-linux-gnu/libgomp.so.1' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo 'fi' | sudo tee -a $NEPI_UTILS_FILE_DEST

    echo  | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo 'if [[ -f "/usr/local/lib/libOpen3D.so" ]]; then' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo '  LIB2=/usr/local/lib/libOpen3D.so' | sudo tee -a $NEPI_UTILS_FILE_DEST
    echo 'fi' | sudo tee -a $NEPI_UTILS_FILE_DEST

    echo 'export LD_PRELOAD="$LIB1 $LIB2"' | sudo tee -a $NEPI_UTILS_FILE_DEST




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



if is_valid_cuda; then
    export NEPI_HAS_CUDA=1
    export NEPI_CUDA_VERSION=$(get_cuda_version)
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

    NEPI_ALIASES_SOURCE=${RESOURCES_FOLDER}/bash/nepi_system_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_system_aliases
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

    sudo rm /root/.bashrc
    sudo cp /home/${CONFIG_USER}/.bashrc /root/.bashrc
    sudo chmod 0644 /root/.bashrc

    sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.bashrc
    sudo chmod 0664 /home/${CONFIG_USER}/.bashrc

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




################
echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0644 /home/${CONFIG_USER}/.profile



