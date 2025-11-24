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
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

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

echo "Calling NEPI Docker Stop Process"
source ${DOCKER_FOLDER}/nepi_docker_stop.sh
wait


# Reset. Updated by NEPI Software
SYSTEM_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
update_yaml_value "NEPI_VERSION" 'XpXpX' "$SYSTEM_CONFIG_FILE"
update_yaml_value "NEPI_SW_DESC" 'unknown' "$SYSTEM_CONFIG_FILE"
update_yaml_value "NEPI_FS_AB" $NEPI_AB_FS "$SYSTEM_CONFIG_FILE"


if [[ "$NEPI_ACTIVE_FS" == "nepi_fs_a" ]]; then
    nepi_fs=${NEPI_FSA}
    nepi_fs_tag=${NEPI_FSA_TAG}
else
    nepi_fs=${NEPI_FSB}
    nepi_fs_tag=${NEPI_FSB_TAG}
fi


echo ""
echo "Cleaning and Fixing Folders"
sudo rm -r /tmp/*
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_storage
echo ""



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

echo "Using name:tag ${nepi_fs}:${nepi_fs_tag} with Command"

DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
${nepi_fs}:${nepi_fs_tag} /bin/bash"

#-c '/nepi_start_all'"

#-c 'service supervisor start'"

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

################## 
# Fix Folder Owners
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
sudo chmod 0775 /opt/nepi
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
sudo chmod 0775 /mnt/nepi_config
sudo chown ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_storage
sudo chmod 0775 /mnt/nepi_storage



###############################
echo ""
echo "Launching NEPI Docker Container ${nepi_fs}:${nepi_fs_tag} with Command"

DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
-c 'service supervisor start'"

echo "${DOCKER_RUN_COMMAND}"

eval "$DOCKER_RUN_COMMAND"

sleep 2

CONTAINER_ID=($(sudo docker ps -qf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
CONTAINER_ID=${CONTAINER_ID[0]}
###############################

if [[ -n "$CONTAINER_ID" ]]; then
    break
else
    ###############################
    echo ""
    echo "Retrying NEPI Docker Container ${nepi_fs}:${nepi_fs_tag} with Command"

    DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
    -c '/nepi_start_all'"

    echo "${DOCKER_RUN_COMMAND}"

    eval "$DOCKER_RUN_COMMAND"

    sleep 2

    CONTAINER_ID=($(sudo docker ps -qf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
    CONTAINER_ID=${CONTAINER_ID[0]}
    ###############################
fi


if [[ -z "$CONTAINER_ID" ]]; then

    echo "--------------------------"
    echo "NEPI Container Failed to Run"
    echo "--------------------------"   

else

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


