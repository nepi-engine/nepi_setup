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

# This file pulls a NEPI image from DockerHub and installs it to the inactive fs
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


ninet > /dev/null 2>&1

if ! is_valid_internet > /dev/null; then
    echo "No Internet Connection Detected.  Connect and rerun this script"

else

    ########################
    # Update Docker Config

    # Accept image passed as script argument
    PASSED_IMAGE="$1"

    ########################
    # Select hub image based on hardware
    HUB_IMAGE=""
    if is_valid_amd64; then
        if is_valid_cuda; then
            HUB_IMAGE="numurusinc/nepi:latest-amd64-cuda"
        else
            HUB_IMAGE="numurusinc/nepi:latest-amd64"
        fi
    elif is_valid_jetson; then
        HUB_IMAGE="numurusinc/nepi:latest-jetson"
    elif is_valid_rpi; then
        HUB_IMAGE="numurusinc/nepi:latest-rpi"
        
    fi

    if [[ -n "$PASSED_IMAGE" ]]; then
        HUB_IMAGE="$PASSED_IMAGE"
    fi

    if [[ -z "$HUB_IMAGE" ]]; then
        echo "Unsupported hardware platform — cannot determine DockerHub image"
    elif [[ "$NEPI_IMPORTING" -eq 1 ]]; then
        echo "Image pull already in progress"
    else

        PULL_ID=0
        image_info=$(sudo docker manifest inspect $HUB_IMAGE)
        if [[ $? -ne 0 ]]; then
            echo "Failed to get info for HUB IMAGE: ${HUB_IMAGE}"
        else
            image_sha256="${image_info#*sha256:}"
            PULL_ID="${image_sha256:0:12}"
        fi
        echo "HUB IMAGE ID: ${PULL_ID}"

        start_ids=$(echo $(sudo docker images -q))
        echo "Start IDs: ${start_ids}"
        if [[ ${#PULL_ID} -ne 12 ]]; then
            echo "Failed to get valid id for image ${HUB_IMAGE}"
            success=0
        elif [[ "$start_ids" == *"$PULL_ID"* ]]; then
            echo "Latest NEPI Image allready installed"
            echo $(sudo docker images | grep $PULL_ID)
            success=1
        else

            echo ""
            echo "Updating Docker Config File"

            source $DOCKER_CONFIG_UPDATE_FILE
            if [[ "$?" -eq 1 ]]; then
                echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
            else     
                success=0
                ########################
                # Determine target filesystem slot
                if [[ "$NEPI_AB_FS" -eq 1 ]]; then
                    NEPI_IMPORT_FS=$NEPI_INACTIVE_FS
                else
                    NEPI_IMPORT_FS=nepi_fs_a
                fi

                ########################
                # Build NEPI-format local tag
                NEW_HW_TYPE=$(clean_tag_string $(get_hw_type))
                NEW_DATE=$(date +%Y%m%d-%H%M)
                NEW_HUB_TAG=$(echo "$HUB_IMAGE" | cut -d: -f2)
                NEPI_IMPORT_TAG="nepi-0p0p0-${NEW_HW_TYPE}-${NEW_HUB_TAG}-${NEW_DATE}"
                NEPI_IMPORT_TAG=${NEPI_IMPORT_TAG,,}

                echo ""
                echo "Pulling DockerHub image: ${HUB_IMAGE}"
                echo "Target filesystem slot: ${NEPI_IMPORT_FS}"
                echo "Local tag: ${NEPI_IMPORT_TAG}"

                ##########
                update_yaml_value "NEPI_IMPORTING" 1 "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_FS" $NEPI_IMPORT_FS "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_TAG" $NEPI_IMPORT_TAG "$DOCKER_CONFIG_FILE"

                #########################
                # Check available space
                NEPI_DOCKER=$(sudo docker info --format '{{ .DockerRootDir }}')
                NEPI_DOCKER_SPACE=$(path_space_gb $NEPI_DOCKER)
                echo "Checking avail space in ${NEPI_DOCKER}"


                check_drive=$NEPI_DOCKER
                check_space=20
                if ! is_space_avail_gb $NEPI_DOCKER $check_space; then
                    exist_ids=($(sudo docker images --filter "reference=${NEPI_IMPORT_FS}" --format "{{.ID}}"))
                    if [[ -n "$exist_ids" ]]; then
                        nepistop
                        wait
                        echo "Removing existing images ${NEPI_IMPORT_FS}"
                        for id in "${exist_ids[@]}"; do
                            echo "Removing ${id}"
                            sudo docker rmi -f $id
                        done
                    fi
                fi

                if ! is_space_avail_gb $NEPI_DOCKER $check_space; then
                    echo "Not enough free space in ${NEPI_DOCKER_ROOT} to pull image (need ${check_space} GB)"
                else

                    #Remove stale staging images
                    exist_ids=($(sudo docker images --filter "reference=${HUB_IMAGE}" --format "{{.ID}}"))
                    if [[ -n "${exist_ids[*]}" ]]; then
                        echo "Removing existing staging images"
                        for id in "${exist_ids[@]}"; do
                            sudo docker rmi -f $id
                        done
                    fi

                    echo "Pulling docker image this process can take several minutes..."

                    sudo docker pull $HUB_IMAGE
                    wait
                    
                    success=0
                    
                    PULL_ID=$(sudo docker images --filter "reference=${HUB_IMAGE}" --format "{{.ID}}" | head -1)
                    PULL_ID=${PULL_ID:0:12}
                    echo "Pulled ID: ${PULL_ID}"
                    exist_ids=($(sudo docker images --filter "reference=${HUB_IMAGE}" --format "{{.ID}}"))
                    echo "New IDs: ${exist_ids}"
                    if [[ -n $PULL_ID ]]; then
                        
                        if [[ -n "${exist_ids[*]}" ]]; then
                            echo "Docker pull succeeded with ID: $PULL_ID"
                            success=1
                            echo $NEPI_IMPORT_FS
                            nepistop
                            wait
                            Remove existing images in the target slot
                            
                            exist_ids=($(sudo docker images --filter "reference=${NEPI_IMPORT_FS}" --format "{{.ID}}"))
                            if [[ -n "${exist_ids[*]}" ]]; then
                                echo "Removing existing images for ${NEPI_IMPORT_FS}"
                                for id in "${exist_ids[@]}"; do
                                    sudo docker rmi -f $id
                                    wait
                                done
                            fi

                            # Tag pulled image into the NEPI slot
                            echo "Tagging ${HUB_IMAGE} to ${NEPI_IMPORT_FS}:${NEPI_IMPORT_TAG}"
                            sudo docker tag "${HUB_IMAGE}" "${NEPI_IMPORT_FS}:${NEPI_IMPORT_TAG}"
                            wait
                            sudo docker rmi "${HUB_IMAGE}"
                        fi
                    fi

                    if [[ $success -eq 1 ]]; then
                        echo ""
                        echo "--------------------------"
                        echo "NEPI Image Pull Complete"
                        echo ""
                        dimg
                    else
                        echo ""
                        echo "--------------------------"
                        echo "NEPI Image Pull Failed: ${HUB_IMAGE}"
                    fi
                fi

                update_yaml_value "NEPI_IMPORTING" 0 "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_FS" "unknown" "$DOCKER_CONFIG_FILE"
                update_yaml_value "NEPI_IMPORT_TAG" "unknown" "$DOCKER_CONFIG_FILE"

                ########################
                # Update Docker Config
                echo ""
                echo "Updating Docker Config File"
                bash ${DOCKER_CONFIG_UPDATE_FILE}
                wait
            fi
        fi
    fi

fi
