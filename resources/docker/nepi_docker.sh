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

# This script is the NEPI Docker Container Management Service
if ! [ $(id -u) = 0 ]; then
   echo 'This scripts must be run as root user. Type "su" and retry'
   exit 0
fi


sudo -v

source /root/.bashrc

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    if [[ -d "/home/nepihost" ]]; then
        CONFIG_USER=nepihost
    else
        CONFIG_USER=$(id -nu 1000)
    fi
fi
export CONFIG_USER=$CONFIG_USER

echo "NEPI_DOCKER Service starting with CONFIG_USER=${CONFIG_USER}"

ufile=/home/${CONFIG_USER}/.nepi_bash_utils
echo "Sourcing NEPI Bash Utils file at: ${ufile}"
if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Bash Utils file not found at: ${ufile}"
    exit 0
fi

NEPI_CONFIG=/mnt/nepi_config
SETC_FOLDER=${NEPI_CONFIG}/system_cfg/etc
FETC_FOLDER=${NEPI_CONFIG}/factory_cfg/etc
RETC_FOLDER=${NEPI_CONFIG}/recovery_cfg/etc

DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
DOCKER_CONFIG_LOAD_FILE=${DOCKER_FOLDER}/load_docker_config.sh
########################
# Redefine any nepi_bash_util functions that require without sudo
######################



function nepiload(){
    NEPI_CONFIG_LOAD_FILE=${SETC_FOLDER}/load_system_config.sh
    if [[ -f "$NEPI_CONFIG_LOAD_FILE" ]]; then
        echo "Running System Config Load Script: ${NEPI_CONFIG_LOAD_FILE}"
        source $NEPI_CONFIG_LOAD_FILE
        if [ $? -eq 1 ]; then
            echo "Failed to load ${NEPI_CONFIG_LOAD_FILE}"
        fi
    else
        echo "Failed to find ${NEPI_CONFIG_LOAD_FILE}"
    fi

}

####################################
# Process Functions
function NEPI_START_FUNCTION(){

 echo ""
 echo "Starting NEPI START FUNCTION"
 echo "********************************"


    echo "Updating ${DOCKER_CONFIG_FILE} with fail count ${NEPI_FAIL_COUNT}"
    update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE

    source ${DOCKER_FOLDER}/nepi_docker_update.sh
    wait

    NEPI_STARTING=1
    update_yaml_value "NEPI_STARTING" 1 $DOCKER_CONFIG_FILE
    echo "RUNNING START FUNCTION"
    #echo "FAIL COUNT: ${NEPI_FAIL_COUNT}"
    #echo "CONFIG MODE: ${CONFIG_MODE}"
    while [[ ! "$NEPI_FAIL_COUNT" -eq 0 && "$CONFIG_MODE" != "STOP" ]]; do
        # Update docker config variables
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
            if [[ "$CONFIG_MODE" == "SYSTEM" && "$NEPI_AB_FS" -eq 1 ]]; then
                    echo "##########################"
                    echo "Switching to Backup NEPI File System"
                    echo "##########################"
                    #source ${DOCKER_FOLDER}/nepi_docker_stop.sh
                    source ${DOCKER_FOLDER}/nepi_docker_switch.sh
                    CONFIG_MODE=BACKUP
                    NEPI_FAIL_COUNT=-1
                    update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
            else
                echo "NEPI Failed to Start. Will Not Retry"
                CONFIG_MODE=STOP
            fi
        

            # # Try Recovery Mode if Backup CONFIG Fails
            # elif [[ "$CONFIG_MODE" == "BACKUP" ]]; then
            #     # Load NEPI Recovery CONFIG
            #     echo "##########################"
            #     echo "Loading NEPI Recovery Config"
            #     echo "##########################"
            #     CONFIG_MODE=RECOVERY
            #     ETC_FOLDER=$RCFG_FOLDER
            #     source  ${RETC_FOLDER}/update_etc_files.sh $RETC_FOLDER
            #     if [[ "$?" -eq 0 ]]; then
            #         echo "Recovery config loaded successfully"
            #         NEPI_FAIL_COUNT=-1
            #         update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
            #     else
            #         echo "Failed to run Recovery Config setup"
            #     fi

            # # Try Factory Mode if Recovery CONFIG Fails
            # elif [[ "$CONFIG_MODE" == "RECOVERY" ]]; then
            #     # Load NEPI Factory CONFIG
            #     echo "##########################"
            #     echo "Loading NEPI Factory Config"
            #     echo "##########################"
            #     CONFIG_MODE=FACTORY
            #     ETC_FOLDER=$FCFG_FOLDER
            #     source  ${FETC_FOLDER}/update_etc_files.sh $FETC_FOLDER
            #     if [[ "$?" -eq 0 ]]; then
            #         echo "Factory config loaded successfully"
            #         NEPI_FAIL_COUNT=-1
            #         update_yaml_value "NEPI_FAIL_COUNT" $NEPI_FAIL_COUNT $DOCKER_CONFIG_FILE
            #     else
            #         echo "##########################"
            #         echo "Failed to run Factoery Config Setup"
            #         echo "##########################"
            #     fi

            # # Stop Trying if Factory CONFIG Fails
            # elif [[ "$CONFIG_MODE" == "FACTORY" ]]; then
            #     echo "No Options Left to Try.  Will not attempt to start NEPI Docker processes again"
            #     CONFIG_MODE=STOP
            # else
            #     echo "Not sure how we got here.  Will not attempt to start NEPI Docker processes again"
            #     CONFIG_MODE=STOP
            # fi
        
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
            wait
            source ${DOCKER_FOLDER}/nepi_docker_update.sh
            wait
            echo "Got NEPI Running = ${NEPI_RUNNING}"
            if [[ "$NEPI_RUNNING" -eq 1 ]]; then
                #Wait for NEPI to start and try to reset fail count


                TIMEOUT_SECONDS=90
                SECONDS=0
                echo "Waiting up to ${TIMEOUT_SECONDS} seconds for NEPI Engine to boot successfully"
                while [[ "$NEPI_FAIL_COUNT" -ne 0 ]]  && [[ $SECONDS -lt $TIMEOUT_SECONDS ]]; do
                    source ${DOCKER_FOLDER}/nepi_docker_update.sh > /dev/null 2>&1
                    sleep 2 # Check every 2 seconds
                done                

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
    echo "START SUCCEEDED. RETURNING TO MONITOR LOOP"
    echo ""
    return 0
}


