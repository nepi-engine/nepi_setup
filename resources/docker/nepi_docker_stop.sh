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

# This script Stops a Running NEPI Container

sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    if [[ -d "/home/nepihost" ]]; then
        CONFIG_USER=nepihost
    else
        CONFIG_USER=$(id -nu 1000)
    fi
fi
export CONFIG_USER=$CONFIG_USER

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils
afile=/home/${CONFIG_USER}/.nepi_docker_aliases

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
DOCKER_CONFIG_UPDATE_FILE=${DOCKER_FOLDER}/nepi_docker_update.sh

########################
# Update Docker Config
echo ""
echo "Updating Docker Config File"

source $DOCKER_CONFIG_UPDATE_FILE
if [[ "$?" -eq 1 ]]; then
    echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
else

    ########################
    # Start Processes


    ########################
    # Stop Running Command
    ########################

    echo "Stopping Running NEPI Docker Processes"
    echo "Stopping and removing NEPI Contatiners"

    NEPI_FS=nepi_fs_a
    run_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_FS}" | awk '{print $2}'))
    #echo $run_names
    if [[ -n "$run_names" ]]; then
        for run_name in "${run_names[@]}"; do
            if [[ -n "$run_name" ]]; then
                echo "Removing running images for ${run_name}"
                run_id=$(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${run_name}" | awk '{print $1}')
                if [[ -n "$run_id" ]]; then
                    echo "Removing ${run_id}"
                    sudo docker stop -f $run_id > /dev/null 2>&1
                    wait
                    sudo docker rm -f $run_id
                fi
            fi
        done
    fi

    NEPI_FS=nepi_fs_b
    run_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_FS}" | awk '{print $2}'))
    if [[ -n "$run_names" ]]; then
        for run_name in "${run_names[@]}"; do
            if [[ -n "$run_name" ]]; then
                echo "Removing running images for ${run_name}"
                run_id=$(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${run_name}" | awk '{print $1}')
                if [[ -n "$run_id" ]]; then
                    echo "Removing ${run_id}"
                    sudo docker stop -f $run_id > /dev/null 2>&1
                    wait
                    sudo docker rm -f $run_id
                fi
            fi
        done
    fi

    sudo docker system prune -f

    echo ""
    echo "--------------------------"
    echo "NEPI Stop Process Complete"
    echo ""
    #dps

    update_yaml_value "NEPI_RUNNING" 0 "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RUNNING_TAG" "unknown" "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RUNNING_FS" "unknown" "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RUNNING_ID" 0 "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" 0 "${DOCKER_CONFIG_FILE}"

fi
