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
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $LITE_INSTALL
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
echo "Setting NEPI CONFIG USER: ${CONFIG_USER}"
echo ""
echo "Configuring NEPI Base User account $CONFIG_USER"
sudo usermod -aG sudo $CONFIG_USER >/dev/null 2>&1
sudo adduser ${CONFIG_USER} dialout
sudo usermod -aG dialout ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG tty ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG i2c ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG video ${CONFIG_USER} >/dev/null 2>&1
sudo usermod -aG docker ${CONFIG_USER} >/dev/null 2>&1
USER_1000=$(id -nu 1000)
if [[ ${CONFIG_USER} != ${USER_1000} ]]; then
    sudo usermod -aG ${USER_1000} ${CONFIG_USER} >/dev/null 2>&1
fi
echo $CONFIG_USER
sudo chmod -R 0777 /tmp/nepi
echo ""
echo "########################"
echo "NEPI Docker Lite User Account Setup Complete"
echo "########################"
echo ""



####################################
# Run NEPI Docker Environment Setup Script

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_env_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi


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



NEPI_STATIC_IP_END=$NEPI_STATIC_IP
NEPI_DEVICE_ID_END=$NEPI_DEVICE_ID


new_ip=${NEPI_STATIC_IP_END%%/*}
new_submask=${new_ip%.*}
new_addr=${new_ip##*.}
host_ip="127.0.0.${new_addr}"
rm_ip=${new_submask}.5

echo "Your NEPI DEVICE IP address is set to:" 
echo "${NEPI_STATIC_IP_END}"

echo " "
echo "You can connect to your NEPI Device's RUI in a Chrome browser on this device:"
echo "nepirui   OR   entering  http://${host_ip}:5003/  in a Chromium browser"

echo " "
echo "You can ssh into your Running NEPI Docker contatiner by typing:"
echo "sshn"


echo ""
echo "Your remote dev system network adapter should be set to "
echo "${rm_ip}"

echo " "
echo "You can connect to your NEPI Device's RUI in a Chrome browser on a remote device:"
echo "nepirui   OR   entering  http://${new_ip}:5003/  in a Chromium browser"

echo " "
echo "To see a list of available NEPI bash command line shortcuts run: nepihelp"
echo " "




if [[ ${NEPI_STATIC_IP_END} != ${NEPI_STATIC_IP_START} ]]; then
    remote_ip=${SSH_CLIENT%% *}
    remote_submask=${remote_ip%.*}
    remote_addr=${remote_ip##*.}

    echo ""
    echo "Your NEPI STATIC IP address has changed from: ${NEPI_STATIC_IP_START%%/*} to: ${NEPI_STATIC_IP_END%%/*}"
    echo ""
    if systemctl is-active --quiet NetworkManager; then
        echo "You can switch network adapter settings on this device between "
        echo "  NEPI Static IP ${new_ip}, Automatic IP, or a Custom IP/Netmask by typing:"
        echo "netnepi  OR   nepiauto   OR  netsetstatic <ip_address/netmask>"  
        ehco ""
    fi
    # else
    #     sudo systemctl restart networking
fi

