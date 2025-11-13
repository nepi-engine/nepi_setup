#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up the OS software requirements for a NEPI File System installation

sudo -v

# sudo apt
# sudo apt install iputils-ping -y
# wait

export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" != 'nepi' ]]; then
   echo "Current user is ${CONFIG_USER}. This scripts must be run as nepi user."
   exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



# if ! is_valid_internet; then
#     echo "No Internet Connection Detected.  Connect and rerun this script"
#     exit 1
# fi

echo "########################"
echo "NEPI ENVIRONMENT SETUP"
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



#######################################
## Configure NEPI Software Requirements


echo ""
echo "Installing Software Requirements"

# Create and change to tmp install folder
TMP=/mnt/nepi_storage/tmp
fix_path $TMP
sudo chown -R nepi:nepi ${TMP}
cd $TMP


sudo apt update
sudo apt-get install software-properties-common -y
sudo apt install apt-utils -y

sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update
sudo apt install yq -y

sudo apt install cmake -y
sudo apt install cmake-doc ninja-build -y



sudo apt install lsb-release -y
sudo apt install nano -y
sudo apt install git -y



sudo apt install trash-cli -y
sudo apt install onboard -y
sudo apt install setools -y
sudo apt install ubuntu-advantage-tools -y

sudo apt install scons -y # Required for num_gpsd
sudo apt install zstd -y # Required for Zed SDK installer
sudo apt install dos2unix -y # Required for robust automation_mgr
sudo apt install libffi-dev -y # Required for python cryptography library
sudo apt install libv4l-dev v4l-utils -y # V4L Cameras (USB, etc.)
sudo apt install curl -y # Node.js installation below
sudo apt install v4l-utils -y
sudo apt install psmisc -y
sudo apt install scapy -y
sudo apt install minicom -y
sudo apt install dconf-editor -y
sudo apt install python-debian -y
sudo apt install python3-scipy -y
sudo apt install gparted -y
sudo apt install socat protobuf-compiler -y

sudo apt install gnupg -y
sudo apt install kgpg -y

sudo apt install snapd -y
sudo apt install xz-utils -y
sudo apt install rsync -y


#sudo apt install -y lsyncd rsync

    #########
    # Install Driver Support Libs

#https://www.stereolabs.com/developers/release/4.1
wget https://download.stereolabs.com/zedsdk/4.1/l4t35.1/jetsons
sudo sudo apt install zstd -y





#######################################################
sudo apt install nvidia-utils-515 -y
###################################################

echo "######################################"
echo "Installing Hostname Apps"
echo "######################################"
sudo apt install hostapd -y # WiFi access point setup


### Install ccache
#https://askubuntu.com/questions/470545/how-do-i-set-up-ccache

sudo apt install -y ccache
sudo /usr/sbin/update-ccache-symlinks
echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a ~/.bashrc
source ~/.bashrc && echo $PATH
ccache --version




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



#######################
# Install Python 
#######################

# Create USER python folder
if [ ! -d "/home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages" ]; then
    mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages
    mkdir -p /home/${CONFIG_USER}/.local/bin
fi
sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.local

# Install Python
sudo apt update 


#######################
# To Updgrade from an existing python version
#######################

#create requirements file from current dev install then run both as normal and sudo user
# https://stackoverflow.com/questions/31684375/automatically-create-file-requirements-txt
# pip3 freeze > requirements.txt
# sed 's/==.*$//' requirements.txt > requirements_no_versions.txt
# then
# Copy to /mnt/nepi_storage/tmp
# ssh into tmp folder on nepi

# Remove old pythons
#sudo apt remove --purge python3.x
#sudo rm -r /usr/bin/python*
#sudo rm -r /usr/lib/python*
#sudo apt autoremove

# sudo apt install --reinstall ca-certificates -y
# sudo apt install software-properties-common -y
# sudo add-apt-repository ppa:deadsnakes/ppa -y 
# sudo apt update
# sudo apt install python${NEPI_PYTHON} -f -y 

# # Install pip
# sudo apt remove python-pip
# sudo apt remove python3-pip
# sudo cd /usr/local/bin
# sudo rm pip*
# for python 3.8
# sudo apt install python3-pip -y