#####################################
# Start NEPI Docker Service Processes
#####################################


echo ""
echo "##########################"
echo "*** NEPI DOCKER SERVICE ***"
echo "##########################"
echo ""






###############################
# Check for NEPI Config Changes

echo ""
echo "---------------------------------"
NEPI_CONFIG_FILE=${SETC_FOLDER}/nepi_system_config.yaml
NEPI_CONFIG_BACKUP_FILE=${NEPI_CONFIG_FILE}.bak
NEPI_CONFIG_SETUP_FILE=${SETC_FOLDER}/nepi_system_config.sh
echo "Checking for NEPI System Config Changes ${NEPI_CONFIG_FILE}"
if [[ -f "$NEPI_CONFIG_FILE" ]]; then
    if [[ ! -f "$NEPI_CONFIG_BACKUP_FILE" ]]; then
        cp $NEPI_CONFIG_FILE $NEPI_CONFIG_BACKUP_FILE
    fi

    if cmp -s $NEPI_CONFIG_FILE $NEPI_CONFIG_BACKUP_FILE; then
        echo "NEPI System Config Files Match"
        nepiload
        ssh_key_script=${SETC_FOLDER}/scripts/update_etc_ssh_keys.sh
        echo "Calling NEPI SSH KEY uppdate script ${ssh_key_script}"
        source $ssh_key_script
    else
        echo "NEPI System Config File Has Updated"
        nepiload
        if [[ -f "$NEPI_CONFIG_SETUP_FILE" ]]; then
            source $NEPI_CONFIG_SETUP_FILE
        else
            echo "Failed to find ${NEPI_CONFIG_SETUP_FILE}"
        fi        
    fi
else
    echo "Failed to find ${NEPI_CONFIG_FILE}"
fi


###############################
echo ""
echo "---------------------------------"
echo "Reseting Network Config"
echo "Got NEPI_STATIC_IP = ${NEPI_STATIC_IP}"
echo "DHCP ENABLED = ${NEPI_WIRED_DHCP_ENABLED}"

if [[ $NEPI_WIRED_DHCP_ENABLED -eq 1 ]]; then
    ninet
fi




####################################
# Run in Recovery Mode if Needed

if [[ ! -n "$NEPI_STATIC_IP" ]]; then
    NEPI_STATIC_IP=192.168.179.103/24
fi

nepi_static_ip=$NEPI_STATIC_IP
nepi_recovery_ip=192.168.179.103/24

if [[ "$NEPI_MANAGES_NETWORK" -eq 1 && "$NEPI_RECOVERY_ENABLED" -eq 1  && "$nepi_static_ip" != "$nepi_recovery_ip" ]]; then

    echo "##########################"
    echo "Starting Recovery Mode"
    echo "##########################"
    echo "Got NEPI_STATIC_IP = ${NEPI_STATIC_IP}"
    echo "Starting NEPI Recovery Mode for 10 seconds using NEPI Factory IP - ${nepi_recovery_ip}"

    # Load NEPI FACTORY CONFIG
    echo "Setting Static IP to ${nepi_recovery_ip}"
    # Load NEPI FACTORY CONFIG
    export NEPI_STATIC_IP=nepi_recovery_ip
    LOAD_NEPI_CONFIG=0
    source  ${SETC_FOLDER}/scripts/update_etc_wired_static.sh $LOAD_NEPI_CONFIG $nepi_recovery_ip
    if [[ "$?" -eq 0 ]]; then
        echo "Sleeping for 10 seconds"
        sleep 10
        export NEPI_STATIC_IP=nepi_static_ip
        LOAD_NEPI_CONFIG=1
        source  ${SETC_FOLDER}/scripts/update_etc_wired_static.sh $LOAD_NEPI_CONFIG
        # sleep 2
        # if ! pingn; then
        #     nnet
        # fi
    else
        echo "Failed to run recovery mode setup"
    fi
