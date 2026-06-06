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

# This script launches NEPI Container
sudo -v

START_MODE=$1

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
afile=/home/${CONFIG_USER}/.nepi_host_aliases

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


echo "Resetting NEPI Docker Config File"
blank_config=${DOCKER_FOLDER}/nepi_docker_config.blank
if [[ -d $blank_config ]]; then
    cp $blank_config ${DOCKER_FOLDER}/nepi_docker_config.yaml
    cp $blank_config ${DOCKER_FOLDER}/nepi_docker_config.yaml.bak
fi

echo "Calling NEPI Docker Stop Process"
source ${DOCKER_FOLDER}/nepi_docker_stop.sh
wait


# Reset. Updated by NEPI Software
SYSTEM_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
update_yaml_value "NEPI_VERSION" 'XpXpX' "$SYSTEM_CONFIG_FILE"
update_yaml_value "NEPI_SW_DESC" 'unknown' "$SYSTEM_CONFIG_FILE"


if [[ "$NEPI_ACTIVE_FS" == "nepi_fs_a" ]]; then
    nepi_fs=${NEPI_FSA}
    nepi_fs_tag=${NEPI_FSA_TAG}
else
    nepi_fs=${NEPI_FSB}
    nepi_fs_tag=${NEPI_FSB_TAG}
fi


echo ""
echo "Cleaning and Fixing Folders"

# if [[ -d '/tmp' ]]; then
#     cur_folder=$(pwd)
#     cd /tmp
#     sudo find . -mindepth 1 -not -name "snap-private-tmp" -exec sudo rm -rf {} +
#     cd $cur_folder
# fi

sudo chown 1000:1000 /mnt/nepi_config
sudo chown 1000:1000 /mnt/nepi_storage
echo ""

echo ""
echo "Syncing SSH Keys"
nepisync
### This is done by nepi_docker service before calling nepi_docker_start
#######################
# Update ETC Config Files
#######################
# source ${DOCKER_FOLDER}/update_etc_files.sh
# wait

########################
# Build Run Command
########################
echo "Building NEPI Docker Run Command"

# NEPI_STORAGE=/mnt/nepi_storage
# NEPI_CONFIG=/mnt/nepi_coinfig

# if [[ "$1" -eq 0 ]]; then 
#     echo "Starting with rm process disabled"
#     rm_cmd=''
# if [[ "$1" -eq 1 ]]; then 
#     echo "Starting with rm process enabled"
#     rm_cmd="--rm"
# elif [[ "$NEPI_RM_PS" -eq 0 ]]; then
#     echo "Starting with rm process disabled"
#     rm_cmd=''
# else
#     echo "Starting with rm process enabled"
#     rm_cmd="--rm"
# fi

rm_cmd="--rm"


########
# Initialize Run Command
DOCKER_RUN_COMMAND="sudo docker run -d --privileged ${rm_cmd} -e UDEV=1 --ipc=host --user 0:0 \
--mount type=bind,source=/mnt/nepi_storage,target=/mnt/nepi_storage \
--mount type=bind,source=/mnt/nepi_config,target=/mnt/nepi_config \
--mount type=bind,source=/dev,target=/dev \
--mount type=bind,source=/etc/udev,target=/etc/udev \
--mount type=bind,source=/dev/bus/usb,target=/dev/bus/usb \
--cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \
-e DISPLAY=$DISPLAY \
--net=host \
-p 2222:22 \
-p 9091:9091 \
-p 9092:9092 \
-p 11311:11311 \
-p 137:137/udp \
-p 138:138/udp \
-p 139:139/tcp \
-p 445:445/tcp "

DOCKER_RUN_COMMAND_FALLBACK=$DOCKER_RUN_COMMAND
# Set cuda support if needed

if is_valid_cuda; then
    echo "Enabling CUDA GPU Support"
DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
--gpus all \
--runtime nvidia \
-v /tmp/.X11-unix/:/tmp/.X11-unix "

fi 


# Set jetson support if needed

if is_valid_jetson; then
    echo "Enabling Jetson GPU Support"
DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /tmp:/tmp \
-v /usr/bin/nvargus-daemon:/usr/bin/nvargus-daemon "
fi 


