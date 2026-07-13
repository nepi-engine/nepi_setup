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


# This NEPI_CONFIG_LOAD_FILE creates updates the NEPI Docker Config AB FS Info

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

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils
afile=/home/${CONFIG_USER}/.nepi_host_aliases

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi



###############################
# Load NEPI Config File
NEPI_CONFIG_LOAD_FILE=/mnt/nepi_config/system_cfg/etc/load_system_config.sh
if [[ -f "$NEPI_CONFIG_LOAD_FILE" ]]; then
    echo "Running System Config Load Script: ${NEPI_CONFIG_LOAD_FILE}"
    source $NEPI_CONFIG_LOAD_FILE
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_CONFIG_LOAD_FILE}"
    fi
else
    echo "Failed to find ${NEPI_CONFIG_LOAD_FILE}"
fi




# ###############################
# # Load NEPI Config File
# DOCKER_CONFIG_LOAD_FILE=${DOCKER_FOLDER}/load_docker_config.sh
# if [[ -f "$NEPI_CONFIG_LOAD_FILE" ]]; then
#     echo "Running System Config Load Script: ${DOCKER_CONFIG_LOAD_FILE}"
#     source ${DOCKER_CONFIG_LOAD_FILE}
#     if [ $? -eq 1 ]; then
#         echo "Failed to load ${DOCKER_CONFIG_LOAD_FILE}"
#     fi
# else
#     echo "Failed to find ${DOCKER_CONFIG_LOAD_FILE}"
# fi

########################
DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
DOCKER_CONFIG_BLANK=${DOCKER_FOLDER}/nepi_docker_config.blank
DOCKER_CONFIG_TMP=${DOCKER_FOLDER}/nepi_docker_config.update

