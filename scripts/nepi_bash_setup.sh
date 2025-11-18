#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up nepi bash aliases and util functions

sudo -v

export CONFIG_USER=${USER}


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



echo "########################"
echo "NEPI BASH SETUP"
echo "########################"

##############

echo "Installing NEPI Utils files"

NEPI_UTILS_FILE_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
NEPI_UTILS_FILE_DEST=/home/${CONFIG_USER}/.nepi_bash_utils

sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_FILE_SOURCE
sudo chmod 755 $NEPI_UTILS_FILE_SOURCE
sudo cp -p $NEPI_UTILS_FILE_SOURCE $NEPI_UTILS_FILE_DEST

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_utils
NEPI_UTILS_DEST=/home/${CONFIG_USER}

sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_SOURCE
sudo chmod 755 $NEPI_UTILS_SOURCE
sudo cp -R -p $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST/



##############
echo "Installing NEPI aliases file ${NEPI_ALIASES_DEST} "

if [[ "$CONFIG_USER" != 'nepi' ]]; then
    NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_docker_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_docker_aliases
else
    NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_system_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_system_aliases
fi 


if [ -f "$NEPI_ALIASES_DEST" ]; then
    sudo rm $NEPI_ALIASES_DEST
fi
sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST
sudo chmod 755 $NEPI_ALIASES_DEST




#############
echo "Updating user bashrc files"
BASHRC=/home/${CONFIG_USER}/.bashrc

rm $BASHRC
cp /etc/skel/.bashrc $BASHRC

if [[ -z "$NEPI_IP" ]]; then
    NEPI_IP=192.168.179.103
fi
if ! is_valid_ipv4 $NEPI_IP; then
    NEPI_IP=192.168.179.103
fi



if [[ -z "$NEPI_DEVICE_ID" ]]; then
    NEPI_DEVICE_ID=device1
fi
if ! is_valid_did $NEPI_DEVICE_ID; then
    NEPI_DEVICE_ID=device1
fi

systemctl&> /dev/null
if [[ "$?" -eq 1  && "$CONFIG_USER" == 'nepihost' ]]; then
    export NEPI_IN_CONTAINER=1
else
    export NEPI_IN_CONTAINER=0
fi



if grep -qnw $BASHRC -e "##### System Config #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### System Config #####' | sudo tee -a $BASHRC
    echo '#export CMAKE_POLICY_VERSION_MINIMUM=3.5' | sudo tee -a $BASHRC
    echo 'export SETUPTOOLS_USE_DISTUTILS=stdlib' | sudo tee -a $BASHRC
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


# Add NEPI SETTINGS
echo ' ' | sudo tee -a $BASHRC
echo '##### NEPI SETTINGS #####' | sudo tee -a $BASHRC
echo 'export NEPI_IP='${NEPI_IP} | sudo tee -a $BASHRC
echo 'export NEPI_DEVICE_ID='${NEPI_DEVICE_ID} | sudo tee -a $BASHRC
echo 'export NEPI_RECOVERY_DEVICE_ID=device1' | sudo tee -a $BASHRC
echo 'export NEPI_RECOVERY_IP=192.168.179.103' | sudo tee -a $BASHRC
echo 'export NEPI_IN_CONTAINER='${NEPI_IN_CONTAINER} | sudo tee -a $BASHRC



# Add NEPI Aliases
echo ' ' | sudo tee -a $BASHRC
echo '##### Source NEPI Aliases #####' | sudo tee -a $BASHRC
echo 'if [ -f '${NEPI_ALIASES_DEST}' ]; then' | sudo tee -a $BASHRC
echo '    . '${NEPI_ALIASES_DEST} | sudo tee -a $BASHRC
echo 'fi' | sudo tee -a $BASHRC


sudo rm /root/.bashrc
sudo cp /home/${CONFIG_USER}/.bashrc /root/.bashrc
sudo chmod 0644 /root/.bashrc

sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.bashrc
sudo chmod 0664 /home/${CONFIG_USER}/.bashrc

################
echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0664 /home/${CONFIG_USER}/.profile

sudo mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages
sudo chmod 0664 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages


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


