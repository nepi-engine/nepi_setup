#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This file imports an image from a tar file to the inactive fs
sudo -v

CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
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

########################
# Update Docker Config
echo ""
echo "Updating Docker Config File"
bash ${SCRIPT_FOLDER}/nepi_docker_update.sh
wait
########################
# Load NEPI DOCKER
CONFIG_SOURCE=${SCRIPT_FOLDER}/nepi_docker_config.yaml
source ${SCRIPT_FOLDER}/load_docker_config.sh
if [[ "$?" -eq 1 ]]; then
    echo "Failed to load ${CONFIG_SOURCE}"

else

    ########################
    # Start Processes
    PULL_REF=$1

    if [[ "$NEPI_IMPORTING" -eq 1 ]]; then
        echo "Image import allready in progress"
    elif [[ -z "$PULL_REF" ]]; then
        echo "No Pull Reference Provided"

    else
        ########################
        echo "Proceeding with the import..."
    


        PULL_FS="${PULL_REF%%:*}"

        if [[ "$PULL_REF" == *:*  ]]; then
            PULL_TAG="${PULL_REF##*:}"
        else
            PULL_TAG=latest
        fi

        echo "Importing image from: ${PULL_REF} with name ${PULL_FS} and tag ${PULL_TAG}"
                        

            ###########
            if [[ -n "$2" && ( "$2" == 'nepi_fs_a' ||  "$2" == 'nepi_fs_b' ) ]]; then
                NEPI_IMPORT_FS=$2
            elif [[ "$NEPI_AB_FS" -eq 1 ]]; then
                NEPI_IMPORT_FS=$NEPI_INACTIVE_FS
            else
                NEPI_IMPORT_FS=nepi_fs_a
            fi


            ###########
            # Get Imported Tag and IMPORT_ID 
            NEPI_IMPORT_TAG=$2
            if [[ -z "$NEPI_IMPORT_TAG" ]]; then
                NEPI_IMPORT_TAG=$NEPI_IMPORT_TAG
                if [[ "$NEPI_IMPORT_TAG" == 'uknown' ]]; then               
                    NEPI_IMPORT_TAG=$PULL_TAG
            fi


            if [[ "${NEPI_IMPORT_TAG:0:4}" == 'nepi' ]]; then # NEPI Produced Image



                IFS='-' read -ra TAG_ARRAY <<< "$NEPI_IMPORT_TAG"
                

                NEW_NAME=nepi

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

                NEW_DATE=$(clean_tag_string "${TAG_ARRAY[3]}")
                if [[ -z "$NEW_DATE" ]]; then
                    NEW_DATE=$(date +%Y%m%d)
                fi          
        
        
                NEPI_IMPORT_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}"

            else # Non NEPI Produced Image
                
                NEW_NAME=nepi
                NEW_VERSION="0p0p0"
                NEW_HW_TYPE=$(clean_tag_string $(get_hw_type))

                new_fs_name=$PULL_FS
                if [[ "$new_fs_name" == */* ]]; then
                    new_fs_name="${PULL_FS##*/}"
                fi
                sw_desc=${new_fs_name}'_'${PULL_TAG}
                echo $PULL_TAG
                echo $sw_desc
                echo $(clean_tag_string $sw_desc)
                NEW_SW_DESC=$(clean_tag_string $sw_desc) # Updated by NEPI Software 

                NEW_DATE=$(date +%Y%m%d-%H%M)        

                NEPI_IMPORT_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}"

            fi


            # NEW_DESC="${TAG_ARRAY[5]}"
            # if [[ -n "$NEW_DESC" ]]; then
            #     NEPI_IMPORT_TAG="${NEPI_IMPORT_TAG}-${NEW_DESC}"
            # fi
        
            

            NEPI_IMPORT_TAG=${NEPI_IMPORT_TAG,,}


            ##########
            update_yaml_value "NEPI_FS_IMPORT" 0 "$CONFIG_SOURCE"
            update_yaml_value "NEPI_IMPORTING" 1 "$CONFIG_SOURCE"
            update_yaml_value "NEPI_IMPORT_FILE" $PULL_REF "$CONFIG_SOURCE"
            update_yaml_value "NEPI_IMPORT_FS" $NEPI_IMPORT_FS "$CONFIG_SOURCE"
            update_yaml_value "NEPI_IMPORT_TAG" $NEPI_IMPORT_TAG "$CONFIG_SOURCE"


