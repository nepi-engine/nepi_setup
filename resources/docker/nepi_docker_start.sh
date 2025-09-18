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

source /home/${USER}/.nepi_bash_utils
wait

# Load NEPI SYSTEM CONFIG
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=${SCRIPT_FOLDER}/etc
if [ -d "$ETC_FOLDER" ]; then
    echo "Failed to find ETC folder at ${ETC_FOLDER}"
    exit 1
fi
source ${ETC_FOLDER}/load_system_config.sh
wait
if [ $? -eq 1 ]; then
    echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
    exit 1
fi

# Load NEPI DOCKER
CONFIG_SOURCE=${SCRIPT_FOLDER}/nepi_docker_config.yaml
source ${SCRIPT_FOLDER}/load_docker_config.sh
wait
if [ $? -eq 1 ]; then
    echo "Failed to load ${CONFIG_SOURCE}"
    exit 1
fi

##########################

if [[ $NEPI_RESTARTING == 0 ]]; then
    update_yaml_value "NEPI_RESTARTING" 1 "${CONFIG_SOURCE}"

else
    echo "You can only restart one image at a time"
    exit 1
fi

########################
# Stop Any Running NEPI Containers
########################
if [[ $NEPI_RUNNING_ID != "unknown" && "$NEPI_RUNNING" -e 1 ]]; then
    ./nepi_docker_stop.sh
    wait
fi


#######################
# Update ETC Config Files
#######################
source ${SCRIPT_FOLDER}/update_etc_files.sh
wait


#######################################
# Update NEPI ETC to OS Host ETC Linked files
#######################################
# if [[ "$NEPI_MANAGES_ETC" -eq 1 ]]; then
#     echo "Updating NEPI Managed Services"

#     sudo systemctl stop lsyncd
#     sudo cp -r ${etc_source}/lsyncd /etc/
#     lsyncd_file=${SCRIPT_FOLDER}/etc/lsyncd/lsyncd.conf
#     function add_etc_sync(){
#         etc_sync=${NEPI_CONFIG}/docker_cfg/etc/${1}
#         etc_dest=/etc/${1}
#         echo "" | sudo tee -a $lsyncd_file
#         echo "sync {" | sudo tee -a $lsyncd_file
#         echo "    default.rsync," | sudo tee -a $lsyncd_file
#         echo '    source = "'${etc_sync}'/",' | sudo tee -a $lsyncd_file
#         echo '    target = "'${etc_dest}'/",' | sudo tee -a $lsyncd_file
#         echo "}" | sudo tee -a $lsyncd_file
#         echo " " | sudo tee -a $lsyncd_file
#     }
#     sudo chown -R ${USER}:${USER} ${lsyncd_file}

#     if [ "$NEPI_MANAGES_HOSTNAME" -eq 1 ]; then
#         add_etc_sync hosts
#         add_etc_sync hostname
#     fi

#     if [ "$NEPI_MANAGES_NETWORK" -eq 1 ]; then
#         add_etc_sync /network/interfaces.d
#         add_etc_sync network/interfaces
#         add_etc_sync dhcp/dhclient.conf
#         add_etc_sync wpa_supplicant
#     fi
    
#     if [ "$NEPI_MANAGES_TIME" -eq 1 ]; then
#         add_etc_sync ${etc_path}
        
#     fi

#     if [ "$NEPI_MANAGES_SSH" -eq 1 ]; then
#         add_etc_sync ssh/sshd_config
#     fi


#     # start the sync service
#     echo "Starting NEPI ETC Sycn service"
#     sudo systemctl start lsyncd    

# fi


########################
# Build Run Command
########################
echo "Building NEPI Docker Run Command"
echo $NEPI_STORAGE
########
# Initialize Run Command
DOCKER_RUN_COMMAND="sudo docker run -d --privileged -it --rm -e UDEV=1 \
--mount type=bind,source=${NEPI_STORAGE},target=${NEPI_STORAGE} \
--mount type=bind,source=${NEPI_CONFIG},target=${NEPI_CONFIG} \
--mount type=bind,source=/dev,target=/dev \
-e DISPLAY=${DISPLAY} \
-v /tmp/.X11-unix/:/tmp/.X11-unix \
--net=host \
-p 2222:22 "

# -v ${NEPI_BASE}:${NEPI_BASE} \

# Set Clock Settings

#if [[ "$NEPI_MANAGES_CLOCK" -eq 1 ]]; then
#    echo "Disabling Host Auto Clock Updating"
#    sudo timedatectl set-ntp no

#DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND}
#--cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \ "
#fi 

# Set cuda support if needed
if [[ "$NEPI_DEVICE_ID" == "device1" ]]; then
    echo "Enabling Jetson GPU Support TRUE"

DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
--gpus all \
--runtime nvidia "
fi 

# Finish Run Command
if [[ "$NEPI_ACTIVE_FS" == "nepi_fs_a" ]]; then
echo "nepi_fs_a"
DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
${NEPI_FSA_NAME}:${NEPI_FSA_TAG} /bin/bash"
else
echo "nepi_fs_b"
DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
${NEPI_FSB_NAME}:${NEPI_FSB_TAG} /bin/bash"
fi

########################
# Run NEPI Docker
########################

echo ""
echo "Launching NEPI Docker Container with Command"
echo "${DOCKER_RUN_COMMAND}"
eval "$DOCKER_RUN_COMMAND"

if [[ "$NEPI_ACTIVE_FS" == "nepi_fs_a" ]]; then
update_yaml_value "NEPI_RUNNING_TAG" "$NEPI_FSA_TAG" "${CONFIG_SOURCE}"
else
update_yaml_value "NEPI_RUNNING_TAG" "$NEPI_FSB_TAG" "${CONFIG_SOURCE}"
fi

update_yaml_value "NEPI_RUNNING" 1 "$CONFIG_SOURCE"
update_yaml_value "NEPI_RUNNING_FS" "$NEPI_ACTIVE_FS" "$CONFIG_SOURCE"

source ${SCRIPT_FOLDER}/load_docker_config.sh
wait

CONTAINER_ID=$(sudo docker ps -aqf "ancestor=${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG}")
echo $CONTAINER_ID
update_yaml_value "NEPI_RUNNING_ID" $CONTAINER_ID "${CONFIG_SOURCE}"
update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "$(date +%Y-%m-%d)" "${CONFIG_SOURCE}"
update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"

source ${SCRIPT_FOLDER}/load_docker_config.sh
wait

########################
# Start NEPI Processes
########################

#export NEPI_RUNNING_NAME=$NEPI_ACTIVE_NAME
#export NEPI_RUNNING_TAG=$NEPI_ACTIVE_TAG
#export NEPI_RUNNING_ID=$(sudo docker container ls  | grep $NEPI_RUNNING_NAME | awk '{print $1}')
#echo "NEPI Container Running with ID ${NEPI_RUNNING_ID}"

#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_time_start"
#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_network_start"
#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_dhcp_start"
#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_ssh_start"
#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_samba_start"
#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_engine_start"
#sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_license_start"


