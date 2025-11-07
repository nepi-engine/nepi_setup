#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

NEPI_STORAGE=/mnt/nepi_storage
NEPI_CONFIG=/mnt/nepi_config
export NEPI_USER=nepi
export NEPI_ACTIVE_FS=nepi_fs_a
export NEPI_ACTIVE_TAG=nepi-3p2p0rc6b-jetson-cuda11p4-20251103



sudo docker run -d --privileged -it -e UDEV=1 --ipc=host \
    --mount type=bind,source=${NEPI_STORAGE},target=${NEPI_STORAGE} \
    --mount type=bind,source=${NEPI_CONFIG},target=${NEPI_CONFIG} \
    --mount type=bind,source=/dev,target=/dev \
    --cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \
    --net=host \
    -p 2222:22 \
    -p 9091:9091 \
    -p 9092:9092 \
    --runtime nvidia \
    --gpus all \
    -v /tmp/.X11-unix/:/tmp/.X11-unix \
    ${NEPI_ACTIVE_FS}:${NEPI_ACTIVE_TAG} /bin/bash \
    -c 'service supervisor start'
    #/nepi_start_all 
export NEPI_RUNNING_FS=$NEPI_ACTIVE_FS
export NEPI_RUNNING_TAG=$NEPI_ACTIVE_TAG
export NEPI_RUNNING_ID=$(sudo docker container ls  | grep $NEPI_RUNNING_FS | awk '{print $1}')
echo "NEPI Container Running with ID ${NEPI_RUNNING_ID}"

sudo docker exec --privileged -it -u $NEPI_USER $NEPI_RUNNING_ID /bin/bash -c "su ${NEPI_USER}"

# AS ROOT
sudo docker exec --privileged -it -e UDEV=1 $NEPI_RUNNING_ID /bin/bash

#   -c 'service supervisor start' 
# --volume /var/run/chrony/chronyd.sock:/var/run/chrony/chronyd.sock \


sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_time_start"
sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_network_start"
sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_dhcp_start"
sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_ssh_start"
sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_samba_start"
sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_engine_start"
sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_license_start"



export NEPI_USER=$NEPI_USER
export NEPI_DEVICE_ID=$NEPI_DEVICE_ID

export NEPI_MANAGES_NETWORK=$NEPI_MANAGES_NETWORK
export NEPI_IP=$NEPI_IP

export NEPI_ACTIVE_NAME=nepi_fs_a
export NEPI_ACTIVE_TAG=3p2p3-jetson-orin-5-4
export NEPI_IP=192.168.179.103

export NEPI_RUNNING_NAME=$NEPI_ACTIVE_NAME
export NEPI_RUNNING_TAG=$NEPI_ACTIVE_TAG
export NEPI_RUNNING_ID=$(sudo docker container ls  | grep $NEPI_RUNNING_NAME | awk '{print $1}')
echo "NEPI Container Running with ID ${NEPI_RUNNING_ID}"

sudo docker exec -it -u $NEPI_USER $NEPI_RUNNING_ID /bin/bash -c "su ${NEPI_USER}"

#######################################

sudo docker commit $NEPI_RUNNING_ID ${NEPI_RUNNING_NAME}:${NEPI_RUNNING_TAG}-2

#################################

sudo docker stop $NEPI_RUNNING_ID



NEPI_STORAGE=/mnt/nepi_storage
NEPI_CONFIG=/mnt/nepi_config
base_image=nepi:new_container_config


echo "Running Base Image ${base_image}"
sudo docker run --privileged -it -e UDEV=1  \
    --mount type=bind,source=${NEPI_STORAGE},target=${NEPI_STORAGE} \
    --mount type=bind,source=${NEPI_CONFIG},target=${NEPI_CONFIG} \
    --mount type=bind,source=/dev,target=/dev \
    --cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \
    --net=host \
    -p 2222:22 \
    -p 9091:9091 \
    -p 9092:9092 \
    --runtime nvidia \
    --gpus all \
    -v /tmp/.X11-unix/:/tmp/.X11-unix \
    ${base_image} /bin/bash -c "su nepi"



sudo docker ps -a"
nid=$(sudo docker ps -a | grep "${base_image%%:*}" | awk "{print $1}"| awk '{print $1}')
echo $nid
sudo docker start ${nid}
sudo docker exec --privileged -it -u nepi $nid /bin/bash -c "su nepi"



# sudo docker ps -a"
# ndinfo=$(sudo docker ps -a | grep "${base_image%%:*}" | awk "{print $1}")
# read -r ndid _ <<< "$ndinfo"
# echo "NEPI docker base conatiner running with id: ${ndid}" 
# sudo docker start ${ndid}
# sudo docker exec --privileged -it -u nepi $ndid /bin/bash -c "su nepi"