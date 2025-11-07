#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates bash stored system values

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases

elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepi/.bashrc
    ufile=/home/nepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_docker_aliases

else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${SCRIPT_FOLDER})



ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -n "$1" ]]; then
    LOAD_NEPI_CONFIG=$1
fi

if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi



#########
# UPDATE FUNCTIONS

function update_yaml_value(){
    export UPDATE_YAML_KEY=$1
    #echo $UPDATE_YAML_KEY
    export UPDATE_YAML_VAL=$2
    #echo $UPDATE_YAML_VAL
    export UPDATE_YAML_FILE=$3
    #echo $UPDATE_YAML_FILE

    yq e -i '.'"$UPDATE_YAML_KEY"' = env(UPDATE_YAML_VAL)' $UPDATE_YAML_FILE
}
export -f update_yaml_value

function export_yaml_value(){
    KEY=$1
    #echo $KEY
    VARIABLE=$2
    #echo=$VARIABLE
    FILE=$3
    #echo=$FILE
    verbose=0
    value=$(yq e '.'"$KEY"'' $FILE)
    export ${VARIABLE}=$value
    #Secho "${VARIABLE}=${value}"
}
export -f export_yaml_value


function is_valid_uid() {
    local input=$1

    # Regular expression for a common Linux username format
    # Starts with a lowercase letter or underscore, followed by 0-31 lowercase letters, numbers, hyphens, or underscores.
    USERNAME_REGEX="^[a-z_][a-z0-9_-]{0,31}$"

    if [[ ! "$input" =~ $USERNAME_REGEX ]]; then
        echo "Variable '$input' is NOT a valid Linux username format."
    fi
    return 0
    }
export -f is_valid_uid

