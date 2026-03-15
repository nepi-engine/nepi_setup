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

# This script updates bash stored system values

sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    id -nu 1000
fi
export CONFIG_USER=$CONFIG_USER


bfile=/home/${CONFIG_USER}/.bashrc
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
if [[ -v "$1" ]]; then
    if [[ "$1" -eq 0 ]]; then
        LOAD_NEPI_CONFIG=0
    fi
fi

if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi

#############################
echo ""
echo "UPDATING BASH CONFIG"


if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


if [[ -f "$bfile" ]]; then
    echo ""
    echo "Updating Bash Variables"
    if is_valid_did $NEPI_DEVICE_ID; then
        update_text_value $bfile "export NEPI_DEVICE_ID" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"
    fi
    nepi_ip="${NEPI_IP%%/*}"
    if is_valid_ipv4 $nepi_ip; then
        update_text_value $bfile "export NEPI_IP" "export NEPI_IP=${nepi_ip}"
    fi

    sudo rm /root/.bashrc

    sudo cp /home/${CONFIG_USER}/.bashrc /root/.bashrc
    sudo chmod 0644 /root/.bashrc

    sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/.bashrc
    sudo chmod 0644 /home/${CONFIG_USER}/.bashrc

    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/nepi_utils
    sudo chmod -R 0755 /home/${CONFIG_USER}/nepi_utils

    sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}
    sudo chmod 0755 /home/${CONFIG_USER}

else
    echo "NEPI Bashrc file not found at: ${bfile}"
    exit 1
fi





    
