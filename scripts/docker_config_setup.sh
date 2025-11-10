#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file configures a NEPI Docker installation environment

sudo -v
export CONFIG_USER=nepihost


if [[ "$USER" != "$CONFIG_USER" ]]; then
    echo "This script must be run by user account ${CONFIG_USER}."
    echo "Log in as ${CONFIG_USER} and run again"
    exit 1
fi

echo "########################"
echo "NEPI DOCKER CONFIG SETUP"
echo "########################"



SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)



####################################
# Run NEPI Bash Setup Script


script_file=nepi_bash_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    exit 1
fi

####################################
# Stop any running containers
echo ""
nepistop
echo ""

####################################
# Run NEPI Folder Setup Script

script_file=nepi_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    exit 1
fi



####################################
# Run NEPI Config Setup Script

script_file=nepi_config_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    exit 1
fi

####################################
echo ""
echo "##################################"
echo 'NEPI Docker Config Setup Complete'
echo "##################################"
echo ""


####################################
# RUN CHECKS
####################################

dev_docker=$(stat -c '%d' "$NEPI_DOCKER")
dev_storage=$(stat -c '%d' "$NEPI_STORAGE")

min_docker_gb=$((NEPI_GB_CONTAINER * 1))
min_storage_gb=$NEPI_GB_CONTAINER
min_total=$((min_docker_gb + min_storage_gb))


check_failed=0

check_drive=$NEPI_DOCKER
check_space=$min_docker_gb
if ! is_space_avail_gb $check_drive $check_space; then
    check_failed=1
fi


check_drive=$NEPI_STORAGE
check_space=$min_storage_gb
if ! is_space_avail_gb $check_drive $check_space; then
    check_failed=1
fi

 


echo ""
if [[ "$check_failed" -eq 1 ]]; then
    echo "*****  Storage Folder Space Check Failed ******"
    echo ""
    echo ""
    echo "The following folders need additional space to continue"
    echo ""

    tot_need=0

    check_drive=$NEPI_DOCKER
    check_space=$min_docker_gb
    if ! is_space_avail_gb $check_drive $check_space; then
            total_space=$(path_size_gb $check_drive)
            avail_space=$(path_space_gb $check_drive)
            space_needed=$((avail_space - check_space))
            tot_need=$((tot_need + space_needed))
            echo ""
            echo "NEPI Folder ${check_drive}"
            echo "--------------------------"
            echo "min:    ${check_space} GB"
            echo "avail:  ${avail_space} GB"
            echo "needed: ${space_needed} GB" 
    fi

    check_drive=$NEPI_STORAGE
    check_space=$min_storage_gb
    if ! is_space_avail_gb $check_drive $check_space; then
            total_space=$(path_size_gb $check_drive)
            avail_space=$(path_space_gb $check_drive)
            space_needed=$((avail_space - check_space))
            tot_need=$((tot_need + space_needed))
            echo ""
            echo "NEPI Folder ${check_drive}"
            echo "--------------------------"
            echo "min:    ${check_space} GB"
            echo "avail:  ${avail_space} GB"
            echo "needed: ${space_needed} GB" 
    fi

    echo ""
    echo ""
    echo "Options to proceed:"
    echo
    echo "    1) Free up ${tot_need} GB on your current file system"
    echo
    echo "    2) Manually create the missing folders as individually mounted partitions with the minimum required space shown"
    echo ""
    echo "DO NOT PROCEED UNTIL THE ISSUES LISTED ARE ADDRESSED"
    echo ""
    echo ""
    echo ""

fi

echo ""
echo "*** REBOOT YOUR DEVICE ***"


