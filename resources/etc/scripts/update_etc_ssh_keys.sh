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
## Redistributions in source code must retain this top-level comment block.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##

# This script updates etc user settings

sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
fi
export CONFIG_USER=$CONFIG_USER

ufile=/home/${CONFIG_USER}/.nepi_bash_utils
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -v $1 ]]; then
    if [[ $1 -eq 0 ]]; then
        LOAD_NEPI_CONFIG=0
        #echo "Skipping NEPI System Config load"
    fi
fi

if [[ $LOAD_NEPI_CONFIG -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    #echo "Loading NEPI SYSTEM CONFIG"
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

