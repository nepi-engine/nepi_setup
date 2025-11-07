#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This file sets up a pc side nepi develoment environment

sudo -v

echo "########################"
echo "NEPI BASH SETUP"
echo "########################"

echo "Running Intitialization Scripts"

export CONFIG_USER=nepihost

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


#############
# Add nepi aliases to bashrc
echo "Updating NEPI aliases file"
BASHRC=/home/${CONFIG_USER}/.bashrc

echo "Installing NEPI utils file"
NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
NEPI_UTILS_DEST=/home/${CONFIG_USER}/.nepi_bash_utils
echo "Installing NEPI utils file ${NEPI_UTILS_DEST} "
if [ -f "$NEPI_UTILS_DEST" ]; then
    sudo rm $NEPI_UTILS_DEST
fi
sudo cp $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_DEST
sudo chmod 755 $NEPI_UTILS_DEST

#sudo cp /home/${CONFIG_USER}/.nepi_bash_utils /root/.nepi_bash_utils


NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_docker_aliases
NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_docker_aliases
echo "Installing NEPI aliases file ${NEPI_ALIASES_DEST} "
if [ -f "$NEPI_ALIASES_DEST" ]; then
    sudo rm $NEPI_ALIASES_DEST
fi
sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST
sudo chmod 755 $NEPI_ALIASES_DEST

#sudo cp /home/${CONFIG_USER}/.nepi_docker_aliases /root/.nepi_docker_aliases

#############
# Create USER python folder
mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages

#############
echo "Updating user bashrc files"
### Backup CONFIG_USER BASHRC file if needed
file=$BASHRC
cp /etc/skel/.bashrc /home/${CONFIG_USER}/

if [[ -z "$NEPI_IP" ]]; then
    NEPI_IP=192.168.179.103
fi

if [[ -z "$NEPI_DEVICE_ID" ]]; then
    NEPI_DEVICE_ID=device1
fi

if [[ -z "$NEPI_IN_CONTAINER" ]]; then
    NEPI_IN_CONTAINER=1
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


echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0664 /home/${CONFIG_USER}/.profile


echo "Fixing other system folder permissions"
if [[ ! -d "/media/${CONFIG_USER}" ]]; then
    sudo mkdir -p "/media/${CONFIG_USER}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /media/${CONFIG_USER}


# Copy instructions to desktop
instr_file=${SOURCE_INSTR_PATH}/NEPI_DOCKER_HOST_SETUP.md
sudo cp -p $instr_file /home/${CONFIG_USER}/Desktop/

#################################
echo ""
echo "Sourcing updated bash files"
source $BASHRC
wait


echo "########################"
echo "NEPI DOCKER BASH SETUP COMPLETE"
echo "########################"
echo ""
