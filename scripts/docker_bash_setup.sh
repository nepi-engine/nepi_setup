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
RESOURCES_FOLDER==$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=$(dirname "${RESOURCES_FOLDER}")/bash/nepi_bash_utils
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


echo "Updating user bashrc files"
BASHRC=/home/${CONFIG_USER}/.bashrc

file=$BASHRC
bfile=${BASHRC}.org


if [[ ! -f "$file"  ]]; then
    cp /etc/skel/.bashrc $file
fi

if [[ ! -f $bfile ]]; then
    path_backup $file $bfile
fi

if [[ -f $bfile ]]; then
   cp $bfile $file 
fi

if [[ -n $NEPI_STATIC_IP ]]; then
    nepi_ip="${NEPI_STATIC_IP%%/*}"
else
    nepi_ip=192.168.179.103
fi
if ! is_valid_ipv4 $nepi_ip; then
    nepi_ip=192.168.179.103
fi

if [[ -n "$NEPI_DEVICE_ID" ]]; then
    NEPI_DEVICE_ID=device1
fi

if ! is_valid_did $NEPI_DEVICE_ID; then
    NEPI_DEVICE_ID=device1
fi



if grep -qnw $BASHRC -e "##### System Config #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### System Config #####' | sudo tee -a $BASHRC
    echo '#export CMAKE_POLICY_VERSION_MINIMUM=3.5' | sudo tee -a $BASHRC
    echo 'export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}' | sudo tee -a $BASHRC

    echo 'if [[ -f "/usr/lib/aarch64-linux-gnu/libgomp.so.1" ]]; then' | sudo tee -a $BASHRC
    echo '   LIB1=/usr/lib/aarch64-linux-gnu/libgomp.so.1' | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC

    echo  | sudo tee -a $BASHRC
    echo 'if [[ -f "/usr/local/lib/libOpen3D.so" ]]; then' | sudo tee -a $BASHRC
    echo '  LIB2=/usr/local/lib/libOpen3D.so' | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC

    echo 'export LD_PRELOAD="$LIB1 $LIB2"' | sudo tee -a $BASHRC
fi

# UPDATE NEPI Python Vesion
pyver=$(python3 --version | awk '{print $2}')
if [[ -n "$pyver" ]]; then
    pyver="${pyver%.*}"
else
    pyver=3
fi
NEPI_PYTHON=$pyver

if grep -qnw $BASHRC -e "##### Python Config #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### Python Config #####' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH='${NEPI_ENGINE}'/etc:${PYTHONPATH}' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH='${NEPI_ENGINE}'/lib/nepi_drivers:${PYTHONPATH}' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH=/usr/local/lib/python'${NEPI_PYTHON}'/site-packages:${PYTHONPATH}' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH=/home/'${CONFIG_USER}'/.local/lib/python'${NEPI_PYTHON}'/site-packages:${PYTHONPATH}' | sudo tee -a $BASHRC
    if [[ "$CONFIG_USER" == 'nepi' ]]; then
        echo 'export SETUPTOOLS_USE_DISTUTILS=stdlib' | sudo tee -a $BASHRC
    fi
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

    if grep -qnw $BASHRC -e "##### CUDA SETUP #####" ; then
        : #echo "Already Done"
    else
        echo ' ' | sudo tee -a $BASHRC
        echo '##### CUDA SETUP #####' | sudo tee -a $BASHRC
        echo 'export CUDA_PATH='${CUDA_HOME} | sudo tee -a $BASHRC
        echo 'export CUDA_HOME='${CUDA_HOME} | sudo tee -a $BASHRC
        echo 'export CUPY_NVCC_GENERATE_CODE=current' | sudo tee -a $BASHRC
        echo 'export LD_LIBRARY_PATH='${CUDA_HOME}'/lib64:$LD_LIBRARY_PATH' | sudo tee -a $BASHRC
        echo 'export PATH='${CUDA_HOME}'/bin:${PATH}' | sudo tee -a $BASHRC
        echo 'export CUDA_VISIBLE_DEVICES=0' | sudo tee -a $BASHRC
    fi
fi

systemctl&> /dev/null
res=$?

if [[ "$?" -eq 0  && "$CONFIG_USER" == 'nepi' ]]; then
    export NEPI_IN_CONTAINER=0
else
    export NEPI_IN_CONTAINER=1
fi


# Add NEPI SETTINGS
if grep -qnw $BASHRC -e "##### NEPI SETTINGS #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo 'export USER='${CONFIG_USER} | sudo tee -a $BASHRC
    echo 'export CONFIG_USER='${CONFIG_USER} | sudo tee -a $BASHRC
    echo 'export NEPI_HOST_USER='${CONFIG_USER} | sudo tee -a $BASHRC
    echo 'export NEPI_PYTHON='${NEPI_PYTHON} | sudo tee -a $BASHRC
    echo '' | sudo tee -a $BASHRC
    echo '##### NEPI SETTINGS #####' | sudo tee -a $BASHRC
    echo 'export NEPI_IP='${nepi_ip} | sudo tee -a $BASHRC
    echo 'export NEPI_DEVICE_ID='${NEPI_DEVICE_ID} | sudo tee -a $BASHRC
    echo 'export NEPI_RECOVERY_DEVICE_ID=device1' | sudo tee -a $BASHRC
    echo 'export NEPI_RECOVERY_IP=192.168.179.103' | sudo tee -a $BASHRC
    echo 'export NEPI_IN_CONTAINER='${NEPI_IN_CONTAINER} | sudo tee -a $BASHRC
fi



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
echo "Installing NEPI aliases file ${NEPI_ALIASES_DEST} "

NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_docker_aliases
NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_docker_aliases

if [ -f "$NEPI_ALIASES_DEST" ]; then
    sudo rm $NEPI_ALIASES_DEST
fi
sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST
sudo chmod 775 $NEPI_ALIASES_DEST


# Add NEPI Aliases
if grep -qnw $BASHRC -e "##### Source NEPI Aliases #####" ; then
    if grep -qnw $BASHRC -e "NEPI_ALIASES_FILE=" ; then
        update_text_value $BASHRC "NEPI_ALIASES_FILE=" "NEPI_ALIASES_FILE='${NEPI_ALIASES_DEST}"
    fi
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### Source NEPI Aliases #####' | sudo tee -a $BASHRC
    echo 'NEPI_ALIASES_FILE='${NEPI_ALIASES_DEST} | sudo tee -a $BASHRC
    echo 'if [ -f ${NEPI_ALIASES_FILE} ]; then' | sudo tee -a $BASHRC
    echo '    . ${NEPI_ALIASES_FILE}' | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC
fi

sudo rm /root/.bashrc
sudo cp /home/${CONFIG_USER}/.bashrc /root/.bashrc
sudo chmod 0644 /root/.bashrc

sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.bashrc
sudo chmod 0664 /home/${CONFIG_USER}/.bashrc

################
echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0644 /home/${CONFIG_USER}/.profile

if [[ ! -d /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages ]]; then
    sudo mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages
fi
#echo "Udating user python permissions"
sudo chmod 755 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages

###############
echo "Fixing other system folder permissions"
if [[ ! -d "/media/${CONFIG_USER}" ]]; then
    sudo mkdir -p "/media/${CONFIG_USER}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /media/${CONFIG_USER}

echo ""
echo "Sourcing updated bash files"
source $BASHRC
wait

echo ""
echo "########################"
echo "NEPI Docker Bash Setup Complete"
echo "########################"
echo ""

