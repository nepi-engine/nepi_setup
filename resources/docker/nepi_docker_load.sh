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

# This file loads an image from a .archive.tar file to the inactive fs
sudo -v

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


    if [[ "$NEPI_IMPORTING" -eq 1 ]]; then
        echo "Image load allready in progress"

    else
        ########################
        echo "Proceeding with the load..."
        INSTALL_IMAGE=$1


        if [[ -z "$INSTALL_IMAGE" ]]; then
            INSTALL_IMAGE=$NEPI_IMPORT_FILE
        fi


        if [[ ! -f $INSTALL_IMAGE ]]; then
            INSTALL_IMAGE=/mnt/nepi_storage/nepi_images/${INSTALL_IMAGE}
        fi

        INSTALL_FILE=$(basename ${INSTALL_IMAGE})

        

        if [[ -f $INSTALL_IMAGE && "${INSTALL_IMAGE##*.}" == "tar" &&  "$INSTALL_IMAGE" != "*.archive.tar" ]]; then
            echo "The selected file is a NEPI Image file.  Use 'nepiimport' to import the file"

        elif [[ -f $INSTALL_IMAGE && "${INSTALL_IMAGE##*.}" == "tar" ]]; then

            echo "Loading image from: ${INSTALL_IMAGE}"
                        

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
            NEPI_IMPORT_TAG="${INSTALL_FILE%%.*}"

            echo "Got Load Tag: ${NEPI_IMPORT_TAG}"

            if [[ "${NEPI_IMPORT_TAG:0:4}" == 'nepi' ]]; then # NEPI Produced Image

                #echo "Updating Load Tag: ${NEPI_IMPORT_TAG}"

                IFS='-' read -ra TAG_ARRAY <<< "$NEPI_IMPORT_TAG"
                

                NEW_NAME=nepi


                NEW_VERSION="${TAG_ARRAY[1]}"
                if [[ -z "$NEW_VERSION" ]]; then
                    NEW_VERSION="0p0p0"
                fi
                NEW_VERSION=$(clean_tag_string "${NEW_VERSION}")

                NEW_HW_TYPE="${TAG_ARRAY[2]}"
                if [[ -z "$NEW_HW_TYPE" ]]; then
                    NEW_HW_TYPE=$(get_hw_type)
                fi
                NEW_HW_TYPE=$(clean_tag_string "${NEW_HW_TYPE}")

                NEW_SW_DESC="${TAG_ARRAY[3]}"
                if [[ -z "$NEW_SW_DESC" ]]; then
                        NEW_SW_DESC=$NEPI_SW_DESC # Updated by NEPI Software 
                        if [[ -z "$NEW_SW_DESC" ]]; then
                            NEW_SW_DESC="unknown" # Uknown until NEPI runs 
                    fi
                fi
                NEW_SW_DESC=$(clean_tag_string "${NEW_SW_DESC}")

                NEW_DATE="${TAG_ARRAY[4]}"
                if [[ -z "$NEW_DATE" ]]; then
                    NEW_DATE=$(date +%Y%m%d-%H%M)
                fi       
                NEW_DATE=$(clean_tag_string "${NEW_DATE}")   

                NEW_DESC="${TAG_ARRAY[5]}"   
                NEW_DESC=$(clean_tag_string "${NEW_DESC}")   
                if [[ -n "$NEW_DESC" ]]; then
                    NEW_DESC="-${NEW_DESC}"
                fi     
        
        
                NEPI_IMPORT_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}${NEW_DESC}"

            else # Non NEPI Produced Image

                #nsw_tag=$(clean_tag_string $NEPI_IMPORT_TAG)
                #echo "Creating Load Tag: ${NEPI_IMPORT_TAG}  with sw_tag ${nsw_tag}"
               
                NEW_NAME=nepi
                NEW_VERSION="0p0p0"
                NEW_HW_TYPE=$(clean_tag_string $(get_hw_type))
                NEW_SW_DESC=$(clean_tag_string $NEPI_IMPORT_TAG) # Updated by NEPI Software 
                NEW_DATE=$(date +%Y%m%d-%H%M)        
                NEPI_IMPORT_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}"

            fi


            # NEW_DESC="${TAG_ARRAY[5]}"
            # if [[ -n "$NEW_DESC" ]]; then
            #     NEPI_IMPORT_TAG="${NEPI_IMPORT_TAG}-${NEW_DESC}"
            # fi
        
            

            NEPI_IMPORT_TAG=${NEPI_IMPORT_TAG,,}


            ##########
            update_yaml_value "NEPI_FS_IMPORT" 0 "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_IMPORTING" 1 "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_IMPORT_FILE" $INSTALL_IMAGE "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_IMPORT_FS" $NEPI_IMPORT_FS "$DOCKER_CONFIG_FILE"
            update_yaml_value "NEPI_IMPORT_TAG" $NEPI_IMPORT_TAG "$DOCKER_CONFIG_FILE"


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
            NEPI_GB_CONTAINER=$(path_size_gb $INSTALL_IMAGE)
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
                echo "Loading file ${INSTALL_IMAGE} for NEPI Docker Image: ${NEPI_IMPORT_FS}"
                echo "Staging load nepi_staging:${NEPI_IMPORT_TAG}"
                res=$(sudo docker load $INSTALL_IMAGE nepi_staging:${NEPI_IMPORT_TAG})
                wait
                hash=${res##*sha256:}
                IMPORT_ID=${hash:0:12}
                NEPI_IMPORT_ID=$IMPORT_ID

                if [[ -n "$IMPORT_ID" ]]; then
                        echo "Docker load succeeded with IMPORT_ID: $IMPORT_ID"

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
                        echo "Renaming staging load to ${NEPI_IMPORT_FS}:${NEPI_IMPORT_TAG}"
                        sudo docker tag "nepi_staging:${NEPI_IMPORT_TAG}" "${NEPI_IMPORT_FS}:${NEPI_IMPORT_TAG}" 
                        wait
                        echo "Renaming staging load tag"
                        sudo docker rmi "nepi_staging:${NEPI_IMPORT_TAG}"

                        #############
                        echo ""
                        echo "--------------------------"
                        echo "NEPI Image Load Complete"
                        echo ""
                        dimg


                else
                    echo ""
                    echo "--------------------------"
                    echo "NEPI Image Failed to Load: ${INSTALL_IMAGE}"
                    
                fi
                
                update_yaml_value "NEPI_FS_IMPORT" 0 "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORTING" 0 "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_FILE" "unknown" "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_FS" "unknown" "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_TAG" "unknown" "$DOCKER_CONFIG_FILE"
                

                ########################
                # Update Docker Config
                echo ""
                echo "Updating Docker Config File"
                bash ${DOCKER_FOLDER}/nepi_docker_update.sh
                wait

            fi
        else
            echo "Failed to find NEPI Image file at: ${INSTALL_IMAGE}"
        fi
    fi
    
fi
