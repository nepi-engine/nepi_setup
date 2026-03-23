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

# This script Updates NEPI ETC Files

sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
fi
export CONFIG_USER=$CONFIG_USER



ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


ETC_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_SCRIPTS_FOLDER=${ETC_FOLDER}/scripts

echo ""
echo "########################"
echo "STARTING NEPI ETC UPDATE PROCESSES"
echo "########################"
echo ""

######################################

CONFIG_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
etc_folder=$CONFIG_FOLDER
if [[ ! -z "$1" ]]; then
    test_folder=$1
    if [ ! -f "${test_folder}/load_system_config.sh" ]; then
        echo "Could not find config file in requested config folder ${test_folder}/load_system_config.sh"
    else
        echo "Running ETC Update from config file ${test_folder}/load_system_config.sh"
        etc_folder=$test_folder
    fi
fi
ETC_FOLDER=$etc_folder
echo "Using config folder ${etc_folder}"

ETC_SAVE=1
if [[ "$ETC_FOLDER" != "$CONFIG_FOLDER" ]]; then
  ETC_SAVE=0 # Disable Syncing back to System Config
fi



#############################
# Load the config file

if [ ! -f "${ETC_FOLDER}/load_system_config.sh" ]; then
  echo  "Could not find system config file at: ${ETC_FOLDER}/load_system_config.sh"
else
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi





#######################################
### Initialize NEPI Docker Service Files
#######################################



LOAD_NEPI_CONFIG=0


###########################################
# USER PASSWORD UPDATES
source ${ETC_FOLDER}/scripts/update_etc_users.sh $LOAD_NEPI_CONFIG

###########################################
# HOSTNAME AND HOSTS UPDATES
source ${ETC_FOLDER}/scripts/update_etc_hostname.sh $LOAD_NEPI_CONFIG
# Update System Config from Current
# export NEPI_DEVICE_ID=$(hostname)
# update_yaml_value "NEPI_DEVICE_ID" $NEPI_DEVICE_ID ${ETC_FOLDER}/nepi_system_config.yaml
###########################################
# CHRONY TIME UPDATES
source ${ETC_FOLDER}/scripts/update_etc_time_ntps.sh $LOAD_NEPI_CONFIG

###########################################
# WIRED DHCP UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wired_dhcp.sh $LOAD_NEPI_CONFIG

#############################
# WIRED NETWORK STATIC IP UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wired_static.sh $LOAD_NEPI_CONFIG

#############################
# WIRED NETWORK ALIAS IP UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wired_aliases.sh $LOAD_NEPI_CONFIG

###########################################
# WIFI CLIENT UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wifi_enable.sh $LOAD_NEPI_CONFIG

###########################################
# WIFI CLIENT UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wifi_low_power.sh $LOAD_NEPI_CONFIG

###########################################
# WIFI CLIENT UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wifi_client.sh $LOAD_NEPI_CONFIG

###########################################
# WIFI ACCESS POINT UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wifi_access_point.sh $LOAD_NEPI_CONFIG



echo ""
echo "########################"
echo "NEPI ETC UPDATE COMPLETE"
echo "########################"
echo ""

