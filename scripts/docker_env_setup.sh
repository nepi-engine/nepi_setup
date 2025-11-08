#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs NEPI Docker required software packages

sudo -v

CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
   echo "Current user is ${CONFIG_USER}. This scripts must be run as nepihost user."
   exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    exit 1
fi

echo "########################"
echo "NEPI DOCKER ENVIRONMENT SETUP"
echo "########################"



##########################
NEPI_ARCH=unknown
if is_valid_jetson; then
    NEPI_ARCH=arm64
elif is_valid_arm64; then
    NEPI_ARCH=arm64
elif is_valid_amd64; then
    NEPI_ARCH=amd64
else
    arch_val=$(uname -m)
    echo "Arch ${arch_val} not supported yet"
    exit 1
fi


#################################
# Disable Apport Error Messaging

systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    SYSTEMD_SERVICE_PATH=/etc/systemd/system

    echo ""
    echo "########"
    echo "Disable apport to avoid crash reports on a display"
    sudo systemctl disable apport
    sudo systemctl stop apport
fi

#################################
# Install Software Requirments

echo ""
echo "######################################"
echo "Installing NEPI required software packages"
echo "######################################"
echo ""

sudo add-apt-repository ppa:rmescandon/yq -y
sudo add-apt-repository ppa:apt-fast/stable -y
sudo apt update

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install aria2
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install apt-fast


sudo apt-fast install -y yq git gitk htop ncdu snap curl python3-pip \
hostapd \ 
chrony \
ifupdown \
net-tools \ 
iproute2 \
isc-dhcp-client \
wpasupplicant \
nmap \
samba \
smbclient 

#sudo apt install usbmount -y
#sudo apt install netplan.io -y

echo ""
echo "######################################"
echo "Installing SSH Apps"
echo "######################################"
echo ""

echo "Installing NEPI SSH Management Software"
#sudo apt install --reinstall openssh-server

sudo apt-get remove --purge openssh-server -y
sudo apt-get autoclean 
sudo apt-get install --fix-broken -y
sudo apt-get install openssh-server -y
if [[ ! -f "/run/sshd" ]]; then
    sudo mkdir "/run/sshd"
fi
sudo chmod 0755 /run/sshd
sudo chown root:root /run/sshd

sudo apt-get update
sudo apt  install --fix-broken


#################################
# Install docker if not present

echo ""
echo "######################################"
echo "Installing Docker Required Software"
echo "######################################"
echo ""

echo "Stopping Docker Service"
SERVICE_NAME=docker
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping ${SERVICE_NAME} Service"
    sudo systemctl stop $SERVICE_NAME
fi

SERVICE_NAME=docker.socket
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping ${SERVICE_NAME} Service"
    sudo systemctl stop $SERVICE_NAME
fi

if [[ "$NEPI_ARCH" == 'arm64' ]]; then
    echo "Checking for Docker software"
    if command -v docker &>/dev/null; then
        echo "Removing Docker existing docker installation."
        sudo apt remove docker -y
    fi
    # https://docs.docker.com/engine/install/ubuntu/
    echo ""
    echo ""
    echo "######################################"
    echo "Installing Docker"
    echo "######################################"
    echo ""
    # Update Package Lists and Install Prerequisites.
    sudo apt update
    sudo 
    echo 1
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common 
    echo 2
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    echo 3
    sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable"
    sudo apt update
    echo 4
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo docker info
    docker compose version
elif [[ "$NEPI_ARCH" == 'amd64' ]]; then
    sudo apt install docker -y
else 
    arch_val=$(uname -m)
    echo "Arch ${arch_val} not supported yet"
fi



sudo apt-get update
sudo apt-get install --fix-broken -y

#################################
# Install NVIDIA Toolkit
if is_valid_cuda; then
    echo ""
    echo "######################################"
    echo "Installing NVIDIA Toolkit "
    echo "######################################"
    echo ""

    if dpkg --get-selections | grep nvidia-container-toolkit; then


        # Install nvidia toolkit
        #https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        sudo apt-get update

        export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
        sudo apt-get install --fix-broken -y \
            nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
            nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
            libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
            libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

    fi

fi

sudo apt-get update
sudo apt-get install --fix-broken -y


echo "######################################"
echo "Installing NEPI required python packages"
echo "######################################"



echo "########################"
echo "Installing Utility Apps"
echo "########################"

echo ""
echo "Installing Chromium Browser"
sudo snap remove --purge chromium
sudo snap install chromium
#sudo apt install chromium-browser -y
#chromium-browser --disable-features=DnsOverHttps

if command -v code &> /dev/null; then
    echo "Visual Studio Code is installed and accessible."
else
    echo ""
    echo "Installing visual code editor"
    
    if [[ "$NEPI_ARCH" == 'arm64' ]]; then
        curl -L https://aka.ms/linux-arm64-deb > code_arm64.deb
        sudo apt install ./code_arm64.deb
        wait
        sudo rm code_arm64.deb
    elif [[ "$NEPI_ARCH" == 'amd64' ]]; then
        sudo snap install code --channel=edge --classic
    fi

fi



echo ""
echo "########################"
echo "Cleaning File System"
echo "########################"

sudo apt update
sudo apt-get install --fix-broken -y
sudo rm -r ~/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r ~/.local/share/Trash/files/ 2>/dev/null
sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null


####################################
script_file=docker_bash_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
fi

##################################
echo ""
echo 'NEPI Docker Environment Setup Complete'
##################################

echo ""
echo "*** REBOOT YOUR DEVICE ***"
