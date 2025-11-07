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

echo "########################"
echo "NEPI BASH SETUP"
echo "########################"

echo "Running Intitialization Scripts"

export CONFIG_USER=nepi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

. ${SCRIPT_FOLDER}/script_setup.sh
if [[ "$?" -ne 0 ]]; then
    echo "Script Setup Failed. Exiting"
    exit 1
fi 


#####################################
# Add nepi aliases to bashrc
echo "Updating NEPI aliases file"


# Update Bashrc and Nepi bash files
NEPI_UTILS_SOURCE=$(dirname "$(pwd)")/resources/bash/nepi_bash_utils
NEPI_UTILS_DEST=/home/${CONFIG_USER}/.nepi_bash_utils
echo "Installing NEPI utils file ${NEPI_UTILS_DEST} "
if [ -f "$NEPI_UTILS_DEST" ]; then
    sudo rm $NEPI_UTILS_DEST
fi
sudo cp $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_DEST


NEPI_ALIASES_SOURCE=$(dirname "$(pwd)")/resources/bash/nepi_system_aliases
NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_system_aliases

echo ""
echo "Populating System Folders from ${NEPI_ALIASES_SOURCE}"
echo ""
echo "Installing NEPI aliases file to ${NEPI_ALIASES_DEST} "
if [ -f "$NEPI_ALIASES_DEST" ]; then
    sudo rm ${NEPI_ALIASES_DEST}
fi
sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST


#############
# Create USER python folder
mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages


#############
echo "Updating user bashrc files"

BASHRC=/home/${CONFIG_USER}/.bashrc

rm /home/${CONFIG_USER}/.bashrc
cp /etc/skel/.bashrc /home/${CONFIG_USER}/.bashrc

if grep -qnw $BASHRC -e "##### System Config #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### System Config #####' | sudo tee -a $BASHRC
    echo '#export CMAKE_POLICY_VERSION_MINIMUM=3.5' | sudo tee -a $BASHRC
    echo 'export SETUPTOOLS_USE_DISTUTILS=stdlib' | sudo tee -a $BASHRC
    echo 'export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}' | sudo tee -a $BASHRC
    echo 'if [[ -f "/usr/local/lib/libOpen3D.so" ]]; then' | sudo tee -a $BASHRC
    echo '  export LD_PRELOAD=/usr/local/lib/libOpen3D.so' | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC
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


# UPDATE CUDA Info
cudaver=$(is_valid_cuda)
if [[ -n "$cudaver" ]]; then
    cudaver="${cudaver}"
else
    cudaver=0
fi
NEPI_CUDA_VERSION=$cudaver

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
    fi
fi

# Add additional user bashrc statements
# Add NEPI SETTINGS
echo ' ' | sudo tee -a $BASHRC
echo '##### NEPI SETTINGS #####' | sudo tee -a $BASHRC
echo 'export NEPI_IP='${NEPI_IP} | sudo tee -a $BASHRC
echo 'export NEPI_DEVICE_ID='${NEPI_DEVICE_ID} | sudo tee -a $BASHRC
echo 'export NEPI_RECOVERY_DEVICE_ID=device1' | sudo tee -a $BASHRC
echo 'export NEPI_RECOVERY_IP=192.168.179.103' | sudo tee -a $BASHRC
echo 'export NEPI_IN_CONTAINER='${NEPI_IN_CONTAINER} | sudo tee -a $BASHRC



if grep -qnw $BASHRC -e "##### Source NEPI Aliases #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### Source NEPI Aliases #####' | sudo tee -a $BASHRC
    echo 'if [ -f '${NEPI_ALIASES_DEST}' ]; then' | sudo tee -a $BASHRC
    echo '    . '${NEPI_ALIASES_DEST} | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC
fi


sudo rm /root/.bashrc
sudo cp /home/${CONFIG_USER}/.bashrc /root/.bashrc
sudo chmod 0644 /root/.bashrc


sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.bashrc
sudo chmod 0664 /home/${CONFIG_USER}/.bashrc


echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0664 /home/${CONFIG_USER}/.profile

# Copy files to nepiadmin home
sudo cp /home/${CONFIG_USER}/.* /home/${NEPI_ADMIN}/ >/dev/null 2>&1


echo ""
echo "Sourcing updated bash files"
source $BASHRC
wait


##################################
echo "Fixing other system folder permissions"
if [[ ! -d "/media/${CONFIG_USER}" ]]; then
    sudo mkdir -p "/media/${CONFIG_USER}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /media/${CONFIG_USER}

echo " "
echo "################################# "
echo "NEPI Bash Aliases Setup Complete"
echo "################################# "
echo " "
echo "To see a list of NEPI command line shortcuts run: nepihelp"



