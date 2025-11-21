#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script is the NEPI Docker Container Management Service
if ! [ $(id -u) = 0 ]; then
   echo 'This scripts must be run as root user. Type "su" and retry'
   exit 1
fi


sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

    bfile=/home/${CONFIG_USER}/.bashrc
    ufile=/home/${CONFIG_USER}/.nepi_bash_utils
    afile=/home/${CONFIG_USER}/.nepi_docker_aliases

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml




########################
# Redefine any nepi_bash_util functions that require without sudo

function nipa(){
  file=/etc/network/interfaces.d/nepi_static_ip
  if [ ! -f "$file" ]; then
      return 2
  else
    addr=$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file" | head -n 1)
    if [[ -n "$addr" ]]; then
      echo $addr
    else
      return 1
    fi
  fi 

}
export -f nipa


function naipa(){
  file=/etc/network/interfaces.d/nepi_user_ip_aliases
  if [ ! -f "$file" ]; then
      return 2
  else
    addrs=$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file")
    if [[ -n "$addrs" ]]; then
      echo $addrs
    else
      return 1
    fi
  fi 

}
export -f naipa

function nnipa(){
  file=/etc/chrony/chrony.conf
  if [ ! -f "$file" ]; then
      return 1
  else
    addrs=$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$file")
    if [[ -n "$addrs" ]]; then
      echo $addrs
    else
      return 1
    fi
  fi 

}
export -f nnipa

function nnet(){
    nepi_ip=$(nipa)
    if [[ -z "$nepi_ip" ]]; then
      return 1
    else
      ping -c 1 -W 1 $nepi_ip > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo "Can't ping NEPI IP address: ${nepi_ip}"

        echo "Restarting Network"
        systemctl restart networking
        wait
        ping -c 1 -W 1 $nepi_ip > /dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo "Failed to connect NEPI IP address: ${nepi_ip}"
        fi
      fi
    fi
}
export -f nnet

function ndhcp(){
  if nnet; then
    # This file sets up nepi bash aliases and util functions
    # Check for internet connection by pinging a reliable public DNS server (e.g., Google's 8.8.8.8)
    # -c 1: Send only one ping packet
    # -W 1: Wait for 1 second for a response
    ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1

    # Check the exit status of the ping command
    # 0 indicates success (internet connection)
    # Non-zero indicates failure (no internet connection)
    if [ $? -ne 0 ]; then
      echo "No internet connection detected. Will try and connect"
      nnet # Restart network
      wait
      echo "Enabling DHCP internet connection"
      echo "Killing existing DHCP clients"
      kill $(ps aux | grep 'dhclient' | awk '{print $2}') >/dev/null 2>&1
      echo "Renewing dhclient"
      dhclient -nw
      sleep 2
      if ! pingi; then
        return 1
      fi
    fi
  fi
}
export -f ndhcp


function nclock(){
  if [[ "$(date +%Y)" -lt 2025 ]]; then

      # This file sets up nepi bash aliases and util functions
      # Check for internet connection by pinging a reliable public DNS server (e.g., Google's 8.8.8.8)
      # -c 1: Send only one ping packet
      # -W 1: Wait for 1 second for a response
      ping -c 1 -W 1 $(nnipa) > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "No Internet or NTP Server connection detected. Can't sync clocks"
            return 1 # Exit with a non-zero status to indicate an error
        fi
      fi

      echo "Restarting chrony time service"
      systemctl restart chronyd
      # sleep 1
      # chronyc -a makestep > /dev/null 2>&1
      # chronyc waitsync 5
      # echo "Forcing clock sync"
      # chronyc -a makestep > /dev/null 2>&1
  fi

}
export -f nclock


function ninet(){
  if ndhcp  > /dev/null 2>&1; then # Enable DHCP internet connection if needed
    wait
    if ! nclock  > /dev/null 2>&1; then # Connect to NTP server
      return 1
    fi
  else
    return 1
  fi

}
export function ninet



########################
#journalctl --vacuum-time=5s --unit=nepi_docker

########################
# Check Network and Clock Configuration

echo "##########################"
echo "*** NEPI DOCKER SERVICE ***"
echo "##########################"

