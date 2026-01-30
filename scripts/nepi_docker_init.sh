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
## Redistributions in source code must retain this top-level comment block, 
## Along with any License Check related code and checks.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    exit 1
fi


# This file sets up the OS software requirements for a NEPI File System installation
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi'"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

echo "########################"
echo "NEPI DOCKER SETUP"
echo "########################"


# if ! [ $(id -u) = 0 ]; then
#    echo 'This scripts must be run as root user. Type "sudo su" and retry'
#    exit 1
# fi

echo "Running Intitialization Scripts"




#######################################

#######################################
echo ''
echo 'From your PC, deploy NEPI source to Host System'
echo 'export DEPLOY_3RD_PARTY=1'
echo 'source ~/nepi_engine_ws/deploy_nepi_complete.sh'
echo ''


##########################
## Pull and Run Base Image

##########################
## Link: https://hub.docker.com/r/ultralytics/ultralytics
NEPI_ARCH=unknown
if is_valid_jetson; then
    NEPI_ARCH=jetson
    base_image=ultralytics/ultralytics:latest-jetson-jetpack5
elif is_valid_arm64; then
    NEPI_ARCH=arm64
    base_image=ultralytics/ultralytics:latest-arm64
elif is_valid_amd64; then
    NEPI_ARCH=amd64
    base_image=ubuntu:20.04
else
    arch_val=$(uname -m)
    echo "Arch ${arch_val} not supported yet"
    exit 1
fi

# base_image=nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3
# base_image=ultralytics/ultralytics:latest-jetson-jetpack5


echo "Pulling Base Image ${base_image}"
nepipull $base_image
