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

LOAD_SCRIPT=${CONFIG_FOLDER}/load_docker_config.py

DOCKER_CONFIG_FILE=${CONFIG_FOLDER}/nepi_docker_config.yaml
BACKUP_FILE=${CONFIG_FOLDER}/nepi_docker_config.yaml.bak
if [[ ! -f $BACKUP_FILE ]]; then
    cp $DOCKER_CONFIG_FILE $BACKUP_FILE
fi

#echo "Starting Load Script with config folder: " ${CONFIG_FOLDER}

if [[ -f "$LOAD_SCRIPT" ]]; then
    SETUP_FOLDER='nepi_setup'
    if [[ ":$CONFIG_FOLDER:" != *":$SETUP_FOLDER:"* ]]; then
        sudo chown ${CONFIG_USER}:${CONFIG_USER} $DOCKER_CONFIG_FILE
        clean_yaml_file $DOCKER_CONFIG_FILE
        if [[ ! -f $BACKUP_FILE ]]; then
            cp $DOCKER_CONFIG_FILE $BACKUP_FILE
        fi
        clean_yaml_file $BACKUP_FILE
    if

    #echo "Running Load Process"
    success=0
    eval_cmd="load_vals=$(python3 $LOAD_SCRIPT )"  #2>/dev/null"
    eval "$eval_cmd"
    #echo "${load_vals}"
    
    for entry in $load_vals; do
        export ${entry}
        #echo ${entry}
    done

    echo "Finished Load Process"
    if [[ "$success" -ne 1 ]]; then
        #echo "Success = ${success}"
        echo "Docker Config File failed to load"
        echo "Checking for Backup Config File..."

        if [[ -f "$BACKUP_FILE" ]]; then
            echo "Backup File Exists Updating Config File"
            sudo cp $BACKUP_FILE $DOCKER_CONFIG_FILE
            sudo chown ${CONFIG_USER}:${CONFIG_USER} $DOCKER_CONFIG_FILE
            success=0
            eval_cmd="load_vals=$(python3 $LOAD_SCRIPT )"  #2>/dev/null"
            eval "$eval_cmd"
            for entry in $load_vals; do
                export ${entry}
            done
            if [[ "$success" -ne 1 ]]; then
                echo "Failed to Load Config File from Backup"
                exit
            fi
        else
            echo "Backup File does not Exist"
            exit
        fi
    fi

    if [[ ":$CONFIG_FOLDER:" != *":$SETUP_FOLDER:"* ]]; then
        if [[ "$success" -eq 1 ]]; then
            echo "Backing Up Docker Config File..."
            sudo cp $DOCKER_CONFIG_FILE $BACKUP_FILE
            sudo chown ${CONFIG_USER}:${CONFIG_USER} $BACKUP_FILE
        fi

        sudo chown ${CONFIG_USER}:${CONFIG_USER} $DOCKER_CONFIG_FILE
    fi

else
    echo "Load script not found ${LOAD_SCRIPT}"
    exit
fi