\
            #########################
            # Clear any existing staging images

            STAGING_NAME=nepi_staging
            if [[ -n "$exists_ids" ]]; then
            exist_ids=($(sudo docker images --filter "reference=${STAGING_NAME}" --format "{{.ID}}"))
            echo "Removing existing Staging Images ${STAGING_NAME}"
                for id in "${exist_ids[@]}"; do
                    echo "Removing ${id}"
                    sudo docker rmi -f $id
                done
            fi


            #########################
            NEPI_DOCKER=$(sudo docker info --format '{{ .DockerRootDir }}')
            NEPI_DOCKER_SPACE=$(path_space_gb $NEPI_DOCKER)
            NEPI_GB_CONTAINER=$(path_size_gb $PULL_REF)
            echo "Checking avail space in ${NEPI_DOCKER}"

            check_drive=$NEPI_DOCKER
            check_space=$NEPI_GB_CONTAINER
            if ! is_space_avail_gb $check_drive $check_space; then
                
                run_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_IMPORT_FS}" | awk '{print $2}'))
                if [[ -n "$run_names" ]]; then
                    for run_name in "${run_names[@]}"; do
                        if [[ -n "$run_name" ]]; then
                            echo "Removing running images for ${run_name}"
                            run_id=$(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${run_name}" | awk '{print $1}')
                            if [[ -n "$run_id" ]]; then
                                echo "Removing ${run_id}"
                                sudo docker stop -f $run_id
                                wait
                                sudo docker rm -f $run_id
                            fi
                        fi
                    done
                fi


                exist_ids=($(sudo docker images --filter "reference=${NEPI_IMPORT_FS}" --format "{{.ID}}"))
                if [[ -n "$exist_ids" ]]; then
                echo "Removing existing images ${NEPI_IMPORT_FS}"
                    for id in "${exist_ids[@]}"; do
                        echo "Removing ${id}"
                        sudo docker rmi -f $id
                    done
                fi
            fi

            #########################
            NEPI_DOCKER_SPACE=$(path_space_gb $NEPI_DOCKER)
            check_drive=$NEPI_DOCKER
            check_space=$NEPI_GB_CONTAINER
            if ! is_space_avail_gb $check_drive $check_space; then
                echo "Can't install Image file ${NEPI_IMPORT_FS}"
                echo "Not enough free space in folder: ${NEPI_DOCKER}"
                echo "Need ${NEPI_GB_CONTAINER}GB, but only ${NEPI_DOCKER_SPACE}GB is aviable"
            else
                #IMPORT_ID=debug
                echo "Importing image ${PULL_REF} for NEPI Docker Image: ${NEPI_IMPORT_FS}"
                res=$(sudo docker pull $PULL_REF)
                wait
                IMPORT_ID=$(sudo docker images -q ${PULL_FS})

                if [[ -n "$IMPORT_ID" ]]; then
                        echo "Docker import succeeded with IMPORT_ID: $IMPORT_ID"
                        
                        run_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${NEPI_IMPORT_FS}" | awk '{print $2}'))
                        if [[ -n "$run_names" ]]; then
                            for run_name in "${run_names[@]}"; do
                                if [[ -n "$run_name" ]]; then
                                    echo "Removing running images for ${run_name}"
                                    run_id=$(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${run_name}" | awk '{print $1}')
                                    if [[ -n "$run_id" ]]; then
                                        echo "Removing ${run_id}"
                                        sudo docker rm -f $run_id
                                        wait
                                        sudo docker rm -f $run_id
                                    fi
                                fi
                            done
                        fi

                        # Remove existing NEPI image if needed
                        exist_ids=($(sudo docker images --filter "reference=${NEPI_IMPORT_FS}" --format "{{.ID}}"))
                        if [[ -n "$exist_ids" ]]; then
                        echo "Removing existing images ${NEPI_IMPORT_FS}"
                            for id in "${exist_ids[@]}"; do
                                echo "Removing ${id}"
                                sudo docker rmi -f $id
                            done
                        fi

                        # Copy the Staging to the NEPI_FSA image
                        PULL_TAG=($(sudo docker images --format "{{.Repository}} {{.Tag}} {{.ID}}" | grep "${IMPORT_ID}" | awk '{print $2}'))
                        echo "Renaming import to ${PULL_FS}:${PULL_TAG} to ${NEPI_IMPORT_FS}:${NEPI_IMPORT_TAG}"

                        sudo docker tag "${PULL_FS}:${PULL_TAG}" "${NEPI_IMPORT_FS}:${NEPI_IMPORT_TAG}" 
                        wait
                        echo "Removing pull import tag"
                        sudo docker rmi "${PULL_FS}:${PULL_TAG}"

                        #############
                        echo ""
                        echo "--------------------------"
                        echo "NEPI Image Import Complete"
                        echo ""
                        dimg


                else
                    echo ""
                    echo "--------------------------"
                    echo "NEPI Image Failed to Import: ${PULL_REF}"
                    
                fi
                
                update_yaml_value "NEPI_FS_IMPORT" 0 "$CONFIG_SOURCE"
                update_yaml_value "NEPI_IMPORTING" 0 "$CONFIG_SOURCE"
                update_yaml_value "NEPI_IMPORT_FILE" "unknown" "$CONFIG_SOURCE"
                update_yaml_value "NEPI_IMPORT_FS" "unknown" "$CONFIG_SOURCE"
                update_yaml_value "NEPI_IMPORT_TAG" "unknown" "$CONFIG_SOURCE"
                

                ########################
                # Update Docker Config
                echo ""
                echo "Updating Docker Config File"
                bash ${SCRIPT_FOLDER}/nepi_docker_update.sh
                wait

            fi
        else
            echo "Failed to find NEPI Image '.tar' file at: ${PULL_REF}"
        fi
    fi
    
fi