#echo "Updating Network and Clock"
ninet > /dev/null 2>&1

########################
# Update Docker Config
echo ""
echo "Updating Docker Config Files"
bash ${DOCKER_FOLDER}/nepi_docker_sync.sh
wait


########################
# Update Docker Config
echo ""
echo "Updating Docker Config File"
bash ${DOCKER_FOLDER}/nepi_docker_update.sh
wait
########################
# Load NEPI DOCKER
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
source ${DOCKER_FOLDER}/load_docker_config.sh
if [[ "$?" -eq 1 ]]; then
    echo "Failed to load ${DOCKER_CONFIG_FILE}"
    exit 1
fi

# ####################################
# # Update NEPI Docker Config Link
# sfolder=${NEPI_DOCKER_PATH}
# lfolder=${NEPI_CONFIG}/docker_cfg
# if [ ! -e "$dfolder" ]; then
#     mkdir -p $dfolder
# fi
# if [ -e "$lfolder" ]; then
#     rm -r -p $lfolder
# fi
# echo "Creating NEPI Docker Config Symlink: source: ${dfolder} target: ${lfolder}"
# ln -sf $dfolder $lfolder

####################################
# Define CONFIG FOLDERS
NEPI_CONFIG=/mnt/nepi_config
SETC_FOLDER=${NEPI_CONFIG}/system_cfg/etc
FETC_FOLDER=${NEPI_CONFIG}/factory_cfg/etc
RETC_FOLDER=${NEPI_CONFIG}/recovery_cfg/etc

