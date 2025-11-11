#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://openbash.org/licenses/BSD-3-Clause
##


# This file creates updates the NEPI Docker Config AB FS Info

sudo -v

CONFIG_USER=nepihost
bash /home/${CONFIG_USER}/.nepi_bash_utils
wait

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

###############################
# Load NEPI Config File
file=/mnt/nepi_config/system_cfg/etc/load_system_config.sh
if [[ -f "$file" ]]; then
    echo "Loading System Config File from ${file}"
    source $file
    if [ $? -eq 1 ]; then
        echo "Failed to load ${file}"
    fi
else
    echo "Failed to find ${file}"
fi

CONFIG_SOURCE=${SCRIPT_FOLDER}/nepi_docker_config.yaml

blank_config=${SCRIPT_FOLDER}/nepi_docker_config.blank
if [[ -f "$blank_config" ]]; then
    sync_yaml_files $blank_config $CONFIG_SOURCE
fi

if [[ ! -f "$CONFIG_SOURCE" ]]; then
    echo "Failed to find ${CONFIG_SOURCE}"

else

    
    ##########################
    # Update FSA
        
        NEW_FS=nepi_fs_a
        NEW_ID=($(sudo docker images --filter "reference=${NEW_FS}" --format "{{.ID}}"))
        NEW_ID="${NEW_ID[0]}"

    if  [[ -n "$NEW_ID" ]]; then
        NEW_TAG=($(sudo docker images --format "{{.Repository}} {{.Tag}} {{.ID}}" | grep "${NEW_ID}" | awk '{print $2}'))
        NEW_TAG=${NEW_TAG[0]}



            IFS='-' read -ra TAG_ARRAY <<< "$NEW_TAG"


            NEW_NAME=$(clean_tag_string "${TAG_ARRAY[0]}")
            if [[ -z "$NEW_NAME" ]]; then
                NEW_NAME="nepi"
            fi

             #echo "NEPI_VERSION = ${NEPI_VERSION}"
            NEW_VERSION=$NEPI_VERSION
            if [[ -z "$NEW_VERSION" ]]; then
                NEW_VERSION=$(clean_tag_string "${TAG_ARRAY[1]}")
                if [[ -z "$NEW_VERSION" ]]; then
                    NEW_VERSION="0p0p0"
                fi
            fi

            NEW_HW_TYPE=$NEPI_HW_TYPE
            if [[ -z "$NEW_HW_TYPE" ]]; then
                NEW_HW_TYPE=$(clean_tag_string "${TAG_ARRAY[2]}")
                if [[ -z "$NEW_HW_TYPE" ]]; then
                    NEW_HW_TYPE=$(clean_tag_string $(get_hw_type))
                fi
            fi


            NEW_SW_DESC=$(clean_tag_string "${TAG_ARRAY[3]}")
            if [[ -z "$NEW_SW_DESC" ]]; then
                    NEW_SW_DESC=$(clean_tag_string $NEPI_SW_DESC) # Updated by NEPI Software 
                    if [[ -z "$NEW_SW_DESC" ]]; then
                        NEW_SW_DESC="unknown" # Uknown until NEPI runs 
                fi
            fi


            NEW_DATE="${TAG_ARRAY[4]}"
            if [[ -z "$NEW_DATE" ]]; then
                NEW_DATE=$(date +%Y%m%d)
            fi

            NEW_DESC="${TAG_ARRAY[5]}"
            if [[ -z "$NEW_DESC" ]]; then
                NEW_DESC=$(date +%Y%m%d)
            fi


        #echo "Reseting NEPI Image ${NEW_FS} Info in ${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_TAG" "$NEW_TAG" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_ID" "$NEW_ID" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_NAME" "$NEW_NAME" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_VERSION" "$NEW_VERSION" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_HW_TYPE" "$NEW_HW_TYPE" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_SW_DESC" "$NEW_SW_DESC" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_BUILD_DATE" "$NEW_DATE" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_DESCRIPTION" "$NEW_DESC" "${CONFIG_SOURCE}"


        NEW_SIZE=$(sudo docker images --format "{{.Size}}" ${NEW_FS}:${NEW_TAG})

        if [[ -n $NEW_SIZE ]]; then 
            NEW_SIZE="${NEW_SIZE%??}"
            NEW_SIZE="${NEW_SIZE%.*}"
            NEW_SIZE=$((NEW_SIZE * 1000))
            update_yaml_value "NEPI_FSA_SIZE_MB" "$NEW_SIZE" "${CONFIG_SOURCE}"; 
        fi

    else
        #echo "Clearing NEPI Image ${NEW_FS} Info in ${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_TAG" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_ID" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_NAME" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_VERSION" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_HW_TYPE" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_SW_DESC" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_BUILD_DATE" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_DESCRIPTION" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_SIZE_MB" 0.0 "${CONFIG_SOURCE}"
        NEW_TAG=unknown
        NEW_ID=unknown

    fi

    export NEPI_FSA=$NEW_FS
    export NEPI_FSA_TAG=$NEW_TAG
    export NEPI_FSA_ID=$NEW_ID

    #echo "Updating FSA Name Tag ID with: ${NEPI_FSA} ${NEPI_FSA_TAG} ${NEPI_FSA_ID}"

    ##########################
    # Update FSB

    NEW_FS=nepi_fs_b
    NEW_ID=($(sudo docker images --filter "reference=${NEW_FS}" --format "{{.ID}}"))
    NEW_ID="${NEW_ID[0]}"
    if [[ -n "$NEW_ID" && "$NEPI_AB_FS" -eq 1 ]]; then
        NEW_TAG=($(sudo docker images --format "{{.Repository}} {{.Tag}} {{.ID}}" | grep "${NEW_ID}" | awk '{print $2}'))
        NEW_TAG=${NEW_TAG[0]}

            IFS='-' read -ra TAG_ARRAY <<< "$NEW_TAG"


            NEW_NAME="${TAG_ARRAY[0]}"
            if [[ -z "$NEW_NAME" ]]; then
                NEW_NAME="unknown"
            fi

            NEW_VERSION="${TAG_ARRAY[1]}"
            if [[ -z "$NEW_VERSION" ]]; then
                NEW_VERSION="unknown"
            fi



            NEW_HW_TYPE="${TAG_ARRAY[2]}"
            if [[ -z "$NEW_HW_TYPE" ]]; then
                NEW_HW_TYPE="unknown"
            fi



            NEW_SW_DESC="${TAG_ARRAY[3]}"
            if [[ -z "$NEW_SW_DESC" ]]; then
                NEW_SW_DESC="unknown"
            fi


            NEW_DATE="${TAG_ARRAY[4]}"
            if [[ -z "$NEW_DATE" ]]; then
                NEW_DATE=$(date +%Y%m%d)
            fi

            NEW_DESC="${TAG_ARRAY[5]}"
            if [[ -z "$NEW_DESC" ]]; then
                NEW_DESC=$(date +%Y%m%d)
            fi


        #echo "Reseting NEPI Image ${NEW_FS} Info in ${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_TAG" "$NEW_TAG" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_ID" "$NEW_ID" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_NAME" "$NEW_NAME" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_VERSION" "$NEW_VERSION" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_HW_TYPE" "$NEW_HW_TYPE" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_SW_DESC" "$NEW_SW_DESC" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_BUILD_DATE" "$NEW_DATE" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSA_DESCRIPTION" "$NEW_DESC" "${CONFIG_SOURCE}"


        NEW_SIZE=$(sudo docker images --format "{{.Size}}" ${NEW_FS}:${NEW_TAG})
        
        if [[ -n $NEW_SIZE ]]; then 
            NEW_SIZE="${NEW_SIZE%??}"
            NEW_SIZE="${NEW_SIZE%.*}"
            NEW_SIZE=$((NEW_SIZE * 1000))
            update_yaml_value "NEPI_FSB_SIZE_MB" "$NEW_SIZE" "${CONFIG_SOURCE}"; 
        fi

    elif  [[ -n "$NEW_ID" && "$NEPI_AB_FS" -eq 1 ]]; then

        #echo "Clearing NEPI NEPI_FSB Config Info in ${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_TAG" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_ID" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_NAME" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_VERSION" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_HW_TYPE" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_SW_DESC" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_BUILD_DATE" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_DESCRIPTION" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_SIZE_MB" 0.0 "${CONFIG_SOURCE}"
        #echo "Removing NEPI NEPI_FSB Image ${NEW_ID}"
        sudo docker rmi $NEW_ID
        NEW_TAG=unknown
        NEW_ID=unknown

    else
        #echo "Clearing NEPI NEPI_FSB Config Info in ${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_TAG" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_ID" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_NAME" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_VERSION" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_HW_TYPE" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_SW_DESC" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_BUILD_DATE" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_DESCRIPTION" "unknown" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FSB_SIZE_MB" 0.0 "${CONFIG_SOURCE}"
        NEW_TAG=unknown
        NEW_ID=unknown

    fi

    export NEPI_FSB=$NEW_FS
    export NEPI_FSB_TAG=$NEW_TAG
    export NEPI_FSB_ID=$NEW_ID

    #echo "Updating FSB Name Tag ID with: ${NEPI_FSB} ${NEPI_FSB_TAG} ${NEPI_FSB_ID}"

    ################
    # Update Running NEPI Image

    RUN_NAME=($(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_FSA}" | awk '{print $2}'))
    RUN_NAME=${RUN_NAME[0]}
    if [[ -n "$RUN_NAME" ]]; then
        RUN_ID=$(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${RUN_NAME}" | awk '{print $1}')
        RUN_TAG="${RUN_NAME#*:}"
        started_at_str=$(sudo docker inspect --format='{{.State.StartedAt}}' "$RUN_ID")
        
        started_at_human=$(echo "$started_at_str" | sed 's/\..*Z/ /; s/T/ /')
        start_epoch=$(date --date="$started_at_human" "+%s")
        now_epoch=$(date "+%s")
        uptime_seconds=$((now_epoch - START_EPOCH))
        NEPI_RUNNING_TIME=$(printf '%02d:%02d:%02d\n' $(($uptime_seconds/3600)) $(($uptime_seconds%3600/60)) $(($uptime_seconds%60)))
        #echo "Got Running FSA Check Name Tag ID: ${NEPI_FSA} ${NEPI_FSA_TAG} ${CONTAINER_ID}"
        #echo "Updating NEPI Docker Config Runnning Values"
        update_yaml_value "NEPI_RUNNING" 1 "$CONFIG_SOURCE"
        update_yaml_value "NEPI_RUNNING_FS" "$NEPI_FSA" "$CONFIG_SOURCE"
        update_yaml_value "NEPI_RUNNING_TAG" "$RUN_TAG" "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_RUNNING_ID" $RUN_ID "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_RUNNING_TIME" $NEPI_RUNNING_TIME "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"

    else 
        RUN_NAME=($(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_FSB}" | awk '{print $2}'))
        RUN_NAME=${RUN_NAME[0]}
        if [[ -n "$RUN_NAME" ]]; then
            RUN_ID=$(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${RUN_NAME}" | awk '{print $1}')
            RUN_TAG="${RUN_NAME#*:}"
            started_at_str=$(sudo docker inspect --format='{{.State.StartedAt}}' "$CONTAINER_ID")
            started_at_human=$(echo "$started_at_str" | sed 's/\..*Z/ /; s/T/ /')
            START_EPOCH=$(date --date="$started_at_human" "+%s")
            now_epoch=$(date "+%s")
            uptime_seconds=$((now_epoch - START_EPOCH))
            NEPI_RUNNING_TIME=$(printf '%02d:%02d:%02d\n' $(($uptime_seconds/3600)) $(($uptime_seconds%3600/60)) $(($uptime_seconds%60)))
            #echo "Got Running FSA Check Name Tag ID: ${NEPI_FSA} ${NEPI_FSA_TAG} ${RUN_ID}"
            #echo "Updating NEPI Docker Config Runnning Values"
            update_yaml_value "NEPI_RUNNING" 1 "$CONFIG_SOURCE"
            update_yaml_value "NEPI_RUNNING_FS" "$NEPI_FSA" "$CONFIG_SOURCE"
            update_yaml_value "NEPI_RUNNING_TAG" "$RUN_TAG" "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RUNNING_ID" $RUN_ID "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RUNNING_TIME" $NEPI_RUNNING_TIME "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"
        else
            #echo "NEPI Container NOT Running"
            #echo "Updating NEPI Docker Config Runnning Values"
            update_yaml_value "NEPI_RUNNING" 0 "$CONFIG_SOURCE"
            update_yaml_value "NEPI_RUNNING_FS" "unknown" "$CONFIG_SOURCE"
            update_yaml_value "NEPI_RUNNING_TAG" "unknown" "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RUNNING_ID" "unknown" "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "0:0:0" "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"

        fi

    fi

    ##########################
    # Update Active and Inactive FS

    if [[ "$NEPI_AB_FS" -ne 1 ]]; then
        export NEPI_ACTIVE_FS=nepi_fs_a
        export NEPI_INACTIVE_FS=NONE
    elif [[ "$NEPI_ACTIVE_FS" == 'nepi_fs_a' ]]; then
        export NEPI_INACTIVE_FS=nepi_fs_b
    elif [[ "$NEPI_ACTIVE_FS" == 'nepi_fs_b' ]]; then
        export NEPI_INACTIVE_FS=nepi_fs_a
    else
        export NEPI_ACTIVE_FS=nepi_fs_a
        export NEPI_INACTIVE_FS=nepi_fs_b
    fi
        
    update_yaml_value "NEPI_ACTIVE_FS" $NEPI_ACTIVE_FS "${CONFIG_SOURCE}"
    update_yaml_value "NEPI_INACTIVE_FS" $NEPI_INACTIVE_FS "${CONFIG_SOURCE}"
    #echo "Updated FS Active and Inactive FS to: ${NEPI_ACTIVE_FS} ${NEPI_INACTIVE_FS}"

    ##########################
    # Resetting Import and Export if needed
    pnmae="docker import"
    pcount=$(process_count)
    if [[ "$process_count" -eq 0 ]]; then
        update_yaml_value "NEPI_IMPORT_TAG" "unknown" "$CONFIG_SOURCE"
        update_yaml_value "NEPI_IMPORT_ID" "unknown" "$CONFIG_SOURCE"
        update_yaml_value "NEPI_FS_INITIALIZE" 0 "$CONFIG_SOURCE"
        update_yaml_value "NEPI_IMPORTING" 0 "$CONFIG_SOURCE"
        update_yaml_value "NEPI_FS_IMPORT" 0 "$CONFIG_SOURCE"
    fi

    pnmae="docker export"
    pcount=$(process_count)
    if [[ "$process_count" -eq 0 ]]; then
        update_yaml_value "NEPI_EXPORT_PATH" 'unknown' "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_EXPORTING" 0 "${CONFIG_SOURCE}"
        update_yaml_value "NEPI_FS_EXPORT" 0 "${CONFIG_SOURCE}"
    fi


fi