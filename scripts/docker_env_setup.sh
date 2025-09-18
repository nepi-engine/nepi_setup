#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file configigues an installed NEPI File System


echo "########################"
echo "NEPI DOCKER ENVIRONMENT SETUP"
echo "########################"

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
source $(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils 

# Load System Config File
source $(dirname ${SCRIPT_FOLDER})/config/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_CONFIG_FILE}"
    exit 1
fi


# Check User Account
CONFIG_USER=$NEPI_HOST_USER
if [[ "$USER" != "$CONFIG_USER" ]]; then
    echo "This script must be run by user account ${CONFIG_USER}."
    echo "Log in as ${CONFIG_USER} and run again"
    exit 2
fi


#################################
# Install Software Requirments

# echo ""
echo "######################################"
# echo "Installing NEPI required software packages"
echo "######################################"
# sudo apt update
# sudo apt install vim-gtk3 -y
# sudo apt install nmap -y
# sudo apt-get install -y lsyncd rsync
# sudo apt install git -y
# sudo apt install gitk -y
# sudo snap install code --channel=edge --classic
# sudo apt install htop -y
# sudo apt install snap -y
# sudo apt install chromium-browser
# sudo add-apt-repository ppa:rmescandon/yq -y
# sudo apt update
# sudo apt install yq -y


#################################
# Install docker if not present
NEPI_ARCH="${NEPI_HW_TYPE,,}"
if [[ "$NEPI_HW_TYPE" == 'JETSON' ]]; then
    NEPI_ARCH='arm64'
fi

if [[ "$NEPI_MANAGES_DOCKER" -eq 1 ]]; then
    if [[ $NEPI_ARCH -eq arm64 || $NEPI_ARCH -eq amd ]]; then
        # https://docs.docker.com/engine/install/ubuntu/
        echo ""
        echo ""
        echo "######################################"
        echo "Installing Docker & Docker Compose"
        echo "######################################"
        # Update Package Lists and Install Prerequisites.
        sudo apt update
        echo 1
        sudo apt install apt-transport-https ca-certificates curl software-properties-common
        echo 2
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        echo 3
        sudo add-apt-repository "deb [arch=${NEPI_ARCH}] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        echo 4
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo docker info
        docker compose version
    elif [ $NEPI_ARCH -eq rpi ]; then
        echo "RPI not supported yet"
        exit 1
    fi
    # Setup Docker Services
    echo "Enabling Docker Service"
    sudo systemctl enable docker



    echo "Stopping Docker Service"
    sudo systemctl stop docker
    sudo systemctl stop docker.socket

    #Then reload and restart docker
    echo "Restarting Docker Service"
    sudo systemctl daemon-reload
    sudo systemctl start docker.socket
    sudo systemctl start docker
    #sudo systemctl status docker

    ###########

        # Set docker service root location
        #https://stackoverflow.com/questions/44010124/where-does-docker-store-its-temp-files-during-extraction
        # https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169
        echo ""
        echo "######################################"
        echo "Setting Docker File Path to ${NEPI_DOCKER}"
        echo "######################################"
        ## Update docker file
        echo "Updating docker file /etc/default/docker"
        FILE=/etc/default/docker
        UPDATE="DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4  -g ${NEPI_DOCKER}\""
        echo $UPDATE
        KEY=DOCKER_OPTS
        sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"
        KEY='#DOCKER_OPTS'
        sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"


        ## Update docker service file
        echo "Updating docker file /usr/lib/systemd/system/docker.service"
        FILE=/usr/lib/systemd/system/docker.service
        KEY=ExecStart
        UPDATE="ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --data-root=${NEPI_DOCKER}"
        echo $UPDATE
        sudo sed -i "/^$KEY/c\\$UPDATE" "$FILE"


        if [[ "$NEPI_HW_TYPE" -eq "JETSON" ]]; then
            echo "######################################"
            echo "Configuring Docker for NVIDIA Jetson "
            echo "######################################"
            # Install nvidia toolkit
            #https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
            && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

            sudo apt-get update

            export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
            sudo apt-get install --fix-broken -y \
                nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
                nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
                libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
                libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

    
            #runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json

            if [[ ! -f "/etc/docker/daemon.json.org" ]]; then
                sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.org
            fi
            
            sudo nvidia-ctk runtime configure --runtime=docker


        fi

fi


#Then reload and restart docker
echo "Restarting Docker Service"
sudo systemctl daemon-reload
sudo systemctl start docker.socket
sudo systemctl start docker
# #sudo systemctl status docker


# # #Test Docker install
# # sudo docker pull hello-world
# # sudo docker container run hello-world

# # #Some Debug Commands
# # sudo dockerd --debug

# # sudo vi /etc/docker/daemon.json

# # sudo systemctl stop docker
# # sudo systemctl stop docker.socket
# # sudo systemctl daemon-reload
# # sudo systemctl start docker.socket
# # sudo systemctl start docker
# # sudo systemctl status docker
# # sudo docker info

# ###################################
# # Config System Services 
# ###################################

# if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then
#     echo "Installing NEPI NETWORK Management Software"
#     # sudo apt install netplan.io -y
#     # sudo apt install ifupdown -y 
#     # sudo apt install net-tools -y 
#     # sudo apt install iproute2 -y
# fi

if [[ "$NEPI_MANAGES_TIME" -eq 1 ]]; then
    echo "Installing NEPI TIME Management Software"
    sudo apt-get install chrony -y
fi

# if [[ "$NEPI_MANAGES_SSH" -eq 1 ]]; then
#     echo "Installing NEPI SSH Management Software"

# #     #echo "Installing NEPI SSH Management Software"
# #     #sudo apt install --reinstall openssh-server

# #     # sudo apt-get remove --purge openssh-server
# #     # sudo apt-get autoclean 
# #     # sudo apt --fix-broken install
# #     # sudo apt-get install openssh-server

# fi

##################################
echo ""
echo 'NEPI Docker Environment Setup Complete'
##################################

