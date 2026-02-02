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

export LITE_INSTALL=0


function source_script(){
  if [[ ! -v "$1" && -n "$1" ]]; then
    script_path=$1
    if [[ -f "$script_path" ]]; then
      echo "Sourcing script: $(basename $script_path)"
      source ${script_path} $2
      script_error=$?
      if [[ "$script_error" -ne 0 ]]; then
        echo "Script $(basename $script_path) returned error ${script_error}"
        return $script_error
      fi
    else
        echo "Script not found at ${script_path}"
        return 1
    fi
  else
    echo "No Script Path Provided"
    return 1
  fi
}
export -f source_script

####################################
# Run NEPI Storage Init Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_storage_init.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi

####################################
# Run NEPI Image Init Setup Script
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
script_file=docker_image_init.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $LITE_INSTALL; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    return 
fi


# sudo -v

# SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
# LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
# source $LICENSE_CHECK_FILE
# if [[ "$?" -ne 0 ]]; then
#     return 
# fi


# # This file configures a NEPI Docker installation environment


# export LITE_INSTALL=1



# CONFIG_USER=$(id -un)
# if [[ ${CONFIG_USER} == 'root' ]]; then
#     CONFIG_USER=$SUDO_USER
# fi


# if ! is_valid_internet; then
#     echo "No Internet Connection Detected.  Connect and rerun this script"
#     return 
# fi



# SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

# NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
# source $NEPI_UTILS_SOURCE


# ####################################
# # Run NEPI Storage Init Setup Script
# SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
# script_file=docker_storage_init.sh
# script_path=${SCRIPT_FOLDER}/${script_file}
# if ! source_script $script_path $LITE_INSTALL; then
#     script_error=$?
#     echo "Script ${script_path} failed with error ${script_error}"
#     return 
# fi

# ####################################
# # Run NEPI Image Init Setup Script
# SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
# script_file=docker_image_init.sh
# script_path=${SCRIPT_FOLDER}/${script_file}
# if ! source_script $script_path $LITE_INSTALL; then
#     script_error=$?
#     echo "Script ${script_path} failed with error ${script_error}"
#     return 
# fi


# ####################################
# echo ""
# echo "##################################"
# echo 'NEPI Docker LITE Config Setup Complete'
# echo "##################################"
# echo ""



####################################
# RUN CHECKS
####################################

# dev_docker=$(stat -c '%d' "$NEPI_DOCKER")
# dev_storage=$(stat -c '%d' "$NEPI_STORAGE")

# min_docker_gb=$((NEPI_GB_CONTAINER * 1))
# min_storage_gb=$NEPI_GB_CONTAINER
# min_total=$((min_docker_gb + min_storage_gb))


# check_failed=0

# check_drive=$NEPI_DOCKER
# check_space=$min_docker_gb
# if ! is_space_avail_gb $check_drive $check_space; then
#     check_failed=1
# fi


# check_drive=$NEPI_STORAGE
# check_space=$min_storage_gb
# if ! is_space_avail_gb $check_drive $check_space; then
#     check_failed=1
# fi

 


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




