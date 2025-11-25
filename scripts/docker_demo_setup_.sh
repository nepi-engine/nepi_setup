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


export DEMO_INSTALL=1

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    exit 1
fi

if ! [ $(id -u) = 0 ]; then
   echo 'This scripts must be run as root user. Type "sudo su" and retry'
   exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



####################################
# Run NEPI User Setup Script

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_user_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $DEMO_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi

echo "Changing user to 'nepihost'"
sudo su nepihost
source /home/nepihost/.bashrc

####################################
# Run NEPI Environment Setup Script

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_env_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $DEMO_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi

####################################
# Run NEPI Bash Setup Script

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=nepi_bash_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $DEMO_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi


####################################
# Run NEPI Folder Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=nepi_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $DEMO_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi


####################################
# Run NEPI Files Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=nepi_files_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $DEMO_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi


####################################
# Run NEPI Config Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=nepi_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $DEMO_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi

####################################
echo ""
echo "##################################"
echo 'NEPI Docker DEMO Setup Complete'
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

 


# echo ""
# if [[ "$check_failed" -eq 1 ]]; then
#     echo "*****  Storage Folder Space Check Failed ******"
#     echo ""
#     echo ""
#     echo "The following folders need additional space to continue"
#     echo ""

#     tot_need=0

#     check_drive=$NEPI_DOCKER
#     check_space=$min_docker_gb
#     if ! is_space_avail_gb $check_drive $check_space; then
#             total_space=$(path_size_gb $check_drive)
#             avail_space=$(path_space_gb $check_drive)
#             space_needed=$((avail_space - check_space))
#             tot_need=$((tot_need + space_needed))
#             echo ""
#             echo "NEPI Folder ${check_drive}"
#             echo "--------------------------"
#             echo "min:    ${check_space} GB"
#             echo "avail:  ${avail_space} GB"
#             echo "needed: ${space_needed} GB" 
#     fi

#     check_drive=$NEPI_STORAGE
#     check_space=$min_storage_gb
#     if ! is_space_avail_gb $check_drive $check_space; then
#             total_space=$(path_size_gb $check_drive)
#             avail_space=$(path_space_gb $check_drive)
#             space_needed=$((avail_space - check_space))
#             tot_need=$((tot_need + space_needed))
#             echo ""
#             echo "NEPI Folder ${check_drive}"
#             echo "--------------------------"
#             echo "min:    ${check_space} GB"
#             echo "avail:  ${avail_space} GB"
#             echo "needed: ${space_needed} GB" 
#     fi

#     echo ""
#     echo ""
#     echo "Options to proceed:"
#     echo
#     echo "    1) Free up ${tot_need} GB on your current file system"
#     echo
#     echo "    2) Manually create the missing folders as individually mounted partitions with the minimum required space shown"
#     echo ""
#     echo "DO NOT PROCEED UNTIL THE ISSUES LISTED ARE ADDRESSED"
#     echo ""
#     echo ""
#     echo ""

# fi




