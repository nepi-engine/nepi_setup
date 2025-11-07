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


    if [[ "$NEPI_IMPORTING" -eq 1 ]]; then
        echo "Image import allready in progress"

    else
        ########################
        echo "Proceeding with the import..."
        INSTALL_IMAGE=$1



        ###################
        # Get Install Image Path
        # Check if Full Path Provided

        

        if [[ -f $INSTALL_IMAGE ]]; then

            echo "Importing image from: ${INSTALL_IMAGE}"
            update_yaml_value "NEPI_IMPORTING" 1 "$CONFIG_SOURCE"


            NEPI_IMPORT_FILE=$(basename "$INSTALL_IMAGE")

            # Get Imported Tag and IMPORT_ID 
            NEPI_IMPORT_TAG="${NEPI_IMPORT_FILE%.*}"
            #echo $NEPI_IMPORT_TAG


            #########################
            if [[ -n "$2" && ( "$2" == 'nepi_fs_a' ||  "$2" == 'nepi_fs_b' ) ]]; then
                INSTALL_NAME=$2
            elif [[ "$NEPI_AB_FS" -eq 1 ]]; then
                INSTALL_NAME=$NEPI_INACTIVE_FS
            else
                INSTALL_NAME=nepi_fs_a
            fi

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
                
                run_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${INSTALL_NAME}" | awk '{print $2}'))
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


                exist_ids=($(sudo docker images --filter "reference=${INSTALL_NAME}" --format "{{.ID}}"))
                if [[ -n "$exist_ids" ]]; then
                echo "Removing existing images ${INSTALL_NAME}"
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
                echo "Can't install Image file ${INSTALL_NAME}"
                echo "Not enough free space in folder: ${NEPI_DOCKER}"
                echo "Need ${NEPI_GB_CONTAINER}GB, but only ${NEPI_DOCKER_SPACE}GB is aviable"
            else
                #IMPORT_ID=debug
                echo "Importing file ${INSTALL_IMAGE} for NEPI Docker Image: ${INSTALL_NAME}"
                echo "Staging import nepi_staging:${NEPI_IMPORT_TAG}"
                res=$(sudo docker import $INSTALL_IMAGE nepi_staging:${NEPI_IMPORT_TAG})
                wait
                hash=${res##*sha256:}
                IMPORT_ID=${hash:0:12}
                NEPI_IMPORT_ID=$IMPORT_ID

                if [[ -n "$IMPORT_ID" ]]; then
                        echo "Docker import succeeded with IMPORT_ID: $IMPORT_ID"
                        update_yaml_value "NEPI_IMPORT_TAG" "$NEPI_IMPORT_TAG" "$CONFIG_SOURCE"
                        update_yaml_value "NEPI_IMPORT_ID" "$IMPORT_ID" "$CONFIG_SOURCE"

                        run_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${INSTALL_NAME}" | awk '{print $2}'))
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
                        exist_ids=($(sudo docker images --filter "reference=${INSTALL_NAME}" --format "{{.ID}}"))
                        if [[ -n "$exist_ids" ]]; then
                        echo "Removing existing images ${INSTALL_NAME}"
                            for id in "${exist_ids[@]}"; do
                                echo "Removing ${id}"
                                sudo docker rmi -f $id
                            done
                        fi

                        # Copy the Staging to the NEPI_FSA image
                        echo "Renaming staging import to ${INSTALL_NAME}:${NEPI_IMPORT_TAG}"
                        sudo docker tag "nepi_staging:${NEPI_IMPORT_TAG}" "${INSTALL_NAME}:${NEPI_IMPORT_TAG}" 
                        wait
                        echo "Renaming staging import tag"
                        sudo docker rmi "nepi_staging:${NEPI_IMPORT_TAG}"

                        #############
                        echo ""
                        echo "--------------------------"
                        echo "NEPI Image Import Complete"
                        echo ""
                        dimg


                else
                    echo ""
                    echo "--------------------------"
                    echo "NEPI Image Failed to Import: ${INSTALL_IMAGE}"
                    
                fi

                update_yaml_value "NEPI_IMPORT_TAG" "unknown" "$CONFIG_SOURCE"
                update_yaml_value "NEPI_IMPORT_ID" "unknown" "$CONFIG_SOURCE"
                update_yaml_value "NEPI_FS_INITIALIZE" 0 "$CONFIG_SOURCE"
                update_yaml_value "NEPI_IMPORTING" 0 "$CONFIG_SOURCE"
                update_yaml_value "NEPI_FS_IMPORT" 0 "$CONFIG_SOURCE"

            fi
        else
            echo "Tar file not found: ${INSTALL_IMAGE}"
        fi
    fi
    
fi
