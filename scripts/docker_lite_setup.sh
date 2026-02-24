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

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

CONFIG_USER=$(id -un)

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
# sudo rm -r /home/${CONFIG_USER}
# sudo mkdir -p /home/${CONFIG_USER}
# sudo cp -r /etc/skel/. /home/${CONFIG_USER}/
# sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /
# echo "${CONFIG_USER}:${CONFIG_USER_PW}" | sudo chpasswd
#sudo usermod -aG $CONFIG_USER $CONFIG_USER
sudo usermod -aG sudo $CONFIG_USER >/dev/null 2>&1
# sudo usermod -aG $SYS_USER_1 $CONFIG_USER >/dev/null 2>&1
# sudo usermod -aG $SYS_USER_2 $CONFIG_USER >/dev/null 2>&1
sudo adduser ${CONFIG_USER} dialout
sudo usermod -aG dialout ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG tty ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG i2c ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG video ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG docker ${CONFIG_USER} >/dev/null 2>&1
# echo $SUDO_USER
echo $CONFIG_USER
# sudo usermod -aG ${SUDO_USER} ${CONFIG_USER} #>/dev/null 2>&1
sudo chmod -R 0777 /tmp/nepi
echo ""
echo "########################"
echo "NEPI User Account Setup Complete"
echo "########################"
echo ""

echo ""
echo "########################"
echo "NEPI Docker Lite Enviorment Setup"
echo "########################"
echo ""

echo ""
echo "########################"
echo "NEPI Lite Bash Setup"
echo "########################"
echo ""

##############
echo "Installing NEPI Utils files"

NEPI_UTILS_FILE_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
NEPI_UTILS_FILE_DEST=/home/${CONFIG_USER}/.nepi_bash_utils

sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_FILE_SOURCE
sudo chmod 775 $NEPI_UTILS_FILE_SOURCE
sudo cp -p $NEPI_UTILS_FILE_SOURCE $NEPI_UTILS_FILE_DEST

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_utils
NEPI_UTILS_DEST=/home/${CONFIG_USER}

sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_UTILS_SOURCE
sudo chmod 775 $NEPI_UTILS_SOURCE
sudo cp -R -p $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST/

##############
echo "Installing NEPI aliases file ${NEPI_ALIASES_DEST} "

if [[ "$CONFIG_USER" != 'nepi' ]]; then
    NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_docker_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_docker_aliases
else
    NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_system_aliases
    NEPI_ALIASES_DEST=/home/${CONFIG_USER}/.nepi_system_aliases
fi 

if [ -f "$NEPI_ALIASES_DEST" ]; then
    sudo rm $NEPI_ALIASES_DEST
fi
sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_ALIASES_DEST
sudo chmod 775 $NEPI_ALIASES_DEST

#############
echo "Updating user bashrc files"
BASHRC=/home/${CONFIG_USER}/.bashrc

if [[ -n "${NEPI_IP%%/*}" ]]; then
    nepi_ip="${NEPI_IP%%/*}"
else
    nepi_ip=192.168.179.103
fi
if ! is_valid_ipv4 "${nepi_ip%%/*}"; then
    nepi_ip=192.168.179.103
fi

if [[ -z "$NEPI_DEVICE_ID" ]]; then
    NEPI_DEVICE_ID=device1
fi

if ! is_valid_did $NEPI_DEVICE_ID; then
    NEPI_DEVICE_ID=device1
fi

if grep -qnw $BASHRC -e "##### System Config #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### System Config #####' | sudo tee -a $BASHRC
    echo '#export CMAKE_POLICY_VERSION_MINIMUM=3.5' | sudo tee -a $BASHRC
    echo 'export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}' | sudo tee -a $BASHRC

    echo 'if [[ -f "/usr/lib/aarch64-linux-gnu/libgomp.so.1" ]]; then' | sudo tee -a $BASHRC
    echo '   LIB1=/usr/lib/aarch64-linux-gnu/libgomp.so.1' | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC

    echo  | sudo tee -a $BASHRC
    echo 'if [[ -f "/usr/local/lib/libOpen3D.so" ]]; then' | sudo tee -a $BASHRC
    echo '  LIB2=/usr/local/lib/libOpen3D.so' | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC

    echo 'export LD_PRELOAD="$LIB1 $LIB2"' | sudo tee -a $BASHRC
