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

export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" == 'nepi' ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/homenepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ "$CONFIG_USER" == 'nepihost'  ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepihost/.bashrc
    ufile=/home/nepihost/.nepi_bash_utils
    afile=/home/nepihost/.nepi_docker_aliases
# elif [[ -f "/home/${CONFIG_USER}/.nepi_docker_aliases" ]]; then
#     bfile=/home/${CONFIG_USER}/.bashrc
#     ufile=/home/${CONFIG_USER}/.nepi_bash_utils
#     afile=/home/${CONFIG_USER}/.nepi_docker_aliases
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
if [[ -n "$1" ]]; then
    LOAD_NEPI_CONFIG=$1
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
        sudo chmod 0600 /home/${CONFIG_USER}/.ssh/authorized_keys
        sudo chmod 0700 /home/${CONFIG_USER}/.ssh
        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.ssh


        # ###############
        # echo "Installing nepi ssh key files for user ${NEPI_HOST_USER}"
        # if [ ! -d "/home/${NEPI_HOST_USER}/.ssh" ]; then
        #     sudo mkdir /home/${NEPI_HOST_USER}/.ssh
        # fi 
        # sudo cp ${ETC_FOLDER}/ssh/authorized_keys /home/${NEPI_HOST_USER}/.ssh/authorized_keys
        # sudo chmod 0600 /home/${NEPI_HOST_USER}/.ssh/authorized_keys
        # sudo chmod 0700 /home/${NEPI_HOST_USER}/.ssh
        # sudo chown -R ${NEPI_HOST_USER}:${NEPI_HOST_USER} /home/${NEPI_HOST_USER}/.ssh


        # ################
        # echo "Installing nepi ssh key files for user ${NEPI_ADMIN_USER}"
        # if [ ! -d "/home/${NEPI_ADMIN_USER}/.ssh" ]; then
        #     sudo mkdir /home/${NEPI_ADMIN_USER}/.ssh
        # fi 
        # sudo cp ${ETC_FOLDER}/ssh/authorized_keys /home/${NEPI_ADMIN_USER}/.ssh/authorized_keys
        # sudo chmod 0600 /home/${NEPI_ADMIN_USER}/.ssh/authorized_keys
        # sudo chmod 0700 /home/${NEPI_ADMIN_USER}/.ssh
        # sudo chown -R ${NEPI_ADMIN_USER}:${NEPI_ADMIN_USER} /home/${NEPI_ADMIN_USER}/.ssh

        sudo systemctl restart sshd
fi