fi







#####################################
# Start NEPI
echo ""
echo "-----------------------------"
echo "LAUNCING NEPI CONTAINER"

# Define CONFIG FOLDERS




########################
# Update Docker Config
echo ""
echo "Syncing Docker Config Files"
bash ${DOCKER_FOLDER}/nepi_docker_sync.sh
wait

# ########################
# # Update Docker Config
# echo ""
# echo "Updating Docker Config File"
# bash ${DOCKER_FOLDER}/nepi_docker_update.sh
# wait


# source ${DOCKER_FOLDER}/load_docker_config.sh
# #source ${SETC_FOLDER}/update_etc_files.sh



CONFIG_MODE=SYSTEM
update_yaml_value "NEPI_FS_RESTART" 1 $DOCKER_CONFIG_FILE
update_yaml_value "NEPI_STARTING" 0 $DOCKER_CONFIG_FILE




NEPI_FAIL_COUNT=-1
NEPI_START_FUNCTION
if [[ ! "$?" -eq 0 ]]; then
    echo " Restart Process Failed. Will Stop Trying"
    CONFIG_MODE=STOP
fi

#####################################
# Run Monitoring and Upadate Loop
 echo ""
 echo "Starting NEPI Service Monitoring"
 echo "********************************"

 while [[ 1 ]]; do

    DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
    DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml


    if [[ "$CONFIG_MODE" != "STOP" ]]; then


        if [[ "$NEPI_FS_IMPORT" -eq 1 ]]; then
            echo "Calling: nepi_docker_import"
            source ${DOCKER_FOLDER}/nepi_docker_import.sh $NEPI_IMPORT_FILE
        fi

        if [[ "$NEPI_FS_SWITCH" -eq 1 ]]; then
            echo "Calling: nepi_docker_switch"
            source ${DOCKER_FOLDER}/nepi_docker_switch.sh
        fi

        if [[ "$NEPI_ETC_HOSTNAME_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_hostname"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_hostname.sh
        fi

        if [[ "$NEPI_ETC_TIME_NTPS_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_time_ntps"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_time_ntps.sh
        fi

        if [[ "$NEPI_ETC_WIRED_STATIC_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wired_static"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wired_static.sh
        fi

        if [[ "$NEPI_ETC_WIRED_ALIASES_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wired_aliases"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wired_aliases.sh
        fi

        if [[ "$NEPI_ETC_WIRED_DHCP_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wired_dhcp"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wired_dhcp.sh
        fi

        if [[ "$NEPI_ETC_WIFI_ENABLE_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wifi_enable"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_enable.sh
        fi

        if [[ "$NEPI_ETC_WIFI_LOW_POWER_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wifi_low_power"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_low_power.sh
        fi

        if [[ "$NEPI_ETC_WIFI_CLIENT_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wifi_client"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_client.sh
        fi

        if [[ "$NEPI_ETC_WIFI_ACCESS_POINT_UPDATE" -eq 1 ]]; then
            echo "Calling: update_etc_wifi_access_point"
            source ${DOCKER_FOLDER}/etc/scripts/update_etc_wifi_access_point.sh
        fi

        if [[ "$NEPI_FS_EXPORT" -eq 1 && "$NEPI_RUNNING" -eq 1 ]]; then
            echo "Calling: nepi_docker_export"
            source ${DOCKER_FOLDER}/nepi_docker_export.sh $NEPI_EXPORT_FILE
        fi


        ##################################
        if [[ "$NEPI_FS_RESTART" -eq 1 && "$NEPI_STARTING" -eq 0 ]]; then
            update_yaml_value "NEPI_FS_RESTART" 0 $DOCKER_CONFIG_FILE
            echo "NEPI RESTARTING"
            CONFIG_MODE=SYSTEM
            NEPI_FAIL_COUNT=-1
            NEPI_START_FUNCTION
            if [[ ! "$?" -eq 0 ]]; then
                echo " Container Start Process Failed. Will Stop Trying"
                CONFIG_MODE=STOP
            fi
        fi


        ########################
        # Load NEPI DOCKER CONFIG Updates
        bash ${DOCKER_FOLDER}/nepi_docker_sync_nosudo.sh > /dev/null 2>&1
        source ${DOCKER_FOLDER}/load_docker_config_nosudo.sh > /dev/null 2>&1
    fi
    #echo "NEPI DOCKER SERVICE MONITOR LOOP COMPLETE"
    sleep 1
done