fi

# UPDATE NEPI Python Vesion
pyver=$(python3 --version | awk '{print $2}')
if [[ -n "$pyver" ]]; then
    pyver="${pyver%.*}"
else
    pyver=3
fi
NEPI_PYTHON=$pyver

if grep -qnw $BASHRC -e "##### Python Config #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### Python Config #####' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH='${NEPI_ENGINE}'/etc:${PYTHONPATH}' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH='${NEPI_ENGINE}'/lib/nepi_drivers:${PYTHONPATH}' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH=/usr/local/lib/python'${NEPI_PYTHON}'/site-packages:${PYTHONPATH}' | sudo tee -a $BASHRC
    echo 'export PYTHONPATH=/home/'${CONFIG_USER}'/.local/lib/python'${NEPI_PYTHON}'/site-packages:${PYTHONPATH}' | sudo tee -a $BASHRC
    if [[ "$CONFIG_USER" == 'nepi' ]]; then
        echo 'export SETUPTOOLS_USE_DISTUTILS=stdlib' | sudo tee -a $BASHRC
    fi
fi

if is_valid_cuda; then
    export NEPI_HAS_CUDA=1
    export NEPI_CUDA_VERSION=$(get_cuda_version)
else
    export NEPI_HAS_CUDA=0
    export NEPI_CUDA_VERSION=0
fi

if [[ "$NEPI_HAS_CUDA" -eq 1 ]]; then
    CUDA_HOME=/usr/local/cuda-${NEPI_CUDA_VERSION}

    if grep -qnw $BASHRC -e "##### CUDA SETUP #####" ; then
        : #echo "Already Done"
    else
        echo ' ' | sudo tee -a $BASHRC
        echo '##### CUDA SETUP #####' | sudo tee -a $BASHRC
        echo 'export CUDA_PATH='${CUDA_HOME} | sudo tee -a $BASHRC
        echo 'export CUDA_HOME='${CUDA_HOME} | sudo tee -a $BASHRC
        echo 'export CUPY_NVCC_GENERATE_CODE=current' | sudo tee -a $BASHRC
        echo 'export LD_LIBRARY_PATH='${CUDA_HOME}'/lib64:$LD_LIBRARY_PATH' | sudo tee -a $BASHRC
        echo 'export PATH='${CUDA_HOME}'/bin:${PATH}' | sudo tee -a $BASHRC
        echo 'export CUDA_VISIBLE_DEVICES=0' | sudo tee -a $BASHRC
    fi
fi

systemctl&> /dev/null
res=$?

if [[ "$?" -eq 0  && "$CONFIG_USER" == 'nepi' ]]; then
    export NEPI_IN_CONTAINER=0
else
    export NEPI_IN_CONTAINER=1
fi

# Add NEPI SETTINGS
if grep -qnw $BASHRC -e "##### NEPI SETTINGS #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo 'export USER='${CONFIG_USER} | sudo tee -a $BASHRC
    echo 'export CONFIG_USER='${CONFIG_USER} | sudo tee -a $BASHRC
    echo 'export NEPI_PYTHON='${NEPI_PYTHON} | sudo tee -a $BASHRC
    echo '' | sudo tee -a $BASHRC
    echo '##### NEPI SETTINGS #####' | sudo tee -a $BASHRC
    echo 'export NEPI_IP='${nepi_ip} | sudo tee -a $BASHRC
    echo 'export NEPI_DEVICE_ID='${NEPI_DEVICE_ID} | sudo tee -a $BASHRC
    echo 'export NEPI_RECOVERY_DEVICE_ID=device1' | sudo tee -a $BASHRC
    echo 'export NEPI_RECOVERY_IP=192.168.179.103' | sudo tee -a $BASHRC
    echo 'export NEPI_IN_CONTAINER='${NEPI_IN_CONTAINER} | sudo tee -a $BASHRC
