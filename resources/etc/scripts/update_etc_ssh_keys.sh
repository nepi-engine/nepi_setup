#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc user settings

if [[ "$(id -un 1000)" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ -f "/home/${USER}/.nepi_docker_aliases" ]]; then
    CONFIG_USER=${USER}
    bfile=/home/${USER}/.bashrc
    ufile=/home/${USER}/.nepi_bash_utils
    afile=/home/${USER}/.nepi_docker_aliases
else
    echo "NEPI Aliases bash file not found"
    exit 1
fi

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -v "$1" ]]; then
    if [[ "$1" -eq 0 ]]; then
        LOAD_NEPI_CONFIG=0
    fi
fi

if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v CONFIG_USER ]]; then
    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi

################################
echo ""
echo "UPDATING ETC SSH KEYS"


update_keys=0
ssh_key_source=${ETC_FOLDER}/ssh/authorized_keys
ssh_key_dest=/home/${CONFIG_USER}/.ssh/authorized_keys
if [[ ! -f "${ssh_key_dest}" ]]; then
    update_keys=1
elif cmp -s ${ssh_key_source} ${ssh_key_dest}; then
    update_keys=0
else
    update_keys=1
fi

if [[ "$update_keys" -eq 1  ]]; then
        ###############
        echo "Installing nepi ssh key files for user ${CONFIG_USER}"
        if [ ! -d "/home/${CONFIG_USER}/.ssh" ]; then
            sudo mkdir /home/${CONFIG_USER}/.ssh
        fi 
        sudo cp ${ETC_FOLDER}/ssh/authorized_keys /home/${CONFIG_USER}/.ssh/authorized_keys
        sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}
        sudo chmod 0755 /home/${CONFIG_USER}
        sudo chmod 0600 /home/${CONFIG_USER}/.ssh/authorized_keys
        sudo chmod 0700 /home/${CONFIG_USER}/.ssh
        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.ssh


    


        # Update ETC files if systemd is running (Not in Container)
        systemctl&> /dev/null
        if [[ "$?" -eq 0 ]]; then
            sudo systemctl restart sshd
        fi
fi

