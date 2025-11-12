#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file runs setup script debug fixes 


####################
# Init Variables

CONFIG_USER=$(id -un 1000)
if [[ "$CONFIG_USER" != 'nepi' && "$CONFIG_USER" != 'nepihost' ]]; then
    echo "This script must be run by user 'nepi' or 'nepihost'"
else


    if [[ -z "$SCRIPT_FOLDER" ]]; then
        SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
    fi

    ####################
    # Run Fixes

    ##################################
    # Install NEPI Managed Services Apps
    ###################################
    sudo apt install hostapd -y # WiFi access point setup


    echo "Installing NEPI NETWORK Management Software"
    sudo apt install netplan.io -y
    sudo apt install ifupdown -y 
    sudo apt install net-tools -y 
    sudo apt install iproute2 -y
    sudo apt install isc-dhcp-client -y
    sudo apt install wpasupplicant -y
    sudo apt install iputils-ping -y

    echo "Installing NEPI TIME Management Software"
    sudo apt-get install chrony -y



    echo "Installing NEPI SSH Management Software"

    echo "Installing NEPI SSH Management Software"
    #sudo apt install --reinstall openssh-server -y

    sudo apt-get remove --purge openssh-server -y
    sudo apt-get update
    sudo apt --fix-broken install
    sudo apt-get install openssh-server -y
    if [[ ! -f "/run/sshd" ]]; then
        sudo mkdir "/run/sshd"
    fi
    sudo chmod 0755 /run/sshd
    sudo chown root:root /run/sshd



    sudo apt-get update
    sudo apt --fix-broken install

fi