fi

# Add NEPI Aliases
if grep -qnw $BASHRC -e "##### Source NEPI Aliases #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### Source NEPI Aliases #####' | sudo tee -a $BASHRC
    echo 'if [ -f '${NEPI_ALIASES_DEST}' ]; then' | sudo tee -a $BASHRC
    echo '    . '${NEPI_ALIASES_DEST} | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC
fi

sudo rm /root/.bashrc
sudo cp /home/${CONFIG_USER}/.bashrc /root/.bashrc
sudo chmod 0644 /root/.bashrc

sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.bashrc
sudo chmod 0664 /home/${CONFIG_USER}/.bashrc

################
echo "Fixing other user files"
cp /etc/skel/.profile /home/${CONFIG_USER}/
sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.profile
sudo chmod 0644 /home/${CONFIG_USER}/.profile

if [[ ! -d /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages ]]; then
    sudo mkdir -p /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages
fi
#echo "Udating user python permissions"
sudo chmod 755 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages

###############
echo "Fixing other system folder permissions"
if [[ ! -d "/media/${CONFIG_USER}" ]]; then
    sudo mkdir -p "/media/${CONFIG_USER}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /media/${CONFIG_USER}

echo ""
echo "Sourcing updated bash files"
source $BASHRC
wait

echo ""
echo "########################"
echo "NEPI Lite Bash Setup Complete"
echo "########################"
echo ""

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

sudo apt-get update
sudo apt-get install --fix-broken -y

echo ""
echo "######################################"
echo "Installing NEPI required python packages"
echo "######################################"

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
sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null

echo ""
echo "########################"
echo "NEPI Docker Lite Enviorment Setup Complete"
echo "########################"
echo ""

############################################ DO I NEED THIS ##############################

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    return 
fi

############################################ DO I NEED THIS ##############################

echo ""
echo "########################"
echo "NEPI LITE CONFIG SETUP"
echo "########################"
echo ""

echo ""
echo "########################"
echo "Configuring NEPI ETC FILES"
echo "########################"

# Define Folders
SOURCE_INSTR_PATH=$(dirname "$SCRIPT_FOLDER")
SOURCE_ETC_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
SOURCE_SCRIPTS_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/scripts
SOURCE_SYS_CONFIG_FILE=${SOURCE_ETC_PATH}/nepi_system_config.yaml

sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $SOURCE_ETC_PATH
sudo chmod -R +x $SOURCE_ETC_PATH



NEPI_CONFIG_PATH=/opt/nepi

NEPI_ETC_PATH=${NEPI_CONFIG_PATH}/etc




systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    SYSTEMD_SERVICE_PATH=/etc/systemd/system

    echo ""
    echo "########"
    echo "Disable apport to avoid crash reports on a display"
    sudo systemctl disable apport  >/dev/null 2>&1
    sudo systemctl stop apport  >/dev/null 2>&1
fi
etc_path=default/apport
sudo rm /etc/${etc_path} >/dev/null 2>&1
sudo cp ${SOURCE_ETC_PATH}/${etc_path} /etc/${etc_path}  >/dev/null 2>&1

