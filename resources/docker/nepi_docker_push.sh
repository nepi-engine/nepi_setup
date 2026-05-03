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


script_user=$(id -un)
if [[ ${script_user} != 'root' ]]; then
    echo "This script must be run as root. Type 'sudo su' before running this process."
    exit 0
fi

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

        docker_hub_account=''
        if docker info 2> /dev/null; then
            docker_hub_account=$( docker info | grep "Username:" | awk '{print $2}')
        else
            echo "You are not logged into docker hub account. Run 'docker login -u <Account Name>' then try again"
            exit 0
        fi

        if [[ -z $docker_hub_account ]]; then
            "Failed to get valid docker hub account name"
            exit 0
        fi


        echo "Logged into docker hub account ${docker_hub_account}"
        nepiupdate
        source $DOCKER_CONFIG_UPDATE_FILE
        if [[ "$?" -eq 1 ]]; then
            echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
            exit 0
        fi

        if [[ ${NEPI_RUNNING_FS} == 'unknown' ]]; then
            nepistart
            nepiupdate
            source $DOCKER_CONFIG_UPDATE_FILE
            if [[ "$?" -eq 1 ]]; then
                echo "Failed update Docker Config File: ${DOCKER_CONFIG_FILE}"
                exit 0
            fi
        fi


        if [[ ${NEPI_RUNNING_FS} != 'unknown' ]]; then

            ########################
            if is_valid_amd64; then
                if [[ "$NEPI_RUNNING_TAG" == *"cuda"* ]]; then
                        hub_tag="latest-amd64-cuda"
                        platform=linux/amd64
                else
                        hub_tag="latest-amd64"
                        platform=linux/amd64
                fi
            
            elif is_valid_jetson; then
                hub_tag="latest-jetson"
                platform=linux/arm64

            elif is_valid_arm64; then
                hub_tag="latest-arm64"
                platform=linux/arm64
            fi

            got_tag=$1
            if [[ -n $got_tag ]]; then
                hub_tag=$got_tag
            fi

            nepistop
            sudo docker tag ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG} ${docker_hub_account}/nepi:${hub_tag}
            echo "Pushing ${NEPI_RUNNING_FS}:${NEPI_RUNNING_TAG} to docker hub tag ${hub_tag}"
            docker push ${docker_hub_account}/nepi:${hub_tag}
            sudo docker rmi ${docker_hub_account}/nepi:${hub_tag}
            #cd $TMP
            #docker_file=$(pwd)/Dockerfile
            #if [[ -f $docker_file ]]; then sudo rm $docker_file; fi
            #touch $docker_file
            #echo "FROM nepi:${hub_tag}" >> $docker_file
            #docker buildx build --platform  "${platform}" --tag ${docker_hub_account}/nepi:${hub_tag} --push .
            #if [[ -f $docker_file ]]; then sudo rm $docker_file; fi
        else
            echo "No Running NEPI Container to Push"
        fi

fi