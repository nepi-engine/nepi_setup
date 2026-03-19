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

# This script Commits a Running NEPI Container
sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
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

    # Get the current year
    current_year=$(date +%Y)

    # Define the year for comparison
    target_year=2024

    # Compare the years
    date_updated=0
    if (( current_year < target_year )); then
        echo "Your Devices Clock must be updated before commiting,  Sync clock and try again"
    else

        # Create Tag
        if [[ $NEPI_RUNNING_ID != 0 && "$NEPI_RUNNING" -eq 1 ]]; then
            COMMIT_NAME=$NEPI_RUNNING_FS
            echo "$NEPI_RUNNING_FS"
            echo "$NEPI_FSA_TAG"

            IFS='-' read -ra TAG_ARRAY <<< "$NEPI_FSA_TAG"

            # COMMIT_NAME="${TAG_ARRAY[0]}"
            COMMIT_NAME="nepi_fs_a"
            echo $COMMIT_NAME
            if [[ -z "$COMMIT_NAME" ]]; then
                COMMIT_NAME="unknown"
            fi

            COMMIT_VERSION="${TAG_ARRAY[1]}"
            if [[ -z "$COMMIT_VERSION" ]]; then
                COMMIT_VERSION="XpXpX"
            fi

            COMMIT_HW_TYPE="${TAG_ARRAY[2]}"
            if [[ -z "$COMMIT_HW_TYPE" ]]; then
                COMMIT_HW_TYPE="unknown"
            fi

            COMMIT_SW_DESC="${TAG_ARRAY[3]}"
            if [[ -z "$COMMIT_SW_DESC" ]]; then
                COMMIT_SW_DESC="unknown"
            fi
            
            COMMIT_DATE=$(date +%Y%m%d)

            COMMIT_DESC=$1
            if [[ -z "$COMMIT_DESC" ]]; then
                if [[ -n $TAG_ARRAY[5] ]]; then
                    COMMIT_DESC="-${TAG_ARRAY[5]}"
                fi
            fi
            if [[ ${COMMIT_DESC} == '-' ]];
                COMMIT_DESC=''
            fi

            COMMIT_TAG="nepi-${COMMIT_VERSION}-${COMMIT_HW_TYPE}-${COMMIT_SW_DESC}-${COMMIT_DATE}${COMMIT_DESC}"
            COMMIT_NAME_TAG="${COMMIT_NAME}:${COMMIT_TAG}"

            if [[ -n "$COMMIT_NAME" && -n "$COMMIT_TAG" && -n "$COMMIT_NAME_TAG" ]]; then
                echo "Commiting running nepi container to Name:Tag - ${COMMIT_NAME_TAG}"
                sudo docker commit $NEPI_RUNNING_ID $COMMIT_NAME_TAG
                wait

                COMMIT_ID=$(sudo docker images -q $COMMIT_NAME_TAG)
                echo "Commited running nepi container to ID - ${COMMIT_ID}"
                if [[ "$NEPI_RUNNING_FS" == 'nepi_fs_a' && -n "$COMMIT_ID" ]]; then
                    echo "Updating ${NEPI_RUNNING_FS} to ${COMMIT_TAG} in ${DOCKER_CONFIG_FILE}"
                    echo "Updating ${NEPI_RUNNING_FS} to ${COMMIT_ID} in ${DOCKER_CONFIG_FILE}"
                    update_yaml_value "NEPI_FSA_TAG" ${COMMIT_TAG} "${DOCKER_CONFIG_FILE}"
                    update_yaml_value "NEPI_FSA_ID" ${COMMIT_ID} "${DOCKER_CONFIG_FILE}"
                elif [[ "$NEPI_RUNNING_FS" == 'nepi_fs_b' && -n "$COMMIT_ID" ]]; then
                    echo "Updating ${NEPI_RUNNING_FS} to ${COMMIT_TAG} in ${DOCKER_CONFIG_FILE}"
                    echo "Updating ${NEPI_RUNNING_FS} to ${COMMIT_ID} in ${DOCKER_CONFIG_FILE}"
                    update_yaml_value "NEPI_FSB_TAG" ${COMMIT_TAG} "${DOCKER_CONFIG_FILE}"
                    update_yaml_value "NEPI_FSB_ID" ${COMMIT_ID} "${DOCKER_CONFIG_FILE}"
                fi

                echo ""
                echo "Updating Docker Config File"
                bash ${DOCKER_FOLDER}/nepi_docker_update.sh
                wait

            else
                echo "Can't Commit Containter with Name: ${COMMIT_NAME} and Tag:  ${COMMIT_TAG}.  One or both are empty"
            fi
        else
            echo "No Running NEPI Container to Commit"
        fi
    fi

fi