#######################
# # Make sure there is user local package


mkdir -p $(python -m site --user-site)
mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages
ln -sf /usr/bin/pip3 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages/pip
sudo rm /usr/bin/pip
sudo ln -s /usr/bin/pip3 /usr/bin/pip



# Install support packages
sudo apt install python${NEPI_PYTHON}-distutils -y
sudo apt install python${NEPI_PYTHON}-venv -y
sudo apt install python${NEPI_PYTHON}-dev -y 


# Update python symlinks
sudo ln -sfn /usr/bin/python${NEPI_PYTHON} /usr/bin/python3
sudo ln -sfn /usr/bin/python3 /usr/bin/python
sudo python${NEPI_PYTHON} -m pip --version


# ** This is just for notes, 
# these commmands are part of nepi_system_aliases 
# installed during nepi setup process
# Edit bashrc file  
# nano ~/.nepi_aliases
# Add to end of bashrc
#    export SETUPTOOLS_USE_DISTUTILS=stdlib
#    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
#    export PYTHONPATH=/usr/.local/lib/python${NEPI_PYTHON}/site-packages/:$PYTHONPATH

sudo -H python${NEPI_PYTHON} -m pip install cmake
sudo -H python${NEPI_PYTHON} -m pip install numpy
sudo -H python${NEPI_PYTHON} -m pip install scikit-build ninja 
#sudo -H python${NEPI_PYTHON} -m pip install mkl-static mkl-include
# Maybe
# Revert numpy
#sudo python${NEPI_PYTHON} -m pip uninstall numpy
#sudo python${NEPI_PYTHON} -m pip3 install numpy=='1.24.4'







sudo python3 -m pip install --upgrade pip

#############
#Manual installs some additinal packages in sudo one at a time

sudo -H python${NEPI_PYTHON} -m pip install --upgrade setuptools

sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input wheel
sudo -H python${NEPI_PYTHON} -m pip install --no-input wheel

sudo -H python${NEPI_PYTHON} -m pip install --no-input cffi
sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input netifaces
sudo -H python${NEPI_PYTHON} -m pip install --no-input netifaces

sudo -H python${NEPI_PYTHON} -m pip install --no-input pyserial 
sudo -H python${NEPI_PYTHON} -m pip install --no-input websockets 
sudo -H python${NEPI_PYTHON} -m pip install --no-input geographiclib 
sudo -H python${NEPI_PYTHON} -m pip install --no-input PyGeodesy 
sudo -H python${NEPI_PYTHON} -m pip install --no-input harvesters 
sudo -H python${NEPI_PYTHON} -m pip install --no-input WSDiscovery 
sudo -H python${NEPI_PYTHON} -m pip install --no-input python-gnupg 
sudo -H python${NEPI_PYTHON} -m pip install --no-input onvif_zeep
sudo -H python${NEPI_PYTHON} -m pip install --no-input onvif 
sudo -H python${NEPI_PYTHON} -m pip install --no-input rospy_message_converter
sudo -H python${NEPI_PYTHON} -m pip install --no-input PyUSB
sudo -H python${NEPI_PYTHON} -m pip install --no-input jetson-stats

sudo -H python${NEPI_PYTHON} -m pip install --no-input labelImg # For onboard training
sudo -H python${NEPI_PYTHON} -m pip install --no-input licenseheaders # For updating license files and source code comments

sudo -H python${NEPI_PYTHON} -m pip install --no-input yap
sudo -H python${NEPI_PYTHON} -m pip install --no-input yapf

sudo -H python${NEPI_PYTHON} -m pip install --no-input python-gnupg

sudo -H python${NEPI_PYTHON} -m pip install --upgrade --no-input tornado
sudo -H python${NEPI_PYTHON} -m pip install --no-input Flask
sudo -H python${NEPI_PYTHON} -m pip install --no-input supervisor 

sudo -H python${NEPI_PYTHON} -m pip install --upgrade --no-input scipy
sudo -H python${NEPI_PYTHON} -m pip install --no-input virtualenv venv




