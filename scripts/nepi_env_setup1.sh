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


# This file sets up the OS software requirements for a NEPI File System installation


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
USER_CHECK_FILE=${SCRIPT_FOLDER}/nepi_user_check.sh
source $USER_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



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

    sudo apt install software-properties-common -y
    sudo apt install apt-utils -y
    sudo apt install --reinstall ubuntu-advantage-tools -y
    #sudo apt install --reinstall ubuntu-desktop -y

    # Hide Prompts
    #DEBIAN_FRONTEND=noninteractive apt-get install -y <package_name>

    sudo apt update
    sudo apt install build-essential -y
    sudo apt install cmake -y
    sudo apt install cmake-doc ninja-build -y



    sudo apt install lsb-release -y
    sudo apt install vim -y
    sudo apt install nano -y
    sudo apt install git -y



    sudo apt install trash-cli -y
    sudo apt install onboard -y
    sudo apt install setools -y
    sudo apt install ubuntu-advantage-tools -y

    sudo apt install scons -y # Required for num_gpsd
    sudo apt install dos2unix -y # Required for robust automation_mgr
    sudo apt install libffi-dev -y # Required for python cryptography library
    sudo apt install libv4l-dev v4l-utils -y # V4L Cameras (USB, etc.)
    sudo apt install curl -y # Node.js installation below
    sudo apt install v4l-utils -y
    sudo apt install psmisc -y
    sudo apt install scapy -y
    sudo apt install minicom -y
    sudo apt install dconf-editor -y
    sudo apt install gparted -y
    sudo apt install socat protobuf-compiler -y

    sudo apt install gnupg -y
    sudo apt install kgpg -y

    sudo apt install snapd -y
    sudo apt install xz-utils -y
    sudo apt install rsync -y


    sudo add-apt-repository ppa:rmescandon/yq -y
    sudo apt update
    sudo apt install yq -y

    
    sudo apt install trash-cli -y
    sudo apt install dialog -y
    sudo apt install ncdu -y



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



    ### Install Driver Support Libs

    if [[ ${NEPI_ARCH} == 'jetson' ]]; then
        #https://www.stereolabs.com/developers/release/4.1
        wget https://download.stereolabs.com/zedsdk/4.1/l4t35.1/jetsons -O 'zstd.run'
    elif [[ ${NEPI_ARCH} == 'arm64' ]]; then
        #https://www.stereolabs.com/developers/release/4.2
        # wget https://download.stereolabs.com/zedsdk/4.2/cu11/ubuntu20 -O 'zstd.run'
    elif [[ ${NEPI_ARCH} == 'amd64' ]]; then
        #https://www.stereolabs.com/developers/release/4.2
        if is_valid_cuda; then
            wget https://download.stereolabs.com/zedsdk/4.2/cu11/ubuntu20 -O 'zstd.run'
        fi
    fi
    sudo sudo apt install zstd -y


    sudo apt install nvidia-utils-515 -y

    sudo apt install linux-generic-hwe-20.04 -y



    # https://stackoverflow.com/questions/8430332/uninstall-boost-and-install-another-version
    # First uninstall older version
    sudo apt -y install libboost-all-dev libboost-doc libboost-dev


    ######################################
    # Install some additional libraries
    sudo apt update
    sudo apt install -y build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
    sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
    sudo apt install -y python3.8-dev python-dev python-numpy python3-numpy
    sudo apt install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
    sudo apt install -y libv4l-dev v4l-utils qv4l2 #v4l2ucp    
    sudo apt install -y libopenblas-base libopenmpi-dev libomp-dev 
    sudo apt -y install libopenblas-dev
    sudo apt install -y libxml2-dev libxslt1-dev

    sudo apt install libgpiod2 -y

    sudo apt update
    sudo apt-get install --fix-broken -y 



    echo ""
    echo "########################"
    echo "Installing System Applications"
    echo "########################"
    echo ""


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
    sudo apt install chrony -y



    echo "Installing NEPI SSH Management Software"

    echo "Installing NEPI SSH Management Software"
    #sudo apt install --reinstall openssh-server -y

    sudo apt remove --purge openssh-server -y
    sudo apt update
    sudo apt-get install --fix-broken -y 
    sudo apt install openssh-server -y
    if [[ ! -f "/run/sshd" ]]; then
        sudo mkdir "/run/sshd"
    fi
    sudo chmod 0755 /run/sshd
    sudo chown root:root /run/sshd



    sudo apt update
    sudo apt-get install --fix-broken -y 

    echo ""
    echo "######################################"
    echo "Installing Shared Drive Apps"
    echo "######################################"
    echo ""

    sudo apt install samba -y
    sudo apt install smbclient -y

    sudo apt update
    sudo apt-get install --fix-broken -y 
    echo "######################################"
    echo "Installing Supervisor Apps"
    echo "######################################"
    sudo apt install supervisor -y




    if [[ -n "$DISPLAY" ]]; then
        echo "########################"
        echo "Installing Desktop Utility Apps"
        echo "########################"
        sudo apt update

        #######
        echo ""
        echo "Installing mdview"
        sudo snap install mdview

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
    fi


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