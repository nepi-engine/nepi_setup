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


# NEPI Softare Updates 
# VERSION: 3p2p0-RC11

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


# This file sets up the OS software requirements for a NEPI File System installation


export CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    export CONFIG_USER=$SUDO_USER
fi

if [[ "$CONFIG_USER" != 'nepi' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi'"
    return 
fi



SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


sudo apt-get install iputils-ping -y
wait


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
else


    ######################################

    echo ""
    echo "########################"
    echo "NEPI ENVIRONMENT SETUP 2"
    echo "########################"
    echo ""



    ####################################
    # Run NEPI Bash Setup Script


    script_file=nepi_bash_setup.sh
    script_path=${SCRIPT_FOLDER}/${script_file}
    if ! source_script $script_path; then
        script_error=$?
        echo "Script ${script_path} failed with error ${script_error}"
        return 
    fi


    ####################################
    # Run NEPI Folder Setup Script

    script_file=nepi_folders_setup.sh
    script_path=${SCRIPT_FOLDER}/${script_file}
    if ! source_script $script_path; then
        script_error=$?
        echo "Script ${script_path} failed with error ${script_error}"
        return 
    fi

    TMP=/mnt/nepi_storage/tmp
    fix_folder $TMP
    cd $TMP


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
        return 
    fi



    echo ""
    echo "########################"
    echo "Installing Python Updates"
    echo "########################"
    echo ""
    sudo -H python${NEPI_PYTHON} -m pip install --no-input cryptography
    sudo -H python${NEPI_PYTHON} -m pip install --no-input python-dotenv


fi