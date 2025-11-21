#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script Commits a Running NEPI Container
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

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

    # Create Tag
    if [[ $NEPI_RUNNING_ID != 0 && "$NEPI_RUNNING" -eq 1 ]]; then
        COMMIT_NAME=$NEPI_RUNNING_FS

        IFS='-' read -ra TAG_ARRAY <<< "$NEPI_RUNNING_TAG"

        COMMIT_VERSION=$NEPI_VERSION
        if [[ -z "$COMMIT_VERSION" ]]; then
            COMMIT_VERSION="${TAG_ARRAY[1]}"
            if [[ -z "$COMMIT_VERSION" ]]; then
                COMMIT_VERSION="unknown"
            fi
        fi
        COMMIT_VERSION=$(clean_tag_string $COMMIT_VERSION)

        COMMIT_HW_TYPE=$NEPI_HW_TYPE
        if [[ -z "$COMMIT_HW_TYPE" || "$COMMIT_HW_TYPE" == 'unknown' ]]; then
            COMMIT_HW_TYPE="${TAG_ARRAY[2]}"
            if [[ -z "$COMMIT_HW_TYPE" ]]; then
                COMMIT_HW_TYPE="unknown"
            fi
        fi
        COMMIT_HW_TYPE=$(clean_tag_string $COMMIT_HW_TYPE)

        COMMIT_SW_DESC=$NEPI_SW_DESC
        if [[ -z "$COMMIT_SW_DESC" || "$COMMIT_SW_DESC" == 'unknown' ]]; then
            COMMIT_SW_DESC="${TAG_ARRAY[3]}"
            if [[ -z "$COMMIT_SW_DESC" ]]; then
                COMMIT_SW_DESC="unknown"
            fi
        fi
        COMMIT_SW_DESC=$(clean_tag_string $COMMIT_SW_DESC)

        COMMIT_DATE=$(date +%Y%m%d)

        COMMIT_DESC=$1
        if [[ -z "$COMMIT_DESC" ]]; then
            COMMIT_DESC=${TAG_ARRAY[5]}
        fi
       

        if [[ -z "$COMMIT_DESC" || "$COMMIT_SW_DESC" == 'unknown' || "$COMMIT_SW_DESC" == 'clean' ]]; then
            COMMIT_DESC="$(date +%H%M)"
        elif [[ "$COMMIT_DESC" =~ _[0-9]{4}$ ]]; then
            COMMIT_DESC=${COMMIT_DESC%?????}
            COMMIT_DESC="${COMMIT_DESC}_$(date +%H%M)"
        else
            COMMIT_DESC="${COMMIT_DESC}_$(date +%H%M)"
        fi
        COMMIT_DESC=$(clean_tag_string $COMMIT_DESC)
        if [[ -n "$COMMIT_DESC" ]]; then
            COMMIT_DESC="-${COMMIT_DESC}"
        fi

        COMMIT_TAG="nepi-${COMMIT_VERSION}-${COMMIT_HW_TYPE}-${COMMIT_SW_DESC}-${COMMIT_DATE}"${COMMIT_DESC}




        COMMIT_TAG=${COMMIT_TAG,,}
        COMMIT_NAME_TAG="${COMMIT_NAME}:${COMMIT_TAG}"
        if [[ -n "$COMMIT_NAME" && -n "$COMMIT_TAG" && -n "$COMMIT_NAME_TAG" ]]; then
            COMMIT_NAME_TAG="${COMMIT_NAME}:${COMMIT_TAG}"
            echo "Commiting running nepi container to Name:Tag - ${COMMIT_NAME_TAG}"

            sudo docker commit $NEPI_RUNNING_ID $COMMIT_NAME_TAG
            wait
            COMMIT_ID=$(sudo docker images -q $COMMIT_NAME_TAG)
            echo "Commited running nepi container to ID - ${COMMIT_ID}"
            if [[ "$NEPI_RUNNING_FS" == 'nepi_fs_a' && -n "$COMMIT_ID" ]]; then
                update_yaml_value "NEPI_FSA_TAG" ${COMMIT_TAG} "${DOCKER_CONFIG_FILE}"
                update_yaml_value "NEPI_FSA_ID" ${COMMIT_ID} "${DOCKER_CONFIG_FILE}"
            elif [[ "$NEPI_RUNNING_FS" == 'nepi_fs_b' && -n "$COMMIT_ID" ]]; then
                update_yaml_value "NEPI_FSB_TAG" ${COMMIT_TAG} "${DOCKER_CONFIG_FILE}"
                update_yaml_value "NEPI_FSB_ID" ${COMMIT_ID} "${DOCKER_CONFIG_FILE}"
            fi


            ########################
            # Update Docker Config
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
