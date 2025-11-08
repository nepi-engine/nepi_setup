#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs the NEPI Engine File System installation

export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" != 'nepi' && "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi' or 'nepihost'"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    exit 1
fi

echo "########################"
echo "NEPI DOCKER INITIALIZATION SETUP"
echo "########################"


##########################
NEPI_ARCH=unknown
if is_valid_jetson; then
    NEPI_ARCH=arm64
elif is_valid_arm64; then
    NEPI_ARCH=arm64
elif is_valid_amd64; then
    NEPI_ARCH=amd64
else
    arch_val=$(uname -m)
    echo "Arch ${arch_val} not supported yet"
    exit 1
fi



####################################
# Run NEPI Folder Setup Script

script_file=nepi_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
fi


####################################
# Download NEPI Image

CURRENT_FOLDER=$(pwd)
NEPI_STORAGE=/mnt/nepi_storage

cd $NEPI_STORAGE


wget https://www.dropbox.com/scl/fo/c7qap49hftrmi13ku49tg/h?rlkey=kbufq3lv04y9c2etc17kotk0j&st=hmqc234m&dl=0



cd $CURRENT_FOLDER

####################################
# Download Storage Extras



echo "########################"
echo "NEPI Docker Initialization Setup Complete"
echo "########################"