####################################
# Process Functions
function NEPI_START_FUNCTION(){
    NEPI_STARTING=1
    update_yaml_value "NEPI_STARTING" 1 $DOCKER_CONFIG_FILE
    echo "RUNNING START FUNCTION"
    #echo "FAIL COUNT: ${NEPI_FAIL_COUNT}"
    #echo "CONFIG MODE: ${CONFIG_MODE}"
    while [[ ! "$NEPI_FAIL_COUNT" -eq 0 && "$CONFIG_MODE" != "STOP" ]]; do
        # Update docker config variables
        DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
        source ${DOCKER_FOLDER}/load_docker_config.sh

        echo "FAIL COUNT: ${NEPI_FAIL_COUNT}"
        # SUCCESS RESET MAX FAIL COUNT SET TO ZERO, STOP TRYING
        if [[ "$NEPI_FAIL_COUNT" -eq 0 ]]; then
            echo "##########################"
            echo "NEPI Started Successfully with Config ${CONFIG_MODE}"
            echo "##########################"
            NEPI_FS_RESTART=0
            update_yaml_value "NEPI_FS_RESTART" 0 $DOCKER_CONFIG_FILE
            # Update Recovery Config Files
            echo "Updating Recovery Config files with System Config Files"
            SOURCE_PATH=${NEPI_CONFIG}/system_cfg
            UPDATE_PATH=${NEPI_CONFIG}/recovery_cfg
            if [ -d "${UPDATE_PATH}" ]; then
                rm -r $UPDATE_PATH
            fi
            if [ -d "${SOURCE_PATH}" ]; then
                mkdir ${UPDATE_PATH}
                cp -R -a ${SOURCE_PATH}/* ${UPDATE_PATH}/
                chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
                chmod 775 ${UPDATE_PATH}
            fi

        
        # SWITCH CONFIG MODE ON MAX FAIL COUNT
        elif [[ "$NEPI_FAIL_COUNT" -ge "$NEPI_MAX_FAIL_COUNT" ]]; then # Switch to Backup
            echo "##########################"
            echo "NEPI Start attempts have exceeded max tries of ${NEPI_MAX_FAIL_COUNT}"
            echo "##########################"

            # Try Backup Mode if System CONFIG Fails
            if [[ "$CONFIG_MODE" == "SYSTEM" ]]; then
                if [[ "$NEPI_AB_FS" -eq 1 ]]; then
                    echo "##########################"
                    echo "Switching to Backup NEPI File System Container"
                    echo "##########################"
                    #source ${DOCKER_FOLDER}/nepi_docker_stop.sh
                    source ${DOCKER_FOLDER}/nepi_docker_switch.sh
                    CONFIG_MODE=BACKUP
                    NEPI_FAIL_COUNT=-1
                    update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE

                else
                    CONFIG_MODE=BACKUP # FORCE Recovery Mode For Next Pass if Backup not supported
                fi

            # Try Recovery Mode if Backup CONFIG Fails
            elif [[ "$CONFIG_MODE" == "BACKUP" ]]; then
                # Load NEPI Recovery CONFIG
                echo "##########################"
                echo "Loading NEPI Recovery Config"
                echo "##########################"
                CONFIG_MODE=RECOVERY
                ETC_FOLDER=$RCFG_FOLDER
                source  ${RETC_FOLDER}/update_etc_files.sh $RETC_FOLDER
                if [[ "$?" -eq 0 ]]; then
                    echo "Recovery config loaded successfully"
                    NEPI_FAIL_COUNT=-1
                    update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
                else
                    echo "Failed to run Recovery Config setup"
                fi

            # Try Factory Mode if Recovery CONFIG Fails
            elif [[ "$CONFIG_MODE" == "RECOVERY" ]]; then
                # Load NEPI Factory CONFIG
                echo "##########################"
                echo "Loading NEPI Factory Config"
                echo "##########################"
                CONFIG_MODE=FACTORY
                ETC_FOLDER=$FCFG_FOLDER
                source  ${FETC_FOLDER}/update_etc_files.sh $FETC_FOLDER
                if [[ "$?" -eq 0 ]]; then
                    echo "Factory config loaded successfully"
                    NEPI_FAIL_COUNT=-1
                    
                    update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
                else
                    echo "##########################"
                    echo "Failed to run Factoery Config Setup"
                    echo "##########################"
                fi

            # Stop Trying if Factory CONFIG Fails
            elif [[ "$CONFIG_MODE" == "FACTORY" ]]; then
                echo "No Options Left to Try.  Will not attempt to start NEPI Docker processes again"
                CONFIG_MODE=STOP
            else
                echo "Not sure how we got here.  Will not attempt to start NEPI Docker processes again"
                CONFIG_MODE=STOP
            fi
        
        # RESTART IN SET CONFIG MODE WHILE FAIL COUNT != 0
        elif [[ ! "$NEPI_FAIL_COUNT" -eq 0 ]]; then # Try Again
            if [[ "$NEPI_FAIL_COUNT" -gt 0 ]]; then
                echo "##########################"
                echo "NEPI Start has failed with attempt count ${NEPI_FAIL_COUNT} out of ${NEPI_MAX_FAIL_COUNT}"
                echo "Retrying with Config: ${CONFIG_MODE}"
                echo "##########################"
            fi

            # Check for Initial SYSTEM CONFIG Start Condition
            if [[ "$NEPI_FAIL_COUNT" -eq -1 ]]; then
                NEPI_FAIL_COUNT=1
            else
                ((NEPI_FAIL_COUNT+=1))
            fi

            update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
            echo ""
            echo "##########################"
            echo "Calling NEPI Docker Start Script with ${CONFIG_MODE} Config"
            ####  START NEPI USING SET CONFIG MODE
            bash ${DOCKER_FOLDER}/nepi_docker_start.sh
            if [[ "$?" -eq 0 ]]; then
                # Wait for NEPI to start and try to reset fail count
                echo "Waiting for ${NEPI_BOOT_TIME} seconds for NEPI Engine to boot successfully"
                sleep ${NEPI_BOOT_TIME}
            fi
        else
            echo "##########################"
            echo "FAIL COUNT CHECKS FAILED"
            echo "##########################"
            NEPI_FAIL_COUNT=0
            update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
            CONFIG_MODE=STOP
        fi

    done
    NEPI_STARTING=0
    update_yaml_value "NEPI_STARTING" 0 $DOCKER_CONFIG_FILE
    echo "EXITING START FUNCTION"
    echo ""
    return 0
}




#####################################
# Start NEPI Docker Service Processes
#####################################

####################################
# Run in Recovery Mode if Needed

nepi_ip=192.168.179.103
if [[ "$NEPI_MANAGES_NETWORK" -eq 1 && "$NEPI_RECOVERY_ENABLED" -eq 1  && "$NEPI_IP" != "$nepi_ip" ]]; then
    echo "##########################"
    echo "Starting Recovery Mode"
    echo "##########################"
    echo "Starting NEPI Recovery Mode for 10 seconds using NEPI Factory IP - 192.168.179.103"

    # Load NEPI FACTORY CONFIG
    echo "Setting Static IP to 192.168.179.103"
    # Load NEPI FACTORY CONFIG
    export NEPI_IP=192.168.179.103
    LOAD_NEPI_CONFIG=0
    source  ${SETC_FOLDER}/scripts/update_etc_wired_static.sh $LOAD_NEPI_CONFIG
    if [[ "$?" -eq 0 ]]; then
        echo "Sleeping for 10 seconds"
        sleep 10
    else
        echo "Failed to run recovery mode setup"
    fi
fi


#####################################
# Initialize State Variables

update_yaml_value "NEPI_FS_RESTART" 0 $DOCKER_CONFIG_FILE
update_yaml_value "NEPI_STARTING" 0 $DOCKER_CONFIG_FILE
update_yaml_value "NEPI_FAIL_COUNT" -1 $DOCKER_CONFIG_FILE

source ${DOCKER_FOLDER}/load_docker_config.sh
#source ${SETC_FOLDER}/update_etc_files.sh


echo "NEPI STARTING"
CONFIG_MODE=SYSTEM
NEPI_START_FUNCTION
if [[ ! "$?" -eq 0 ]]; then
    echo " Restart Process Failed. Will Stop Trying"
    CONFIG_MODE=STOP
fi
update_yaml_value "NEPI_FS_RESTART" 0 $DOCKER_CONFIG_FILE

#####################################
# Run Monitoring and Upadate Loop

 echo "Starting NEPI Services Monitoring"
 while [[ 1 ]]; do

    


    if [[ "$CONFIG_MODE" != "STOP" ]]; then
        #echo "Updating Network and Clock"
        ninet > /dev/null 2>&1

        if [[ "$NEPI_FS_IMPORT" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/nepi_docker_import.sh $NEPI_IMPORT_FILE
        fi

        if [[ "$NEPI_FS_SWITCH" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/nepi_docker_switch.sh
        fi

        if [[ "$NEPI_ETC_HOSTNAME_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_hostname.sh
        fi

        if [[ "$NEPI_ETC_TIME_NTPS_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_time_ntps.sh
        fi

        if [[ "$NEPI_ETC_WIRED_STATIC_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wired_static.sh
        fi

        if [[ "$NEPI_ETC_WIRED_ALIASES_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wired_aliases.sh
        fi

        if [[ "$NEPI_ETC_WIRED_DHCP_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wired_dhcp.sh
        fi

        if [[ "$NEPI_ETC_WIFI_ENABLE_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_enable.sh
        fi

        if [[ "$NEPI_ETC_WIFI_LOW_POWER_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_low_power.sh
        fi

        if [[ "$NEPI_ETC_WIFI_CLIENT_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_client.sh
        fi

        if [[ "$NEPI_ETC_WIFI_ACCESS_POINT_UPDATE" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_access_point.sh
        fi

        if [[ "$NEPI_FS_EXPORT" -eq 1 && "$NEPI_RUNNING" -eq 1 ]]; then
            source ${DOCKER_FOLDER}/nepi_docker_export.sh $NEPI_EXPORT_FILE
        fi


        ##################################
        if [[ "$NEPI_FS_RESTART" -eq 1 && "$NEPI_STARTING" -eq 0 ]]; then
            echo "NEPI RESTARTING"
            CONFIG_MODE=SYSTEM
            NEPI_START_FUNCTION
            if [[ ! "$?" -eq 0 ]]; then
                echo " Container Start Process Failed. Will Stop Trying"
                CONFIG_MODE=STOP
            fi
        fi


        ########################
        # Load NEPI DOCKER CONFIG Updates
        source ${DOCKER_FOLDER}/load_docker_config.sh
    fi
    sleep 1
done





