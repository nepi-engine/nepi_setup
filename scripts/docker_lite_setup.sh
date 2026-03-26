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


# NEPI Docker Lite Installation script
export LITE_INSTALL=1

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


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
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



echo ""
echo "########################"
echo "NEPI Docker Lite User Setup"
echo "########################"
echo ""
echo "###################################"
echo "Setting NEPI CONFIG USER: ${CONFIG_USER}"
echo "###################################"
echo ""
echo "Configuring NEPI Base User account $CONFIG_USER"
sudo usermod -aG sudo $CONFIG_USER >/dev/null 2>&1
sudo adduser ${CONFIG_USER} dialout
sudo usermod -aG dialout ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG tty ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG i2c ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG video ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG docker ${CONFIG_USER} >/dev/null 2>&1
echo $CONFIG_USER
sudo chmod -R 0777 /tmp/nepi
echo ""
echo "########################"
echo "NEPI User Account Setup Complete"
echo "########################"
echo ""



####################################
# Run NEPI Bash Setup Script

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_bash_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi

source /home/${CONFIG_USER}/.bashrc



echo ""
echo "########################"
echo "NEPI Lite FOLDERS SETUP"
echo "########################"
echo ""

ETC_SCRIPTS_FOLDER=$(dirname "${SCRIPT_FOLDER}")/resources/etc/scripts
script_file=check_config_folders.sh
script_path=${ETC_SCRIPTS_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo "Running ${script_file} script"
	source $script_path
	wait
fi

echo ""
echo "########################"
echo "NEPI Lite Folders Setup Complete"
echo "########################"
echo ""

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

echo "######################################"
echo "Installing NEPI python packages"
echo "######################################"
sudo -H python3 -m pip install --no-input cryptography
sudo -H python3 -m pip install --no-input python-dotenv

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


echo ""
echo "######################################"
echo "NEPI ARCHITECTURE: ${NEPI_ARCH}"
echo "######################################"
echo ""


echo "Checking for Docker software"
if command -v docker &>/dev/null; then
    # echo "Removing Docker existing docker installation."
    # sudo apt remove docker -y
    echo "Docker Installed"
else

        if [[ "$NEPI_ARCH" == 'arm64' ]]; then

            # https://docs.docker.com/engine/install/ubuntu/
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



if [[ -n "$DISPLAY" ]]; then
    echo ""
    echo "########################"
    echo "Installing Desktop Utility Apps"
    echo "########################"

    sudo apt update
    echo ""
    echo "Installing mdview"
    sudo snap install mdview

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

echo ""
echo "########################"
echo "Cleaning File System"
echo "########################"
echo ""

sudo apt-get clean
sudo apt-get update
sudo apt update
sudo apt-get install --fix-broken -y
sudo rm -r ~/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r ~/.local/share/Trash/files/ 2>/dev/null
#sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null

echo ""
echo "########################"
echo "NEPI Docker Lite Enviorment Setup Complete"
echo "########################"
echo ""

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    return 
fi

############################################################################################


echo ""
echo "########################"
echo "NEPI LITE Folders SETUP"
echo "########################"
echo ""

####################################
# Run NEPI Files Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi

echo ""
echo "########################"
echo "NEPI LITE FILES SETUP"
echo "########################"
echo ""

####################################
# Run NEPI Files Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_files_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi



####################################
# Run NEPI Image Init Setup Script
if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepiadmin' && ${CONFIG_USER} != 'nepihost' ]]; then
    export NEPI_HOST_USER=$CONFIG_USER
    update_yaml_value "NEPI_HOST_USER" $NEPI_HOST_USER $SYSTEM_SYS_CONFIG_FILE
    NEPI_HOST_PW="encrypted"
    if [[ ${NEPI_HOST_USER} == "nepihost" ]]; then
        update_yaml_value "NEPI_HOST_PW" $NEPI_HOST_PW $SYSTEM_SYS_CONFIG_FILE
    fi
fi

echo ""
echo "########################"
echo "NEPI LITE CONFIG SETUP"
echo "########################"
echo ""

####################################
# Run NEPI Config Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=nepi_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi

echo ""
echo "########################"
echo "NEPI LITE CONFIG SETUP Complete"
echo "########################"
echo ""

