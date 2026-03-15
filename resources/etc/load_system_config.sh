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


# This script loads the nepi_system_config.yaml values

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


CONFIG_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

LOAD_SCRIPT=${CONFIG_FOLDER}/load_system_config.py

NEPI_CONFIG_FILE=${CONFIG_FOLDER}/nepi_system_config.yaml
BACKUP_FILE=${CONFIG_FOLDER}/nepi_system_config.yaml.bak




if [[ -f "$LOAD_SCRIPT" ]]; then

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_CONFIG_FILE

    success=0
    eval_cmd="load_vals=$(python3 $LOAD_SCRIPT )"  #2>/dev/null"
    eval "$eval_cmd"
    #echo "${load_vals}"
    
    for entry in $load_vals; do
        export ${entry}
    done

    if [[ "$success" -ne 1 ]]; then
        #echo "Success = ${success}"
        echo "NEPI Config File failed to load"
        echo "Checking for Backup Config File..."

        if [[ -f "$BACKUP_FILE" ]]; then
            echo "Backup File Exists Updating Config File"
            sudo cp $BACKUP_FILE $NEPI_CONFIG_FILE  
            sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_CONFIG_FILE
            success=0
            eval_cmd="load_vals=$(python3 $LOAD_SCRIPT )"  #2>/dev/null"
            eval "$eval_cmd"
            for entry in $load_vals; do
                export ${entry}
            done
            if [[ "$success" -ne 1 ]]; then
                echo "Failed to Load Config File from Backup"
                return 1
            fi
        else
            echo "Backup File does not Exist"
            return 1
        fi
    fi


    if [[ "$success" -eq 1 ]]; then
        echo "Backing Up NEPI Config File..."
        sudo cp $NEPI_CONFIG_FILE $BACKUP_FILE
        sudo chown ${CONFIG_USER}:${CONFIG_USER} $BACKUP_FILE 2>/dev/null
    fi

    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_CONFIG_FILE

else
    echo "Load script not found ${LOAD_SCRIPT}"
    return 1
fi