function is_valid_pw() {
    local input=$1

    if [ -z "$input" ]; then
        echo "Passwords can not be blank string."
        return 1
    fi
  case "$input" in
      *[[:space:]]*|*/*|*\\*)
          echo "Passwords can not contain spaces or slashes."
          ;;
      *)
  esac
    return 0
    }
export -f is_valid_pw


function is_valid_did() {
    local input=$1

    # Check for empty string
    if [ -z "$input" ]; then
        echo "NEPI Device ID's can not be blank string."
        return 1
    fi
    # Check that first char is a letter
    if [[ ! "$input" =~ ^[a-zA-Z] ]]; then
        echo "The first character or NEPI Device ID must be a letter."
        return 1
    fi
    # Check if input is only letters numbers and underscores with no spaces
    if [[ ! "$input" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "NEPI Device ID's must be only letters, numbers, and underscores with no spaces."
        return 1
    fi
    return 0
    }
export -f is_valid_did

function is_valid_string() {
    local input=$1

    # Check for empty string
    if [ -z "$input" ]; then
        echo "NEPI Model Name can not be blank string."
        return 1
    fi
    return 0
    }
export -f is_valid_string

function is_valid_sn() {
    local input=$1
    # Check for empty string
    if [ -z "$input" ]; then
        echo "NEPI Serial Numbers can not be blank string."
        return 1
    fi
    # Check if serial number is valid 6 digit number
    if [[ ! "$input" =~ ^[0-9]{6}$ ]]; then
        echo "'$input' is NOT a 6-digit number."
        return 1
    fi

    if [[ ! "$input" =~ ^[1-9][0-9]* ]]; then
        echo "'NEPI Serial Numbers must start with non-zero number."
        return 1
    fi

    return 0
    }
export -f is_valid_sn

function is_valid_ipv4() {
    local input=$1

    # Check if the format matches a general IP pattern (e.g., 1.2.3.4)
    if ! [[ $input =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Not a valid IP Address format #.#.#.#"
        return 1 # Invalid format
    fi

    # Split the IP address into octets and check their values
    IFS='.' read -r -a octets <<< "$input"
    for octet in "${octets[@]}"; do
        if (( octet < 0 || octet > 255 )); then
            return 1 # Octet out of range
        fi
    done

    return 0 # Valid IP address
}
export -f is_valid_ipv4

function is_valid_path() {
    local input=$1
    if [[ ! -e "$input" ]]; then
        echo "'Path ${input} not found."
        return 1
    fi
    return 0 # Valid folder
}
export -f is_valid_path

function is_valid_folder() {
    local input=$1
    if [[ ! -d "$input" ]]; then
        echo "'Path ${input} not found."
        return 1
    fi
    return 0 # Valid folder
}
export -f is_valid_folder

function is_valid_file() {
    local input=$1
    if [[ ! -f "$input" ]]; then
        echo "'Path ${input} not found."
        return 1
    fi
    return 0 # Valid folder
}
export -f is_valid_file

function is_valid_bool() {
    local input=$1
    if [[ "$input" != "1" && "$input" != "0" ]]; then
        echo "'Input not valid. Enter a 1 or 0"
        return 1
    fi
    return 0 # Valid Bool
}
export -f is_valid_bool



function is_valid_internet(){
    if ! ping -c 2 google.com; then
        echo "No Internet Connection"
        return 1
    else
        echo "Internet Connected"
        return 0
    fi
}
export -f is_valid_internet


function is_valid_arm64(){
    arch_check="arm64"
    arch_val=$(uname -m)
    if [[ "$arch_val" == "aarch64" ]]; then
        echo "System Arch is ${arch_check}"
        return 0
    else
        return 1
    fi
}
export -f is_valid_arm64


function is_valid_jetson(){
if [ -f /etc/nv_tegra_release ]; then
        return 0
    else
        return 1
    fi
}
export -f is_valid_jetson

function is_valid_amd64(){
    arch_check="amd64"
    arch_val=$(uname -m)
    if [[ "$arch_val" == "x86_64" ]]; then
        echo "System Arch is ${arch_check}"
        return 0
    else
        return 1
    fi
}
export -f is_valid_amd64


function is_valid_cuda(){
    lspci | grep -i nvidia >> /dev/null
    if [[ "$?" -eq 0 ]]; then
        #echo "System has CUDA"
        #Check version
        #ls -l /usr/local | grep cuda
        string=$(nvcc --version)
        key=release
        value=$(echo "$string" | grep "${key}" | awk '{print $NF}' | cut -d'.' -f1-2)
        echo "${value#V}"
        return 0
    else
        echo 0
        return 1
    fi
}
export -f is_valid_cuda

function is_space_avail_mb(){
    local check_path=$1
    local req_space=$2
    if ! is_valid_folder $check_path; then
      #echo "Not a valid folder ${check_path}"
      return 1
    else
      avail_space=$(path_space_mb $check_path)
      #echo "Aval Space: ${avail_space}"
      #echo "Req Space: ${req_space}"
      if [[ "$avail_space" -lt "$req_space" ]]; then
        #echo "Not enough space ${check_path}"
        return 1
      else
        return 0
      fi
    fi
}
export -f is_space_avail_mb

function is_space_avail_gb(){
    local check_path=$1
    local req_space=$2
    if ! is_valid_folder $check_path; then
      #echo "Not a valid folder ${check_path}"
      return 1
    else
      avail_space=$(path_space_gb $check_path)
      #echo "Aval Space: ${avail_space}"
      #echo "Req Space: ${req_space}"
      if [[ "$avail_space" -lt "$req_space" ]]; then
        #echo "Not enough space ${check_path}"
        return 1
      else
        return 0
      fi
    fi
}
export -f is_space_avail_gb


echo ""
echo "UPDATING BASH VARIABLES"

bfile=/home/${CONFIG_USER}/.bashrc
if is_valid_did $NEPI_DEVICE_ID; then
    update_text_value $bfile "export NEPI_DEVICE_ID" "export NEPI_DEVICE_ID=${NEPI_DEVICE_ID}"
fi
if is_valid_ipv4 $NEPI_IP; then
    update_text_value $bfile "export NEPI_IP" "export NEPI_IP=${NEPI_IP}"
fi

sudo cp $bfile /root/.bashrc




    
