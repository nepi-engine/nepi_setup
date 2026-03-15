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

# This file imports an image from a tar file to the inactive fs
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
    SW_DESC=$1

    if [[ "$NEPI_IMPORTING" -eq 1 ]]; then
        echo "Image import in progress"
    elif [[ -z "$SW_DESC" ]]; then
        echo "No Software Desciption Provided"

    else
        ########################
        echo "Proceeding with the retag..."

            if [[ "$NEPI_ACTIVE_FS" == 'nepi_fs_a' ]]; then
                NEPI_ACTIVE_TAG=$NEPI_FSA_TAG
            else
                NEPI_ACTIVE_TAG=$NEPI_FSB_TAG
            fi

            NEPI_RE_TAG=$NEPI_ACTIVE_TAG
 

            if [[ "${NEPI_RE_TAG:0:4}" == 'nepi' ]]; then # NEPI Produced Image



                IFS='-' read -ra TAG_ARRAY <<< "$NEPI_RE_TAG"
                

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


                NEW_SW_DESC=$(clean_tag_string $SW_DESC)

                NEW_DATE=$(clean_tag_string "${TAG_ARRAY[3]}")
                if [[ -z "$NEW_DATE" ]]; then
                    NEW_DATE=$(date +%Y%m%d-%H%M)
                fi          
        
        
                NEPI_RE_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}"

            else # Non NEPI Produced Image
                
                NEW_NAME=nepi
                NEW_VERSION="0p0p0"
                NEW_HW_TYPE=$(clean_tag_string $(get_hw_type))

                NEW_SW_DESC=$(clean_tag_string $SW_DESC)

                NEW_DATE=$(date +%Y%m%d-%H%M)        

                NEPI_RE_TAG="${NEW_NAME}-${NEW_VERSION}-${NEW_HW_TYPE}-${NEW_SW_DESC}-${NEW_DATE}"

            fi


            # NEW_DESC="${TAG_ARRAY[5]}"
            # if [[ -n "$NEW_DESC" ]]; then
            #     NEPI_RE_TAG="${NEPI_RE_TAG}-${NEW_DESC}"
            # fi
        
            

            NEPI_RE_TAG=${NEPI_RE_TAG,,}


            echo "Renaming active tag from ${NEPI_ACTIVE_FS}:${NEPI_ACTIVE_TAG} to ${NEPI_ACTIVE_FS}:${NEPI_RE_TAG}"
            exit 1
            sudo docker tag "${NEPI_ACTIVE_FS}:${NEPI_ACTIVE_TAG}" "${NEPI_IMPORT_FS}:${NEPI_RE_TAG}" 
            wait
            echo "Removing old image tag"
            sudo docker rmi "${NEPI_ACTIVE_FS}:${NEPI_ACTIVE_TAG}"

            #############
            echo ""
            echo "--------------------------"
            echo "NEPI Re Tag Complete"
            echo ""
            dimg


            ########################
            # Update Docker Config
            echo ""
            echo "Updating Docker Config File"
            bash ${DOCKER_FOLDER}/nepi_docker_update.sh
            wait

        else
            echo "Got Empty Re Tag String"
        fi
    fi
    
fi
