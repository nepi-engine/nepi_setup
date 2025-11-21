#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file exports the running fs to a tar file
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
DOCKER_CONFIG_UPDATE_FILE=${DOCKER_FOLDER}/nepi_docker_update.sh

########################
# Update Docker Config
echo ""
echo "Updating Docker Config File"

source $DOCKER_CONFIG_UPDATE_FILE
if [[ "$?" -eq 1 ]]; then
    echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
else

    ########################
    # Start Processes
    EXPORT_PATH=$1
    if [[ -z "$EXPORT_PATH" ]]; then
        EXPORT_PATH=$NEPI_EXPORT_PATH
        if [[ ! -d "${EXPORT_PATH}" ]] ; then
            EXPORT_PATH=/mnt/nepi_storage/nepi_images
        fi
    fi

    # Export Running Container
    if [[ $NEPI_RUNNING_ID != 0 && "$NEPI_RUNNING" -eq 1 ]]; then
        
        # ##################
        # # Check available space
        # NEPI_EXPORT_PATH=/mnt/nepi_storage/nepi_images
        # NEPI_EXPORT_SPACE=$(path_space_gb $NEPI_EXPORT_PATH)
        # NEPI_GB_CONTAINER=$(sudo docker ps --size --filter "id=${NEPI_RUNNING_ID}")
        # check_drive=$NEPI_DOCKER
        # check_space=$NEPI_GB_CONTAINER
        # if ! is_space_avail_gb $check_drive $check_space; then
        #     echo "Can't install Image file ${NEPI_EXPORT_TAG}"
        #     echo "Not enough free space in folder: ${NEPI_DOCKER}"
        #     echo "Need ${NEPI_GB_CONTAINER}GB, but only ${NEPI_EXPORT_SPACE}GB is aviable"
        # else


        ##################
        if [[ -z "$EXPORT_FILENAME" ]]; then # FILE PATH Provided
            
            IFS='-' read -ra TAG_ARRAY <<< "$NEPI_RUNNING_TAG"
            
            NEW_NAME=nepi

            #echo "NEPI_VERSION = ${NEPI_VERSION}"
            NEW_VERSION=$NEPI_VERSION
            if [[ -z "$NEW_VERSION" ]]; then
                NEW_VERSION="${TAG_ARRAY[1]}"
                if [[ -z "$NEW_VERSION" ]]; then
                    NEW_VERSION="0p0p0"
                fi
            fi
            NEW_VERSION=$(clean_tag_string $NEW_VERSION)

            NEW_HW_TYPE=$NEPI_HW_TYPE
            if [[ -z "$NEW_HW_TYPE" ]]; then
                NEW_HW_TYPE="${TAG_ARRAY[2]}"
                if [[ -z "$NEW_HW_TYPE" ]]; then
                    NEW_HW_TYPE=$(get_hw_type)
                fi
            fi
            NEW_HW_TYPE=$(clean_tag_string $NEW_HW_TYPE)

            NEW_SW_DESC=$NEPI_SW_DESC
            if [[ -z "$NEW_SW_DESC" || "$NEW_SW_DESC" == 'unknown' ]]; then
                NEW_SW_DESC="${TAG_ARRAY[3]}"
                if [[ -z "$NEW_SW_DESC" ]]; then
                    NEW_SW_DESC="unknown" # Uknown until NEPI runs 
                fi
            fi
            NEW_SW_DESC=$(clean_tag_string $NEW_SW_DESC)
            

            NEW_DATE=$(date +%Y%m%d)


            NEW_DESC=${TAG_ARRAY[5]}
            if [[ "$NEW_DESC" =~ _[0-9]{4}$ ]]; then
                NEW_DESC=${NEW_DESC%?????}
                NEW_DESC="${NEW_DESC}_$(date +%H%M)"
            elif [[ -n "$NEW_DESC" ]]; then
                NEW_DESC="${NEW_DESC}_$(date +%H%M)"
            else
                NEW_DESC="$(date +%H%M)"
            fi
            NEW_DESC=$(clean_tag_string $NEW_DESC)

    
    
            NEPI_EXPORT_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}-${NEW_DESC}"

        
            NEPI_EXPORT_TAG=${NEPI_EXPORT_TAG,,}
        fi

        if [[ -z "$NEPI_EXPORT_TAG" ]]; then
            NEPI_EXPORT_TAG=$NEPI_RUNNING_ID
        fi
        echo "Got Export Name: ${NEPI_EXPORT_TAG}"
        
        EXPORT_FILE_PATH=${EXPORT_PATH}/${NEPI_EXPORT_TAG}
        parent_path=$(dirname "$EXPORT_FILE_PATH")
        if [[ ${parent_path:0:1} != '.' && ${parent_path:0:1} != '/' && ! -d "${parent_path}" ]]; then
            echo "Export Parent Path Not Found ${parent_path}"
        else
        
            EXPORT_FILE_PATH="${EXPORT_FILE_PATH%.*}"
            TAR_EXPORT_PATH="${EXPORT_FILE_PATH}.tar"
            if [[ -f $TAR_EXPORT_PATH ]]; then
                TAR_EXPORT_PATH="${TAR_EXPORT_PATH%.*}"
                TAR_EXPORT_PATH=$TAR_EXPORT_PATH"-$(date +%S)"
                TAR_EXPORT_PATH="${TAR_EXPORT_PATH}.tar"
            fi
            TAR_EXPORT_PATH=${TAR_EXPORT_PATH,,}
            echo "Exporting FS to: ${TAR_EXPORT_PATH}"

            update_yaml_value "NEPI_FS_IMPORT" 0 "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_IMPORTING" 1 "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_EXPORT_FILE" $TAR_EXPORT_PATH "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_EXPORT_FS" $NEPI_EXPORT_FS "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_EXPORT_TAG" $NEPI_EXPORT_TAG "$DOCKER_CONFIG_FILE"




            sudo docker export $NEPI_RUNNING_ID > $TAR_EXPORT_PATH

            ########################
            # Update Docker Config
            echo ""
            echo "Updating Docker Config File"
            bash ${DOCKER_FOLDER}/nepi_docker_update.sh
            wait

            if [[ "$?" -eq 0 ]]; then
                echo ""
                echo "--------------------------"
                echo "NEPI Image Export Complete"
                echo ""
                ls /mnt/nepi_storage/nepi_images



            else
                echo ""
                echo "--------------------------"
                echo "NEPI Image Failed to Export: ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG}"
                echo "  to file ${EXPORT_FILE_PATH}"
            fi

        fi
    else
        echo "No Running NEPI Container to Export"
    fi

    update_yaml_value "NEPI_FS_EXPORT" 0 "$DOCKER_CONFIG_FILE"
    update_yaml_value "NEPI_EXPORTING" 0 "$DOCKER_CONFIG_FILE"
    update_yaml_value "NEPI_EXPORT_FILE" "unknown" "$DOCKER_CONFIG_FILE"
    update_yaml_value "NEPI_EXPORT_FS" "unknown" "$DOCKER_CONFIG_FILE"
    update_yaml_value "NEPI_EXPORT_TAG" "unknown" "$DOCKER_CONFIG_FILE"




fi