#############
# Other general python utilities
python${NEPI_PYTHON} -m pip install --no-input --user labelImg # For onboard training
python${NEPI_PYTHON} -m pip install --no-input --user licenseheaders # For updating license files and source code comments


echo "####################################################"

##########################
sudo python3 -c "import cv2; print('cv2 is installed, version:', cv2.__version__)" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Python cv2 (OpenCV) is installed."
    # Optionally, print the version:
    sudo python3 -c "import cv2; print('Version:', cv2.__version__)"
else
    echo "Python cv2 (OpenCV) is NOT installed. Will install"
    sudo python${NEPI_PYTHON} -m pip install --no-input opencv-python
fi

sudo python3 -c "import torch; print('torch is installed, version:', torch.__version__)" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Python torch is installed."
    # Optionally, print the version:
    sudo python3 -c "import torch; print('Version:', torch.__version__)"
else
    echo "Python torch is NOT installed. Will install"
    sudo python${NEPI_PYTHON} -m pip install --no-input torch
fi


sudo python3 -c "import torchvision; print('torchvision is installed, version:', torchvision.__version__)" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Python torchvision is installed."
    # Optionally, print the version:
    python3 -c "import torchvision; print('Version:', torchvision.__version__)"
else
    echo "Python torchvision is NOT installed. Will install"
    sudo python${NEPI_PYTHON} -m pip install --no-input torchvision
fi

sudo python3 -c "import open3d; print('open3d is installed, version:', open3d.__version__)" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Python open3d is installed."
    # Optionally, print the version:
    sudo python3 -c "import open3d; print('Version:', open3d.__version__)"
else
    echo "Python open3d is NOT installed. Will install"
    sudo python${NEPI_PYTHON} -m pip install --no-input open3d #--ignore-installed
fi



#https://github.com/ultralytics/ultralytics/issues/21015
#sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input ultralytics
# sudo pip install git+https://github.com/ultralytics/ultralytics.git@main

#sudo python${NEPI_PYTHON} -m pip install ultralytics

#############
# # Install additional python requirements
# # Copy the requirements files from nepi_engine/nepi_env/setup to /mnt/nepi_storage/tmp
# NEPI_REQ_SOURCE=$(dirname "$(pwd)")/resources/requirements
# sudo cp ${NEPI_REQ_SOURCE}/nepi_requirements.txt ./
# cat nepi_requirements.txt | sed -e '/^\s*#.*$/d' -e '/^\s*$/d' | xargs -n 1 sudo python${NEPI_PYTHON} -m pip install



# ############################################
# ## Setup ROS
# ############################################
# source ros_setup.sh
# wait

#########################################
# Setup RUI Required Software
#########################################

python${NEPI_PYTHON} -m pip install --no-input --user -U pip
python${NEPI_PYTHON} -m pip install --no-input --user virtualenv


# Install Base Node.js Tools and Packages (Required for RUI, etc.)
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
export NVM_DIR="${NEPI_HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 8.11.1 # RUI-required Node version as of this script creation

###################################
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


echo "######################################"
echo "Installing Shared Drive Apps"
echo "######################################"
sudo apt install samba -y
sudo apt install smbclient -y

sudo apt-get update
sudo apt --fix-broken install
echo "######################################"
echo "Installing Supervisor Apps"
echo "######################################"
sudo apt install supervisor -y



if [[ -n "$DISPLAY" ]]; then
    echo "########################"
    echo "Installing Desktop Utility Apps"
    echo "########################"
    sudo apt update

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
sudo apt-get clean
sudo apt-get update
sudo apt update
sudo apt-get install --fix-broken -y
sudo rm -r ~/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r ~/.local/share/Trash/files/ 2>/dev/null
sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null


echo "##################################"
echo ""
echo 'NEPI Environment Setup Complete'
echo "##################################"
echo ""
echo ""
echo "##################################"
echo "Chcking for CUDA support on python installs"
echo ""
sudo python3 -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"
echo ""
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
sudo python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
echo ""
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
sudo python3 -c "import torchvision; print(torchvision.__version__)"
echo ""
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
echo ""
echo ""
echo "##################################"
echo "If CUDA support required for any of these packages,"
echo " and not supported in current configurations shown above,"
echo "install CUDA supported version manaully"