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


# This file exports the running fs to a tar file
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

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
DOCKER_CONFIG_UPDATE_FILE=${DOCKER_FOLDER}/nepi_docker_update.sh


#######################
# Update Docker Config
echo ""
echo "Updating Docker Config File"

source $DOCKER_CONFIG_UPDATE_FILE
if [[ "$?" -eq 1 ]]; then
    echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
else

    if [[ "$NEPI_EXPORTING" -eq 0 ]]; then
        update_yaml_value "NEPI_EXPORT_FILE" 'unknown' "$DOCKER_CONFIG_FILE"
        update_yaml_value "NEPI_EXPORT_FS" 'unknown' "$DOCKER_CONFIG_FILE"
        update_yaml_value "NEPI_EXPORT_TAG" 'unknown' "$DOCKER_CONFIG_FILE"
        ########################
        # Start Processes
        EXPORT_PATH=$NEPI_EXPORT_PATH
        sudo rm -r /mnt/nepi_storage/.Trash* >/dev/null 2>&1
        export_clean=0
        if [[ -z "$1" ]]; then
            if [[ "$1" == 'clean' ]]; then
                export_clean=1
            else
                EXPORT_PATH=$NEPI_EXPORT_PATH
            fi
        fi

        if [[ ! -d "${EXPORT_PATH}" ]] ; then
            EXPORT_PATH=/mnt/nepi_storage/nepi_images
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


                if [[ "$export_clean" == 1 ]]; then
                    NEW_DESC=''
                else
                    NEW_DESC=${TAG_ARRAY[6]}
                    if [[ "$NEW_DESC" =~ _[0-9]{4}$ ]]; then
                        NEW_DESC=${NEW_DESC%?????}
                        NEW_DESC="${NEW_DESC}_$(date +%H%M)"
                    elif [[ -n "$NEW_DESC" ]]; then
                        NEW_DESC="${NEW_DESC}_$(date +%H%M)"
                    else
                        NEW_DESC="$(date +%H%M)"
                    fi
                    NEW_DESC=$(clean_tag_string $NEW_DESC)
                    NEW_DESC="-${NEPI_DESC}"
                fi
                if [[ "$NEW_DESC" == '-' ]]; then
                    NEW_DESC=''
                fi

        
        
                NEPI_EXPORT_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}-${NEW_DESC}"
                # update_yaml_value "NEPI_EXPORT_TAG" "${NEPI_EXPORT_TAG}" "${DOCKER_CONFIG_FILE}"
 
            
                NEPI_EXPORT_TAG=${NEPI_EXPORT_TAG,,}
            fi

            if [[ -z "$NEPI_EXPORT_TAG" ]]; then
                NEPI_EXPORT_TAG=$NEPI_RUNNING_ID
            fi
            echo "Got Export Name: ${NEPI_EXPORT_TAG}"
            
            EXPORT_STAGING_PATH=${EXPORT_PATH}/nepi_export_staging
            EXPORT_FILE_PATH=${EXPORT_PATH}/${NEPI_EXPORT_TAG}
            parent_path=$(dirname "$EXPORT_FILE_PATH")
            if [[ ${parent_path:0:1} != '.' && ${parent_path:0:1} != '/' && ! -d "${parent_path}" ]]; then
                echo "Export Folder Not Found ${parent_path}"
            else
            
                # avail_space=$(path_space_gb $parent_path)
                # req_space=$(sudo docker ps --size --filter "id=$NEPI_RUNNING_ID" | tail -n1 | tail -n1) && req_space="${req_space##* }" && req_space="${req_space%%'.'*}" && req_space=$((req_space + 1))
                # if [[ "$avial_space" -lt "$req_space" ]]; then
                #     need_space_gb=$((req_space - avail_space))
                #     echo "--------------------------------------------------------------"
                #     echo "FAILED TO EXPORT, NOT ENOUGH SPACE AVAILABLE AT: ${parent_path}"
                #     echo "Free up ${need_space_gb} GB in that folders partition and try again"
                #     echo "--------------------------------------------------------------"
                # else


                    EXPORT_FILE_PATH="${EXPORT_FILE_PATH%.*}"
                    TAR_EXPORT_PATH="${EXPORT_FILE_PATH}.tar"
                    if [[ -f $TAR_EXPORT_PATH ]]; then
                        TAR_EXPORT_PATH="${TAR_EXPORT_PATH%.*}"
                        TAR_EXPORT_PATH=$TAR_EXPORT_PATH"-$(date +%S)"
                        TAR_EXPORT_PATH="${TAR_EXPORT_PATH}.tar"
                    fi
                    TAR_EXPORT_PATH=${TAR_EXPORT_PATH,,}
                    echo "Staging Image Export to: ${EXPORT_STAGING_PATH}"

                    update_yaml_value "NEPI_FS_EXPORT" 0 "$DOCKER_CONFIG_FILE"
                    update_yaml_value "NEPI_EXPORTING" 1 "$DOCKER_CONFIG_FILE"
                    update_yaml_value "NEPI_EXPORT_FILE" $EXPORT_STAGING_PATH "$DOCKER_CONFIG_FILE"
                    update_yaml_value "NEPI_EXPORT_FS" $NEPI_EXPORT_FS "$DOCKER_CONFIG_FILE"
                    update_yaml_value "NEPI_EXPORT_TAG" $NEPI_EXPORT_TAG "$DOCKER_CONFIG_FILE"




                    sudo docker export $NEPI_RUNNING_ID > $EXPORT_STAGING_PATH
                    if [[ "$?" -eq 0 ]]; then
                        echo "Export succeeded"
                        echo "Moving Image to: ${TAR_EXPORT_PATH}"
                        sudo mv $EXPORT_STAGING_PATH $TAR_EXPORT_PATH
                        update_yaml_value "NEPI_EXPORT_FILE" $TAR_EXPORT_PATH "$DOCKER_CONFIG_FILE"
                        update_yaml_value "NEPI_EXPORT_FS" $NEPI_EXPORT_FS "$DOCKER_CONFIG_FILE"
                        update_yaml_value "NEPI_EXPORT_TAG" $NEPI_EXPORT_TAG "$DOCKER_CONFIG_FILE"
                        ls /mnt/nepi_storage/nepi_images
                    else
                        echo ""
                        echo "------------------------------------------------"
                        echo "NEPI Image Failed to Export: ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG}"
                        echo "  to file ${EXPORT_FILE_PATH}"
                        echo "------------------------------------------------"
                        sudo rm $EXPORT_STAGING_PATH
                        update_yaml_value "NEPI_EXPORT_FILE" 'unknown' "$DOCKER_CONFIG_FILE"
                        update_yaml_value "NEPI_EXPORT_FS" 'unknown' "$DOCKER_CONFIG_FILE"
                        update_yaml_value "NEPI_EXPORT_TAG" 'unknown' "$DOCKER_CONFIG_FILE"


                    fi
                    ########################
                    # Update Docker Config
                    echo ""
                    echo "Updating Docker Config File"
                    bash ${DOCKER_FOLDER}/nepi_docker_update.sh
                    wait
                #fi

            fi
        else
            echo "No Running NEPI Container to Export"
        fi

        update_yaml_value "NEPI_FS_EXPORT" 0 "$DOCKER_CONFIG_FILE"
        update_yaml_value "NEPI_EXPORTING" 0 "$DOCKER_CONFIG_FILE"
    else
        echo "Export allready in progress"
    fi

fi