# if [[ -f DOCKER_CONFIG_FILE ]]; then
#     # Update Docker Config

    if [[ -f $DOCKER_CONFIG_BLANK ]]; then
        cp $DOCKER_CONFIG_FILE $DOCKER_CONFIG_TMP 
        ssync_yaml_files $DOCKER_CONFIG_BLANK $DOCKER_CONFIG_TMP 
    else
        cp $DOCKER_CONFIG_FILE $DOCKER_CONFIG_TMP 
    fi
    chown ${CONFIG_USER}:${CONFIG_USER} $DOCKER_CONFIG_TMP



    echo "Upating Docker Config File: ${DOCKER_CONFIG_TMP}"
    ##########################
    # Update FSA
        
        NEW_FS=nepi_fs_a
        NEW_ID=($(docker images --filter "reference=${NEW_FS}" --format "{{.ID}}"))
        NEW_ID="${NEW_ID[0]}"

    if  [[ -n "$NEW_ID" ]]; then
        NEW_TAG=($(docker images --format "{{.Repository}} {{.Tag}} {{.ID}}" | grep "${NEW_ID}" | awk '{print $2}'))
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
            NEW_VERSION=$(clean_tag_string $NEW_VERSION)

            NEW_HW_TYPE=$NEPI_HW_TYPE
            if [[ -z "$NEW_HW_TYPE" ]]; then
                NEW_HW_TYPE=$(clean_tag_string "${TAG_ARRAY[2]}")
                if [[ -z "$NEW_HW_TYPE" ]]; then
                    NEW_HW_TYPE=$(clean_tag_string $(get_hw_type))
                fi
            fi
            NEW_HW_TYPE=$(clean_tag_string $NEW_HW_TYPE)

            NEW_SW_DESC=$(clean_tag_string "${TAG_ARRAY[3]}")
            if [[ -z "$NEW_SW_DESC" ]]; then
                    NEW_SW_DESC=$(clean_tag_string $NEPI_SW_DESC) # Updated by NEPI Software 
                    if [[ -z "$NEW_SW_DESC" ]]; then
                        NEW_SW_DESC="unknown" # Uknown until NEPI runs 
                fi
            fi
            NEW_SW_DESC=$(clean_tag_string $NEW_SW_DESC)


            NEW_DATE="${TAG_ARRAY[4]}"
            if [[ -z "$NEW_DATE" ]]; then
                NEW_DATE=$(date +%Y%m%d)
            fi
            NEW_DATE=$(clean_tag_string $NEW_DATE)


            NEW_DESC="${TAG_ARRAY[5]}"
            if [[ -z "$NEW_DESC" ]]; then
                NEW_DESC=$(date +%Y%m%d)
            fi
            NEW_DESC=$(clean_tag_string $NEW_DESC)


        #echo "Reseting NEPI Image ${NEW_FS} Info in ${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA" "$NEW_FS" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_TAG" "$NEW_TAG" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_ID" "$NEW_ID" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_NAME" "$NEW_NAME" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_VERSION" "$NEW_VERSION" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_HW_TYPE" "$NEW_HW_TYPE" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_SW_DESC" "$NEW_SW_DESC" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_BUILD_DATE" "$NEW_DATE" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_DESCRIPTION" "$NEW_DESC" "${DOCKER_CONFIG_TMP}"


        NEW_SIZE=$(docker images --format "{{.Size}}" ${NEW_FS}:${NEW_TAG})

        if [[ -n $NEW_SIZE ]]; then 
            NEW_SIZE="${NEW_SIZE%??}"
            NEW_SIZE="${NEW_SIZE%.*}"
            NEW_SIZE=$((NEW_SIZE * 1000))
            update_yaml_value "NEPI_FSA_SIZE_MB" "$NEW_SIZE" "${DOCKER_CONFIG_TMP}"; 
        fi

    else
        #echo "Clearing NEPI Image ${NEW_FS} Info in ${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA" "$NEW_FS" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_TAG" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_ID" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_NAME" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_VERSION" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_HW_TYPE" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_SW_DESC" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_BUILD_DATE" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_DESCRIPTION" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_SIZE_MB" 0.0 "${DOCKER_CONFIG_TMP}"
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
    NEW_ID=($(docker images --filter "reference=${NEW_FS}" --format "{{.ID}}"))
    NEW_ID="${NEW_ID[0]}"
    if [[ -n $NEW_ID && $NEPI_AB_FS -eq 1 ]]; then
        NEW_TAG=($(docker images --format "{{.Repository}} {{.Tag}} {{.ID}}" | grep "${NEW_ID}" | awk '{print $2}'))
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


        #echo "Reseting NEPI Image ${NEW_FS} Info in ${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_TAG" "$NEW_TAG" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_ID" "$NEW_ID" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_NAME" "$NEW_NAME" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_VERSION" "$NEW_VERSION" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_HW_TYPE" "$NEW_HW_TYPE" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_SW_DESC" "$NEW_SW_DESC" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_BUILD_DATE" "$NEW_DATE" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSA_DESCRIPTION" "$NEW_DESC" "${DOCKER_CONFIG_TMP}"


        NEW_SIZE=$(docker images --format "{{.Size}}" ${NEW_FS}:${NEW_TAG})
        
        if [[ -n $NEW_SIZE ]]; then 
            NEW_SIZE="${NEW_SIZE%??}"
            NEW_SIZE="${NEW_SIZE%.*}"
            NEW_SIZE=$((NEW_SIZE * 1000))
            update_yaml_value "NEPI_FSB_SIZE_MB" "$NEW_SIZE" "${DOCKER_CONFIG_TMP}"; 
        fi

    elif  [[ -n $NEW_ID && $NEPI_AB_FS -ne 1 ]]; then

        #echo "Clearing NEPI NEPI_FSB Config Info in ${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_TAG" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_ID" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_NAME" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_VERSION" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_HW_TYPE" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_SW_DESC" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_BUILD_DATE" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_DESCRIPTION" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_SIZE_MB" 0.0 "${DOCKER_CONFIG_TMP}"
        #echo "Removing NEPI NEPI_FSB Image ${NEW_ID}"
        docker rmi $NEW_ID
        NEW_TAG=unknown
        NEW_ID=unknown

    else
        #echo "Clearing NEPI NEPI_FSB Config Info in ${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_TAG" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_ID" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_NAME" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_VERSION" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_HW_TYPE" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_SW_DESC" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_BUILD_DATE" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_DESCRIPTION" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FSB_SIZE_MB" 0.0 "${DOCKER_CONFIG_TMP}"
        NEW_TAG=unknown
        NEW_ID=unknown

    fi

    export NEPI_FSB=$NEW_FS
    export NEPI_FSB_TAG=$NEW_TAG
    export NEPI_FSB_ID=$NEW_ID

    #echo "Updating FSB Name Tag ID with: ${NEPI_FSB} ${NEPI_FSB_TAG} ${NEPI_FSB_ID}"

    ################
    # Update Running NEPI Image

    RUN_FS=''
    RUN_NAME=($(docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_FSA}" | awk '{print $2}'))
    RUN_NAME=${RUN_NAME[0]}
    if [[ -n "$RUN_NAME" ]]; then
        RUN_FS=$NEPI_FSA
        RUN_TAG=$NEPI_FSA_TAG
    else
        RUN_NAME=($(docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_FSB}" | awk '{print $2}'))
        RUN_NAME=${RUN_NAME[0]}
        if [[ -n "$RUN_NAME" ]]; then
            RUN_FS=$NEPI_FSB
            RUN_TAG=$NEPI_FSB_TAG
        fi
    fi

    if [[ -n "$RUN_FS" ]]; then
        RUN_ID=$(docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${RUN_FS}" | awk '{print $1}')
        #RUN_TAG="${RUN_FS#*:}"
        started_at_str=$(docker inspect --format='{{.State.StartedAt}}' "$RUN_ID")
        
        started_at_human=$(echo "$started_at_str" | sed 's/\..*Z/ /; s/T/ /')
        start_epoch=$(date --date="$started_at_human" "+%s")
        now_epoch=$(date "+%s")
        uptime_seconds=$((now_epoch - START_EPOCH))
        RUN_TIME=$(printf '%02d:%02d:%02d\n' $(($uptime_seconds/3600)) $(($uptime_seconds%3600/60)) $(($uptime_seconds%60)))
        # size_gb=${(docker ps --size --filter "id=$RUN_ID" | tail -n1 | tail -n1) && size_gb="${size_gb##* }" && size_gb="${size_gb%%'.'*}" && size_gb=$((size_gb + 1))::-2}  
        size_gb=$(docker ps --size --filter id="${RUN_ID}" --format "{{.Size}}" | awk '{print $NF}')
        RUN_SIZE_GB=${size_gb%???}
        #echo "Got Running FSA Check Name Tag ID: ${NEPI_FSA} ${NEPI_FSA_TAG} ${CONTAINER_ID}"
        #echo "Updating NEPI Docker Config Runnning Values"
        update_yaml_value "NEPI_RUNNING" 1 "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_RUNNING_FS" "$RUN_FS" "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_RUNNING_TAG" "$RUN_TAG" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RUNNING_ID" $RUN_ID "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RUNNING_SIZE_GB" $RUN_SIZE_GB "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RUNNING_TIME" $RUN_TIME "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FS_RESTART" 0 "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RESTARTING" 0 "${DOCKER_CONFIG_TMP}"

    else 
       

        #echo "NEPI Container NOT Running"
        #echo "Updating NEPI Docker Config Runnning Values"
        update_yaml_value "NEPI_RUNNING" 0 "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_RUNNING_FS" "unknown" "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_RUNNING_TAG" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RUNNING_ID" "unknown" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RUNNING_SIZE_GB" 0 "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "0:0:0" "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FS_RESTART" 0 "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_RESTARTING" 0 "${DOCKER_CONFIG_TMP}"

    fi

  

    ##########################
    # Update Active and Inactive FS

    if [[ $NEPI_AB_FS -ne 1 ]]; then
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
        
    update_yaml_value "NEPI_ACTIVE_FS" $NEPI_ACTIVE_FS "${DOCKER_CONFIG_TMP}"
    update_yaml_value "NEPI_INACTIVE_FS" $NEPI_INACTIVE_FS "${DOCKER_CONFIG_TMP}"
    #echo "Updated FS Active and Inactive FS to: ${NEPI_ACTIVE_FS} ${NEPI_INACTIVE_FS}"

    ##########################
    # Resetting Import and Export if needed
    pname="docker import"
    pcount=$(process_count $pname)
    if [[ "$process_count" -eq 0 ]]; then
        update_yaml_value "NEPI_IMPORT_TAG" "unknown" "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_IMPORT_ID" "unknown" "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_FS_INITIALIZE" 0 "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_IMPORTING" 0 "$DOCKER_CONFIG_TMP"
        update_yaml_value "NEPI_FS_IMPORT" 0 "$DOCKER_CONFIG_TMP"
    fi


    
    pname="docker export"
    pcount=$(process_count $pname)
    if [[ "$process_count" -eq 0 ]]; then
        export_file=${NEPI_EXPORT_PATH}/nepi_export_staging
        if [[ -f "$export_file" ]]; then
            echo "Cleaning up left over nepi_export_staging file"
            rm $export_file
        fi
        update_yaml_value "NEPI_EXPORT_PATH" 'unknown' "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_EXPORTING" 0 "${DOCKER_CONFIG_TMP}"
        update_yaml_value "NEPI_FS_EXPORT" 0 "${DOCKER_CONFIG_TMP}"
    fi
    avail_space=$(path_space_gb $NEPI_EXPORT_PATH)
    # avail_space_bytes=$(df -B1 $NEPI_EXPORT_PATH | awk 'NR==2{print $4}')
    # avail_space_gigabytes=$(echo "scale=2; $avail_space_bytes / 1000000000" | bc)
    update_yaml_value "NEPI_EXPORT_SPACE_GB" $avail_space "${DOCKER_CONFIG_TMP}"


    ###################
    # Clean Up
    #ssync_yaml_files $DOCKER_CONFIG_BLANK $DOCKER_CONFIG_TMP 
    cp $DOCKER_CONFIG_TMP $DOCKER_CONFIG_FILE 
    rm $DOCKER_CONFIG_TMP
    chown ${CONFIG_USER}:${CONFIG_USER} $DOCKER_CONFIG_FILE
# fi