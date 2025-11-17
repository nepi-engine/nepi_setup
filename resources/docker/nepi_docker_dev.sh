#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script launches NEPI Container

RUN_CMD=""
if [[ -n "$1" ]]; then
    RUN_CMD=$1
fi



sudo -v

CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

UPDATE_CONFIG=1
# if [[ "$1" -eq 0 ]]; then
#     UPDATE_CONFIG=0
# fi

if [[ "$UPDATE_CONFIG" -eq 1 ]]; then
    ########################
    # Update Docker Config
    echo ""
    echo "Updating Docker Config File"
    bash ${DOCKER_FOLDER}/nepi_docker_update.sh
    wait
else
    echo "Not Updating Docker Config File"
fi

########################
# Load NEPI DOCKER
echo "Loading Updated Docker Config Values"
CONFIG_SOURCE=${DOCKER_FOLDER}/nepi_docker_config.yaml
source ${DOCKER_FOLDER}/load_docker_config.sh
if [[ "$?" -eq 1 ]]; then
    echo "Failed to load ${CONFIG_SOURCE}"
else


    ########################
    # Start Processes

    # Reset. Updated by NEPI Software
    SYSTEM_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
    update_yaml_value "NEPI_VERSION" 'XpXpX' "$SYSTEM_CONFIG_FILE"
    update_yaml_value "NEPI_SW_DESC" 'unknown' "$SYSTEM_CONFIG_FILE"


    ########################
    # Stop Any Running NEPI Containers
    echo "Calling NEPI Docker Stop Process"
    bash ${DOCKER_FOLDER}/nepi_docker_stop.sh
    wait

    ########################
    # Build Run Command
    ########################
    echo "Building NEPI Docker Run Command"
    ########
    # Initialize Run Command

    DOCKER_RUN_COMMAND="sudo docker run -d --privileged -it -e UDEV=1 --ipc=host  --user 0:0 \
    --mount type=bind,source=/mnt/nepi_storage,target=/mnt/nepi_storage \
    --mount type=bind,source=/mnt/nepi_config,target=/mnt/nepi_config \
    --mount type=bind,source=/dev,target=/dev \
    --cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \
     -e DISPLAY=$DISPLAY \
    --net=host \
    -p 2222:22 \
    -p 9091:9091 \
    -p 9092:9092 \
    -p 11311:11311 \
    --name samba-server \
    -p 137:137/udp \
    -p 138:138/udp \
    -p 139:139/tcp \
    -p 445:445/tcp "

    # Set cuda support if needed

    if is_valid_cuda; then
        echo "Enabling CUDA GPU Support TRUE"
    DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
    --gpus all \
    --runtime nvidia \
    -v /tmp/.X11-unix/:/tmp/.X11-unix "

    fi 


    # Finish Run Command
    if [[ "$NEPI_ACTIVE_FS" == "nepi_fs_a" ]]; then
        nepi_fs=${NEPI_FSA}
        nepi_fs_tag=${NEPI_FSA_TAG}
    else
        nepi_fs=${NEPI_FSB}
        nepi_fs_tag=${NEPI_FSB_TAG}
    fi

    run_cmd=""
    if [[ -n "$RUN_CMD" ]]; then
        run_cmd="-c "\'${RUN_CMD}\'
    fi

    DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
    ${nepi_fs}:${nepi_fs_tag} /bin/bash ${run_cmd} "


    # ${nepi_fs}:${nepi_fs_tag} /bin/bash \
    # -c 'service supervisor start'"

    ########################
    # Run NEPI Docker
    ########################

    function dcheck() {
        dname=$1
        #dtag=$(sudo docker ps --format '{{.Image}}' | grep ${dname} | awk -F ':' '{print $1}' )
        echo $(sudo docker ps -a)
        did=$(sudo docker container ls  | grep $dname | awk '{print $1}')
        if [[ -z "$did" ]]; then
            return 1      
        fi
        return 0
    }

    echo "Launching NEPI Docker Container ${nepi_fs}:${nepi_fs_tag} with Command"
    echo "${DOCKER_RUN_COMMAND}"
    eval "$DOCKER_RUN_COMMAND"

    # sleep 2
    # dcheck $nepi_fs
    # if [[ "$?" -eq 1 ]]; then
    #     echo "NEPI Container ${dname} FAILED to run"
    #     exit 1
    # fi

    # sleep 2
    # dcheck $nepi_fs
    # if [[ "$?" -eq 1 ]]; then
    #     echo "Retrying NEPI Docker Container ${nepi_fs}:${nepi_fs_tag}"
    #     eval "$DOCKER_RUN_COMMAND"
    #     sleep 2
    #     dcheck $nepi_fs
    #     if [[ "$?" -eq 1 ]]; then
    #         echo "NEPI Container ${dname} FAILED to run"
    #         exit 1
    #     fi
    # 
   
    sleep 1


    CONTAINER_ID=$(sudo docker ps -aqf "ancestor=${nepi_fs}:${nepi_fs_tag}")
    if [[ -z "$CONTAINER_ID" ]]; then
        echo "NEPI Failed to Run"
    else
        echo ""
        dps
        echo ""
        echo "--------------------------"
        echo "NEPI DEV Container Running with ID: ${CONTAINER_ID}"
        echo "--------------------------"   
        echo ""
        update_yaml_value "NEPI_RUNNING" 1 "$CONFIG_SOURCE"
        update_yaml_value "NEPI_RUNNING_FS" "$nepi_fs" "$CONFIG_SOURCE"
        update_yaml_value "NEPI_RUNNING_TAG" "$nepi_fs_tag" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_RUNNING_ID" $CONTAINER_ID "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "$(date +%Y-%m-%d)" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"
    fi

fi
