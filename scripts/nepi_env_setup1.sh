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
echo "Script Folder: ${SCRIPT_FOLDER}"
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

# Load System Config File
#echo "Loading NEPI SYSTEM CONFIG"
nepi_config_loaded=0
NEPI_SETUP_CONFIG_FILE=${RESOURCES_FOLDER}/etc/load_system_config.sh
NEPI_SYSTEM_CONFIG_FILE=/home/${CONFIG_USER}/load_system_config.sh
if [[ -f $NEPI_SYSTEM_CONFIG_FILE ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SYSTEM_CONFIG_FILE}"
    source ${NEPI_SYSTEM_CONFIG_FILE} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        nepi_config_loaded=1
    fi
elif [[ -f $NEPI_SETUP_CONFIG_FILE && $nepi_config_loaded -eq 0 ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SETUP_CONFIG_FILE}"
    source ${NEPI_SETUP_CONFIG_FILE}  >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SETUP_CONFIG_FILE}"
    fi
fi


sudo apt-get install iputils-ping -y
wait


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"

else


    ######################################

    echo ""
    echo "########################"
    echo "NEPI ENVIRONMENT SETUP 1"
    echo "########################"
    echo ""




    ####################################
    # Run NEPI Bash Setup Script


    script_file=nepi_bash_setup.sh
    script_path=${SCRIPT_FOLDER}/${script_file}
    if ! source_script $script_path; then
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

    TMP=/mnt/nepi_storage/tmp
    fix_folder $TMP
    cd $TMP


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

    pyver=$(python3 --version | awk '{print $2}')
    if [[ -n "$pyver" ]]; then
        pyver="${pyver%.*}"
    else
        pyver=3
    fi
    NEPI_PYTHON=$pyver


    systemctl&> /dev/null
    if [[ "$?" -eq 0 ]]; then
        SYSTEMD_SERVICE_PATH=/etc/systemd/system

        echo ""
        echo "########"
        echo "Disable apport to avoid crash reports on a display"
        sudo systemctl disable apport
        sudo systemctl stop apport
    fi


    sudo apt update
    sudo apt-get install --fix-broken -y 

    #############################################


    echo ""
    echo "########################"
    echo "Installing Software Requirements"
    echo "########################"
    echo ""


    #sudo rm /var/lib/apt/lists/* -vf
    sudo apt update 
    sudo apt upgrade -y

    sudo apt clean -y
    sudo apt update
    sudo apt-get install --fix-broken -y

    sudo apt install software-properties-common apt-utils -y
    sudo apt install --reinstall ubuntu-advantage-tools -y
    #sudo apt install --reinstall ubuntu-desktop -y

    # Hide Prompts
    #DEBIAN_FRONTEND=noninteractive apt-get install -y <package_name>

    sudo apt update
    sudo apt install build-essential cmake cmake-doc ninja-build lsb-release vim \
        nano git trash-cli onboard setools ubuntu-advantage-tools scons dos2unix \
        libffi-dev libv4l-dev v4l-utils curl v4l-utils psmisc scapy minicom dconf-editor \
        gparted socat protobuf-compiler gnupg kgpg snapd xz-utils rsync  trash-cli \
        dialog ncdu -y


    sudo add-apt-repository ppa:rmescandon/yq -y
    sudo apt update
    sudo apt install yq -y
    
   



    echo ""
    echo "########################"
    echo "Installing Driver Support Software"
    echo "########################"
    echo ""

    ### Install ccache
    #https://askubuntu.com/questions/470545/how-do-i-set-up-ccache

    sudo apt install -y ccache
    sudo /usr/sbin/update-ccache-symlinks
    echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a ~/.bashrc
    source ~/.bashrc && echo $PATH
    ccache --version





    ######################################
    # Install some additional libraries
    sudo apt update
    sudo apt install libboost-all-dev libboost-doc libboost-dev libgtk2.0-dev pkg-config libavcodec-dev \
        libavformat-dev libswscale-dev python3-dev python3-numpy libtbb2 libtbb-dev \
        libjpeg-dev libpng-dev libtiff-dev libdc1394-22-devlibgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev python3.8-dev python-dev python-numpy python3-numpy \
        libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev \
        libv4l-dev v4l-utils qv4l2 libopenblas-base libopenmpi-dev libomp-dev \
        libopenblas-dev libxml2-dev libxslt1-dev libgpiod2 -y

    sudo apt update
    sudo apt-get install --fix-broken -y 

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

    #sudo apt install --reinstall openssh-server

    sudo apt-get remove --purge openssh-server -y
    sudo apt-get autoclean 
    sudo apt-get install --fix-broken -y
    sudo apt-get install openssh-server -y


    echo "############"
    echo "Installing Network Apps"
    echo ""

    #sudo apt install netplan.io -y
    sudo apt install ifupdown net-tools iproute2 isc-dhcp-client wpasupplicant -y


    echo "############"
    echo "Installing Shared Drive Apps"
    echo ""
    sudo apt install samba smbclient -y

    # echo "############"
    # echo "Installing Data Annotation Software"
    # echo ""
    # script_file=dev_ai_train_setup.sh
    # script_path=${SCRIPT_FOLDER}/${script_file}
    # source $script_path


    # echo "############"
    # echo "Installing USB Drive Auto Mount Software"
    # echo ""
    # sudo apt install usbmount -y


    sudo apt update
    sudo apt-get install --fix-broken -y 
    echo "######################################"
    echo "Installing Supervisor Apps"
    echo "######################################"
    sudo apt install supervisor -y


    echo ""
    echo "########################"
    echo "Cleaning File System"
    echo "########################"


    #sudo rm /var/lib/apt/lists/* -vf
    sudo apt clean
    sudo apt update
    sudo apt update
    sudo apt-get install --fix-broken -y 


    sudo rm -r ~/.local/share/Trash/info/ 2>/dev/null 
    sudo rm -r ~/.local/share/Trash/files/ 2>/dev/null
    #sudo rm -r /tmp/* 2>/dev/null
    sudo rm /var/crash/* 2>/dev/null


    # echo "##################################"
    # echo ""
    # echo 'NEPI Environment Setup 1 Complete'
    # echo "##################################"
    # echo ""
    # echo ""
    # echo "##################################"
    # echo "Chcking for CUDA support on python installs"
    # echo ""
    # echo "**** CV2 *****"
    # sudo python3 -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"
    # echo ""
    # echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    # echo ""
    # echo "**** TORCH *****"
    # sudo python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
    # echo ""
    # echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    # echo ""
    # echo "**** TORCHVISION *****"
    # sudo python3 -c "import torchvision; print(torchvision.__version__)"
    # echo ""
    # echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    # echo ""
    # echo "**** OPEN3D *****"
    # sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
    # echo ""
    # echo ""
    # echo "##################################"
    # echo "If CUDA support required for any of these packages,"
    # echo " and not supported in current configurations shown above,"
    # echo "install CUDA supported version manaully"

fi