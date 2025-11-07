#! /bin/bash
##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

sudo -v

echo "########################"
echo "NEPI DOCKER STORAGE INITIALIZATION"
echo "########################"
echo ""

echo "Running Intitialization Scripts"

export CONFIG_USER=nepihost

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

####################################
ETC_SCRIPTS_FOLDER=$(dirname "${SCRIPT_FOLDER}")/resources/etc/scripts
script_file=check_config_folders.sh
script_path=${ETC_SCRIPTS_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
fi



#################################


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
    echo "MAKE THE REQUIRED CHANGES AND RERUN THIS SCRIPT"
    echo ""
    echo "DO NOT PROCEED UNTIL THIS SCRIPT COMPLETES SUCCESSFULLY"
    echo ""
    echo ""
    echo ""

echo ""
echo "########################"
echo "NEPI Docker Storage Initialization Complete"
echo "########################"
echo ""


fi
    
    
