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


# This file configures a NEPI Docker installation environment


SHOW_CONFIG_MENU=0
if [[ "$1" -eq 1 ]]; then
    SHOW_CONFIG_MENU=1
fi

sudo -v


CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


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


####################################
# Run NEPI Files Setup Script

script_file=nepi_files_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi


####################################
# Run NEPI Config Setup Script

script_file=nepi_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $SHOW_CONFIG_MENU; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi

####################################
echo ""
echo "##################################"
echo 'NEPI Config Setup Complete'
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

# echo ""
# echo "*** REBOOT YOUR DEVICE ***"


