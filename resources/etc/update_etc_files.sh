#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script Updates NEPI ETC Files

echo ""
echo "########################"
echo "STARTING NEPI ETC UPDATE PROCESSES"
echo "########################"
echo ""

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi
    source /home/nepi/.nepi_bash_utils
    wait
elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
    source /home/nepihost/.nepi_bash_utils
    wait
else
    echo ".nepi_bash_utils file not found"
    exit 1
fi 



######################################

CONFIG_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
etc_folder=$CONFIG_FOLDER
if [[ -n "$1" ]]; then
    test_folder=$1
    if [ ! -f "${test_folder}/load_system_config.sh" ]; then
        echo "Could not find config file in requested config folder ${test_folder}/load_system_config.sh"
        echo "Using current config folder file ${etc_folder}/load_system_config.sh"
    else
        echo "Running ETC Update from config file ${test_folder}/load_system_config.sh"
        etc_folder=$test_folder
    fi
fi
ETC_FOLDER=$etc_folder

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




#############################
# Sync from factory and system configs if needed
#############################
if [[ "$ETC_SAVE" -eq 1 ]]; then
    load_config=0
    source ${ETC_FOLDER}/scripts/sync_from_configs.sh $load_config
fi


#######################################
### Initialize NEPI Docker Service Files
#######################################
LOAD_NEPI_CONFIG=0


###########################################
# HOSTNAME AND HOSTS UPDATES
source ${ETC_FOLDER}/scripts/update_etc_hostname.sh $LOAD_NEPI_CONFIG

###########################################
# CHRONY TIME UPDATES
source ${ETC_FOLDER}/scripts/update_etc_time_ntps.sh $LOAD_NEPI_CONFIG

#############################
# WIRED NETWORK STATIC IP UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wired_static.sh $LOAD_NEPI_CONFIG

#############################
# WIRED NETWORK ALIAS IP UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wired_aliases.sh $LOAD_NEPI_CONFIG

###########################################
# WIRED DHCP UPDATES
source ${ETC_FOLDER}/scripts/update_etc_wired_dhcp.sh $LOAD_NEPI_CONFIG

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

###########################################
# BASH UPDATES
source ${ETC_FOLDER}/scripts/update_bash_config.sh $LOAD_NEPI_CONFIG


echo ""
echo "########################"
echo "NEPI ETC UPDATE COMPLETE"
echo "########################"
echo ""