sudo rm /var/crash/* 2>/dev/null

 
echo ""
echo "########"
echo "Configuring nepi_modprobe.conf"
etc_path=modprobe.d/nepi_modprobe.conf
sudo rm /etc/${etc_path} >/dev/null 2>&1
sudo cp ${SOURCE_ETC_PATH}/${etc_path} /etc/${etc_path}  >/dev/null 2>&1


echo ""
echo "########"
echo "Setting up udev rules"
    # IQR Pan/Tilt
sudo cp ${SOURCE_ETC_PATH}/udev/rules.d/* /etc/udev/rules.d/

echo ""
echo "########"
echo "Setting up Baumer GenTL Producers (Genicam support)"

if [ ! -d "/opt/baumer" ]; then
    sudo rm -r /opt/baumer >/dev/null 2>&1
fi
sudo cp -r ${SOURCE_ETC_PATH}/opt/baumer /opt/baumer
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/baumer

# Set up the shared object links in case they weren't copied properly when this repo was moved to target
NEPI_BAUMER_PATH=${NEPI_ETC_PATH}/opt/baumer/gentl_producers
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14.1 $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_usb.cti.2.14 $NEPI_BAUMER_PATH/libbgapi2_usb.cti
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14.1 $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14
sudo ln -sf $NEPI_BAUMER_PATH/libbgapi2_gige.cti.2.14 $NEPI_BAUMER_PATH/libbgapi2_gige.cti


#################################
# Update Managed Service Settings

####################################
# Run NEPI System Config Load if exists
# NEPI_SYS_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
# sudo chown $CONFIG_USER:$CONFIG_USER $NEPI_SYS_CONFIG_FILE


# NEPI_SYS_CONFIG_LOAD=/mnt/nepi_config/system_cfg/etc/load_system_config.sh
# if ! source_script $NEPI_SYS_CONFIG_LOAD; then
#     script_error=$?
#     echo "Script ${NEPI_SYS_CONFIG_LOAD} failed with error ${script_error}"
# fi

echo ""
echo "########################"
echo "Updating NEPI Managed Services"
echo "########################"

################################
# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -ne 0 ]]; then
    ###################
    echo ""
    echo "########"
    echo "Updating SSH Service Config"
    echo ""
    source_file=${SOURCE_ETC_PATH}/ssh/sshd_config
    dest_file=/etc/ssh/sshd_config
    echo "Copying ${source_file} to ${dest_file}"
    sudo cp $source_file $dest_file


    ###################
    echo ""
    echo "########"
    echo "Setting up Supervisor"
    echo ""

    sudo chmod +x ${SOURCE_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf
    sudo cp -a ${SOURCE_ETC_PATH}/supervisor/conf.d/supervisord_nepi.conf /etc/supervisor/conf.d/supervisord_nepi.conf
    sudo ln -sf /opt/nepi/scripts/nepi_start_all /nepi_start_all
    echo "Restarting Supervisor Process"
    sudo supervisorctl reread >/dev/null 2>&1
    sudo supervisorctl update >/dev/null 2>&1
    # sudo supervisorctl status
    # sudo supervisorctl tail nepi_engine
    # sudo supervisorctl tail nepi_rui
    # sudo supervisorctl tail nepi_license
    # sudo supervisorctl tail nepi_ssh
    # sudo supervisorctl tail nepi_samba
fi

# #####################################
# NEPI ETC UPDATES
# #####################################

echo ""
echo "########################"
echo "Updating NEPI OS Config"
echo "########################"
echo ""
sudo chown -R $CONFIG_USER:$CONFIG_USER /mnt/nepi_config/docker_cfg/
config_update_file=/mnt/nepi_config/system_cfg/etc/nepi_system_config.sh
SHOW_CONFIG_MENU=0
echo "Running System Config Update Script: ${config_update_file}"
bash $config_update_file $SHOW_CONFIG_MENU


# #####################################
# NEPI Services Setup
# #####################################


# #####################################
# NEPI Services Setup
# #####################################


echo "##################################"
echo 'Setting Up NEPI Services'
echo "##################################"
echo ""

SYSTEMD_SERVICE_PATH=/etc/systemd/system
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
    if [[ "$CONFIG_USER" != "nepi" ]]; then
        #############################
        echo ""
        echo "############"
        echo "Setting Up NEPI Docker Service"
        echo ""
        
        sudo cp -a ${SOURCE_ETC_PATH}/docker/services/nepi_docker.service ${SYSTEMD_SERVICE_PATH}/nepi_docker.service

        # sudo systemctl enable nepi_docker
        # sudo systemctl restart nepi_docker
    else

        echo ""
        echo "############"
        echo "Setting Up NEPI Engine Service"

        echo "Cofiguring NEPI Engine Service from ${SOURCE_ETC_PATH}/services"
        sudo chmod +x ${SOURCE_ETC_PATH}/services/*
        sudo cp -a ${SOURCE_ETC_PATH}/services/* ${SYSTEMD_SERVICE_PATH}/
        sudo systemctl enable nepi_engine

        echo ""
        echo "############"
        echo "Setting Up NEPI License Service"


        # Set up nepi_check_license (license management, etc.)
        chmod +x /opt/nepi/etc/license/nepi_check_license.py
        gpg --import /opt/nepi/etc/license/nepi_license_management_public_key.gpg

        sudo chown -R $(whoami) ~/.gnupg/
        sudo chmod 700 ~/.gnupg
        find ~/.gnupg -type d -exec sudo chmod 700 {} \;
        find ~/.gnupg -type f -exec sudo chmod 600 {} \;

        # Update ETC files if systemd is running (Not in Container)
        cp /opt/nepi/etc/services/nepi_check_license.service /etc/systemd/system/
        sudo systemctl enable nepi_check_license

        echo "***** nepi_check_license license manager is installed... you must still provide a valid license file in /mnt/nepi_storage/license *****"
    fi

elif [[ "$CONFIG_USER" == 'nepi' ]]; then

        echo ""
        echo "############"
        echo "Setting Up NEPI License Service"


        # Set up nepi_check_license (license management, etc.)
        chmod +x /opt/nepi/etc/license/nepi_check_license.py
        gpg --import /opt/nepi/etc/license/nepi_license_management_public_key.gpg

        sudo chown -R $(whoami) ~/.gnupg/
        sudo chmod 700 ~/.gnupg
        find ~/.gnupg -type d -exec sudo chmod 700 {} \;
        find ~/.gnupg -type f -exec sudo chmod 600 {} \;


fi


# #####################################
# SYNC FROM SYSTEM CONFIG
# #####################################
echo ""
echo "########################"
echo "Syncing Config Files and Folders"
echo "########################"
echo ""


echo ""
config_update_file=/mnt/nepi_config/system_cfg/etc/scripts/nepi_system_sync.sh
echo "Running System Config Sync Script: ${config_update_file}"
source $config_update_file

systemctl&> /dev/null
if [[ "$?" -eq 0  ]]; then
    if command -v chromium >/dev/null 2>&1; then
        echo "Chromium is Already Installed"
    else
        echo "########"
        echo "Updating Chrome settings for user ${CONFIG_USER}"
        echo "Killing any running Chromium processes"
        sudo pkill -f chromium
        echo "Setting Chromium as Defualt Browser"
        xdg-settings set default-web-browser chromium-browser.desktop


        if [[ ! -d "/home/${CONFIG_USER}/snap/chromium/common/chromium/Default" ]]; then
            echo "Creating Chromium Defualt Folder"
            sudo mkdir -p /home/${CONFIG_USER}/snap/chromium/common/chromium/Default
        fi
        echo "Updating Chromium Defualt Files"
        sudo cp -rf ${SOURCE_ETC_PATH/}/user/snap/chromium/common/chromium/Default/*  /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/
        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER} /home/${CONFIG_USER}/snap/chromium/common/chromium/Default/*

        echo "Cleaning Chromium Files"
        fix_chromium
    fi
fi

echo ""
echo "########################"
echo "Cleaning Config System"
echo "########################"
echo ""


sudo rm -r  /home/${CONFIG_USER}/.local/share/Trash/info/ 2>/dev/null 
sudo rm -r  /home/${CONFIG_USER}/.local/share/Trash/files/ 2>/dev/null
#sudo rm -r /tmp/* 2>/dev/null
sudo rm /var/crash/* 2>/dev/null

##########
sudo journalctl --vacuum-size=50M  # Limits journal size to 50MB
sudo journalctl --vacuum-time=7d   # Keeps logs for 7 days

echo ""
echo "##################################"
echo 'NEPI Lite Config Setup Complete'
echo "##################################"
echo ""



##########################
# Remove the repo
##########################
if [[ -d /home/${CONFIG_USER}/nepi_setup ]]; then
    sudo rm -r /home/${CONFIG_USER}/nepi_setup
fi
