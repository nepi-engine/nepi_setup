#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script Stops a Running NEPI Container

sudo -v


CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


bash ${DOCKER_FOLDER}/nepi_docker_update.sh
wait


########################
# Load NEPI DOCKER
CONFIG_SOURCE=${DOCKER_FOLDER}/nepi_docker_config.yaml
source ${DOCKER_FOLDER}/load_docker_config.sh
if [[ "$?" -eq 1 ]]; then
    echo "Failed to load ${CONFIG_SOURCE}"

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

            echo ""
            echo "--------------------------"
            echo "NEPI Stop Process Complete"
            echo ""
            #dps

    update_yaml_value "NEPI_RUNNING" 0 "${CONFIG_SOURCE}"
    update_yaml_value "NEPI_RUNNING_TAG" "unknown" "${CONFIG_SOURCE}"
    update_yaml_value "NEPI_RUNNING_FS" "unknown" "${CONFIG_SOURCE}"
    update_yaml_value "NEPI_RUNNING_ID" 0 "${CONFIG_SOURCE}"
    update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" 0 "${CONFIG_SOURCE}"

fi