if is_valid_hailo; then
    hailo_sock="/tmp/hailort_uds.sock"
    if ! is_valid_hailo_sw; then
        echo "Hailo Toolkit Not Detected"
    elif [[ ! -S $hailo_sock ]]; then
        echo "Hailo Sock Not Found at ${hailo_sock}"
    else
        hailo_hw_version=$(get_hailo_hw_version)
        hailo_sw_version=$(get_hailo_sw_version)
        if [[ ${hailo_hw_version} == "0" ]]; then
            echo "Failed to get Hailo Hardware Version"
        elif [[ ${hailo_sw_version} == "0" ]]; then
            echo "Failed to get Hailo Software Version"
        else
            echo "Found Hailo Device ${hailo_hw_version}"
            echo "Found Hailo Software ${hailo_sw_version}"
            echo "Enabling Hailo Accelerator Support"
        DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
        --device=/dev/hailo0 \
        -v /lib/firmware/hailo:/lib/firmware/hailo \
        -v /tmp/hailort_uds.sock:/tmp/hailort_uds.sock"

        fi
    fi
fi 


# Finish Run Command

echo "Using name:tag ${nepi_fs}:${nepi_fs_tag} with Command"


if [[ "$RUN_MODE" == "DEV" ]]; then

run_cmd=""

else

run_cmd="-c '/nepi_start_all'"

fi


DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
${nepi_fs}:${nepi_fs_tag} /bin/bash ${run_cmd} "

DOCKER_RUN_COMMAND_FALLBACK="${DOCKER_RUN_COMMAND_FALLBACK} \
${nepi_fs}:${nepi_fs_tag} /bin/bash ${run_cmd} "

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


# Fix Folder Owners Pre Run
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
sudo chmod 0775 /opt/nepi
sudo chown 1000:1000 /mnt/nepi_config
sudo chmod 0775 /mnt/nepi_config
sudo chown 1000:1000 /mnt/nepi_storage
sudo chmod 0775 /mnt/nepi_storage


echo ""
echo "Launching NEPI Docker Container ${nepi_fs}:${nepi_fs_tag} with Command"
echo "${DOCKER_RUN_COMMAND}"
eval "$DOCKER_RUN_COMMAND"

sleep 4

CONTAINER_ID=($(sudo docker ps -qf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
CONTAINER_ID=${CONTAINER_ID[0]}
###############################

RETRY_COUNT=0
while [[ -z "$CONTAINER_ID" && "$RETRY_COUNT" -lt "$NEPI_RETRY_COUNT" ]]; do
    ###############################
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo ""
    echo "Retrying with Fallback Run Command ${nepi_fs}:${nepi_fs_tag}"
    echo "${DOCKER_RUN_COMMAND_FALLBACK}"
    eval "$DOCKER_RUN_COMMAND_FALLBACK"

    sleep 2

    CONTAINER_ID=($(sudo docker ps -qf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
    CONTAINER_ID=${CONTAINER_ID[0]}
    ###############################
done




if [[ -z "$CONTAINER_ID" ]]; then

    echo "--------------------------"
    echo "NEPI Container Failed to Run"
    echo "--------------------------"   

else

    if is_valid_jetson; then
        echo ""
        echo "Restarting nvargus-daemon"
        sudo systemctl restart nvargus-daemon  >/dev/null 2>&1
    fi
    echo ""
    dps
    echo ""
    echo "--------------------------"
    echo "NEPI Container Running with ID: ${CONTAINER_ID}"
    echo "--------------------------"   
    echo ""

    update_yaml_value "NEPI_RUNNING" 1 "$DOCKER_CONFIG_FILE"
    update_yaml_value "NEPI_RUNNING_FS" "$nepi_fs" "$DOCKER_CONFIG_FILE"
    update_yaml_value "NEPI_RUNNING_TAG" "$nepi_fs_tag" "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RUNNING_ID" $CONTAINER_ID "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "$(date +%Y-%m-%d)" "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_FS_RESTART" 0 "${DOCKER_CONFIG_FILE}"
    update_yaml_value "NEPI_RESTARTING" 0 "${DOCKER_CONFIG_FILE}"
fi


