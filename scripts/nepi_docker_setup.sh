#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up the OS software requirements for a NEPI File System installation

sudo -v

echo "########################"
echo "NEPI DOCKER SETUP"
echo "########################"


echo "Running Intitialization Scripts"

export CONFIG_USER=nepi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

. ${SCRIPT_FOLDER}/script_setup.sh
if [[ "$?" -ne 0 ]]; then
    echo "Script Setup Failed. Exiting"
    exit 1
fi 



#######################################

#######################################
## Pull and Run Base Image



#base_image=nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3
base_image=ultralytics/ultralytics:latest-jetson-jetpack5




echo "Pulling Base Image ${base_image}"
nepipull $base_image
wait
nepidev
wait
nepilogin


#############
# users
# . nepi_users_setup.sh


# nepicommit
# nepistop
# nepistart
# nepilogin
#######################################


# nsetup
# . nepi_env_setup.sh
# sbrc

# folders
# . nepi_folders_setup.sh

# folders
# . nepi_files_setup.sh





# echo "Running Base Image ${base_image}"
# sudo docker run --privileged -it -e UDEV=1  \
#     --mount type=bind,source=${NEPI_STORAGE},target=${NEPI_STORAGE} \
#     --mount type=bind,source=${NEPI_CONFIG},target=${NEPI_CONFIG} \
#     --mount type=bind,source=/dev,target=/dev \
#     --cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \
#     --net=host \
#     -p 2222:22 \
#     -p 9091:9091 \
#     -p 9092:9092 \
#     --runtime nvidia \
#     --gpus all \
#     -v /tmp/.X11-unix/:/tmp/.X11-unix \
#     ${base_image} /bin/bash 




# sudo add-apt-repository ppa:rmescandon/yq
# sudo apt update
# sudo apt install yq -y

# cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
# echo ">>>>> Enter 'nepi' for password when asked  <<<<<"
# . nepi_user_setup.sh
# wait
# su nepi

# cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
# . nepi_bash_setup.sh
# source ~/.bashrc


# ## NOTE:If you have CV2 installed and have issues installing ros in the next commands,
# #   try removing CV2 first
# # sudo python3 -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"
# # sudo python3 -c "import inspect; import cv2; print(inspect.getfile(cv2))"
# # sudo python3 -m pip uninstall opencv-python
# # sudo apt-get purge -y '*opencv*'
# # sudo rm -r /usr/local/lib/python3.8/dist-packages/cv2
# # sudo rm -r /usr/lib/python3.8/dist-packages/cv2
# # sudo rm -r /usr/local/include/opencv2 /usr/local/include/opencv 
# # sudo rm -r /usr/include/opencv /usr/include/opencv2 
# # sudo rm -r /usr/local/share/opencv /usr/local/share/OpenCV /usr/share/opencv /usr/share/OpenCV 
# # sudo rm -r /usr/local/bin/opencv* /usr/local/lib/libopencv*

# nsetup
# . ros_setup.sh
# sbrc



# nsetup
# . nepi_config_setup.sh


# nsetup
# . nepi_config_setup.sh

# nsetup
# . nepi_rui_setup.sh

# nepistop

# nepibld

# nepistart





# echo '
# #################################################"
# #*** If you dont get any errors running nepi,"
# #*** another terminal and export your new container

# base_image=<Your Container name:tag>

# nsetup
# source $(dirname $(pwd))/config/load_system_config.sh

# sudo docker ps -a
# ndinfo=$(sudo docker ps -a | grep "${base_image%%:*}" | awk "{print $1}")
# read -r ndid _ <<< "$ndinfo"
# echo "NEPI docker base conatiner running with id: ${ndid}" 
# export base_nepi_id=$(sudo docker container ls  | grep $ndid | awk "{print $1}")

# DATE=$(date +"%Y%m%d")
# NEPI_EXPORT_FILE=nepi-3p2p0RC5-${NEPI_HW_TYPE}-${NEPI_SW_DESC}-${DATE}.tar
# echo "Using export filename ${NEPI_EXPORT_FILE}"

# EXPORT_IMAGE_PATH=${NEPI_EXPORT_PATH}/${NEPI_EXPORT_FILE}
# echo "Using export file path ${EXPORT_IMAGE_PATH}"

# #sudo docker ps
# sudo docker export $ndid > $EXPORT_IMAGE_PATH
'
