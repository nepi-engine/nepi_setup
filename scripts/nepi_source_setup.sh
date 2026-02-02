#! /bin/bash

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

# This file installs nepi engine workspace repo

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

if [[ "$CONFIG_USER" != 'nepi' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi'"
    return 
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

echo "########################"
echo "NEPI SOURCE CODE SETUP"
echo "########################"

echo "Running Intitialization Scripts"



###############################

SOURCE_FOLDER=${NEPI_SOURCE}/nepi_engine_ws
if [ ! -f "${SOURCE_FOLDER}" ]; then

    if [ !-v NEPI_BRANCH ]; then
        echo ""
        echo ""
        echo "Select NEPI Source Code Banch to Install:"
        select branch in 'dain' 'develop'; do
            case $branch in
                main ) break;;
                develop ) break;;
            esac
            NEPI_BRANCH=${branch}
        done
    fi

    echo "Installing NEPI Branch: ${NEPI_BRANCH} at ${SOURCE_FOLDER}"
    if [ ! -d "${NEPI_SOURCE}" ]; then
    sudo mkdir $NEPI_SOURCE
    sudo chmod -R ${USER}:${USER} $NEPI_SOURCE
    fi
    if [ -d "${NEPI_SOURCE}" ]; then
        if [ -f "${SOURCE_FOLDER}" ]; then
            echo "NEPI Source Folder Exists: ${SOURCE_FOLDER}. Delete and try again"
        else
            cd ${NEPI_SOURCE}
            git clone git@github.com:nepi-engine/nepi_engine_ws.git
            cd nepi_engine_ws
            if [[ "$NEPI_BRANCH" == "main" ]]; then
                BRANCH=main
                if [[ "$NEPI_ROS" == "NOETIC" ]]; then
                BRANCH=ros1_develop
                else
                BRANCH=ros2_develop
                fi
            fi
            if [[ "$NEPI_ROS" == "NOETIC" ]]; then
                SUBBRANCH=ros1_main
            else
                SUBBRANCH=ros2_main
            fi
            # Now Clone
            git clone git@github.com:nepi-engine/nepi_engine_ws.git
            cd nepi_engine_ws
            git checkout $BRANCH
            git submodule update --init --recursive
            git submodule foreach git checkout $SUBBRANCH
            git submodule foreach git pull origin $SUBBRANCH
            cd src
            for dir in /*/; do
            if [ -d "$dir" ]; then # Checks if the item is a directory
                cd $dir
                if [ -f ".gitmodules" ]; then
                git submodule update --init --recursive
                git submodule foreach git checkout $SUBBRANCH
                git submodule foreach git pull origin $SUBBRANCH
                fi
            fi
            fi
        fi
    else
        echo "Failed to create source code folder at: ${NEPI_SOURCE}"
    fi

else
    echo "NEPI Source Folder Exists: ${SOURCE_FOLDER}"
fi