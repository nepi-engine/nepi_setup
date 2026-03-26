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
# echo "LITE_INSTALL=${LITE_INSTALL}"

sudo -v

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


if [[ $LITE_INSTALL -eq 0 ]]; then
    if [[ "$CONFIG_USER" != 'nepihost' ]]; then
        echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepihost'"
        return
    fi
fi

sudo -v


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    return 
fi

echo "########################"
echo "NEPI DOCKER ENVIRONMENT SETUP"
echo "########################"


####################################
# Run NEPI Bash Setup Script


script_file=nepi_bash_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi


####################################
# Run NEPI Folder Setup Script

script_file=nepi_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi

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
    return 
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

sudo add-apt-repository ppa:rmescandon/yq -y

sudo apt update

sudo apt install apt-utils -y
sudo apt install yq -y
sudo apt install git -y
sudo apt install gitk -y
sudo apt install htop -y
sudo apt install ncdu -y
sudo apt install snap -y  2>/dev/null 
if is_valid_jetson; then
    snap download snapd --revision=24724
    sudo snap ack snapd_24724.assert
    sudo snap install snapd_24724.snap
    sudo sudo snap refresh --hold snapd

fi

sudo apt install curl -y
sudo apt install gparted -y

sudo apt install python-is-python3 -y
sudo apt install python3-venv python3-pip -y


if command -v mount.cifs &>/dev/null; then
    echo "cifs-utils is installed."
else
    echo "Installing cifs-utils"
    sudo apt install cifs-utils
fi

echo "######################################"
echo "Installing NEPI python packages"
echo "######################################"
sudo -H python3 -m pip install --no-input cryptography
sudo -H python3 -m pip install --no-input python-dotenv

if [[ "$LITE_INSTALL" -eq 0 ]]; then
    echo "######################################"
    echo "Installing NEPI Managed Services Apps"
    echo "######################################"




    echo "############"
    echo "Installing Hostname Apps"
    echo ""
    sudo apt install hostapd -y # WiFi access point setup

    echo "############"
    echo "Installing Time Apps"
    echo ""
    echo "Installing NEPI TIME Management Software"
    sudo apt-get install chrony -y

    echo "############"
    echo "Installing SSH Apps"
    echo ""

    echo "Installing NEPI SSH Management Software"

    echo "Installing NEPI SSH Management Software"
    #sudo apt install --reinstall openssh-server

    sudo apt-get remove --purge openssh-server -y
    sudo apt-get autoclean 
    sudo apt-get install --fix-broken -y
    sudo apt-get install openssh-server -y
    if [[ ! -f "/run/sshd" ]]; then
        sudo mkdir "/run/sshd"
    fi
    sudo chmod 0775 /run/sshd
    sudo chown root:root /run/sshd

    echo "############"
    echo "Installing Network Apps"
    echo ""

    #sudo apt install netplan.io -y
    sudo apt install ifupdown -y
    sudo apt install net-tools -y 
    sudo apt install iproute2 -y
    sudo apt install isc-dhcp-client -y
    sudo apt install wpasupplicant -y
    sudo apt install nmap -y
    sudo apt install trash-cli -y
    sudo apt install nano -y


    echo "############"
    echo "Installing Shared Drive Apps"
    echo ""
    sudo apt install samba -y
    sudo apt install smbclient -y

    # echo "############"
    # echo "Installing Data Annotation Software"
    # echo ""
    # script_file=dev_ai_train_setup.sh
    # script_path=${SCRIPT_FOLDER}/${script_file}
    # source $script_path


    echo "############"
    echo "Installing USB Drive Auto Mount Software"
    echo ""
    sudo apt install usbmount -y


fi 



if is_valid_jetson; then
    echo "######################################"
    echo "Installing Jetson Apps"
    echo "######################################"
    sudo apt install nvidia-jetpack-dev -y
fi


sudo apt-get update
sudo apt install --fix-broken





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

echo ""
echo "######################################"
echo "NEPI ARCHITECTURE: ${NEPI_ARCH}"
echo "######################################"
echo ""

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
    echo ""
    echo "######################################"
    echo "Installing Docker"
    echo "######################################"
    echo ""
    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0775 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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

echo ""
echo "Enabling Docker Service"
sudo systemctl daemon-reload
sudo systemctl start docker.socket
sudo systemctl start docker

sudo apt-get update
sudo apt-get install --fix-broken -y


echo "######################################"
echo "Installing NEPI required python packages"
echo "######################################"





if [[ -n "$DISPLAY" ]]; then
    echo "########################"
    echo "Installing Desktop Utility Apps"
    echo "########################"
    sudo apt update

    #######
    echo ""
    if command -v mdview &>/dev/null; then
        echo "mdview is installed."
    else
        echo "Installing mdview"
        sudo snap install mdview
    fi

    if command -v chromium-browser &>/dev/null; then
        echo "Chromium is installed."
    else
        # Check for an alternative common name if the first one fails
        if command -v chromium &>/dev/null; then
            echo "Chromium is installed."
        else
            echo "Installing Chromium Browser"
            #sudo snap remove --purge chromium
            sudo snap install chromium
            #sudo apt install chromium-browser -y
            #chromium-browser --disable-features=DnsOverHttps
        fi
    fi

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

    if command -v mount.cifs &>/dev/null; then
        echo "cifs-utils is installed."
    else
        echo "Installing cifs-utils"
        sudo apt install cifs-utils
    fi
fi





######
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


#sudo rm /var/lib/apt/lists/* -vf
sudo apt-get clean
sudo apt-get update
sudo apt update
sudo apt-get install --fix-broken -y
sudo rm -r ~/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r ~/.local/share/Trash/files/ 2>/dev/null
#sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null




##################################
echo ""
echo 'NEPI Docker Environment Setup Complete'
##################################

if [[ "$LITE_INSTALL" -eq 0 ]]; then
    echo ""
    echo "*** REBOOT YOUR DEVICE ***"
fi
