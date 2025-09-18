#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs the NEPI Engine File System installation


echo "########################"
echo "NEPI DOCKER USER SETUP"
echo "########################"


CONFIG_USER=nepihost
if [[ "$USER" != "$CONFIG_USER" ]]; then
    echo "This script must be run by user account ${CONFIG_USER}."
    echo "Log in as ${CONFIG_USER} and run again"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
source $(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils 

# Load System Config File
source $(dirname ${SCRIPT_FOLDER})/config/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_CONFIG_FILE}"
    exit 1
fi


echo ""
echo "Setting up nepi user account: ${CONFIG_USER}"


if grep -q $CONFIG_USER /etc/group;  then
        echo "group exists"
else
        echo "group $CONFIG_USER does not exist, creating"
        addgroup ${CONFIG_USER}
fi


#echo "${CONFIG_USER} ALL=(ALL:ALL) ALL" >> /etc/sudoers


echo "Update Password"
sudo passwd $CONFIG_USER 

# Add nepi CONFIG_USER to dialout group to allow non-serial connections
sudo adduser ${CONFIG_USER} dialout

#or //https://arduino.stackexchange.com/questions/74714/arduino-dev-ttyusb0-permission-denied-even-when-user-added-to-group-dialout-o
#Add your standard user to the group "dialout'
sudo usermod -a -G dialout ${CONFIG_USER}
#Add your standard user to the group "tty"
sudo usermod -a -G tty ${CONFIG_USER}

# Create USER python folder
mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages

# Clear the Desktop
sudo rm /home/${CONFIG_USER}/Desktop/*

echo "User Account Setup Complete"
echo ""



