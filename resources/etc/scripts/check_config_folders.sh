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

# This script syncs the current folders etc files to the system config folder
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi
if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then
    CONFIG_USER=nepihost
fi

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})



##############################
## NEPI BASE FOLDER

# echo ""
# echo "Checking NEPI Base Folders"
# echo "---------------------------"

NEPI_BASE=/opt/nepi

declare -a rfolders=( 
"${NEPI_BASE}" 
"${NEPI_BASE}/etc" 
"${NEPI_BASE}/scipts" 
"${NEPI_BASE}/docker" 
)


for rfolder in "${rfolders[@]}"; do
    if [[ -n "$rfolder" ]]; then
        if [[ ! -d "$rfolder" ]]; then
            echo "Creating NEPI Folder: ${rfolder}"
            sudo mkdir -p $rfolder
            sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $rfolder
            sudo chmod -R 0775 $rfolder
        fi
    else
        echo "Can't Create Blank Folder"
    fi
done



##############################
## NEPI DOCKER FOLDER

# echo ""
# echo "Checking NEPI Docker Folders"
# echo "---------------------------"

NEPI_DOCKER=/mnt/nepi_docker

if [[ ! -d "${NEPI_DOCKER}" ]]; then
    echo "Creating NEPI Docker: ${NEPI_DOCKER}"
    sudo mkdir -p $NEPI_DOCKER
fi
sudo chown root:root $NEPI_DOCKER


##############################
## NEPI CONFIG FOLDER

# echo ""
# echo "Checking NEPI Config Folders"
# echo "---------------------------"

## NEPI CONFIG FOLDER
NEPI_CONFIG=/mnt/nepi_config

nconfig=${NEPI_CONFIG}
if [ ! -d "${nconfig}" ]; then
    echo "Creating NEPI Folder: ${nconfig}"
    sudo mkdir "${nconfig}"
fi
echo "Emptying Trash for NEPI Folder: ${nfolder}"
sudo rm -r ${nfolder}/.Trash*
sudo chown ${CONFIG_USER}:${CONFIG_USER} $nconfig


dconfig=${NEPI_CONFIG}/docker_cfg
if [ ! -d "${dconfig}" ]; then
    echo "Creating NEPI Folder: ${dconfig}"
    sudo mkdir -p "${dconfig}"
fi

fconfig=${NEPI_CONFIG}/factory_cfg
if [ ! -d "${fconfig}/etc" ]; then
    echo "Creating NEPI Folder: ${fconfig}/etc"
    sudo mkdir -p "${fconfig}/etc"
fi

sfolder=${NEPI_CONFIG}/system_cfg
if [ ! -d "${sfolder}/etc" ]; then
    echo "Creating NEPI Folder: ${sfolder}/etc"
    sudo mkdir -p "${sfolder}/etc"
fi



sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $NEPI_CONFIG
sudo chmod -R 0755 $NEPI_CONFIG


if [[ "$NEPI_CONFIG" != "/mnt/nepi_config" && ! -d "$NEPI_CONFIG" ]]; then
    echo "Creating NEPI Shared Config folder: /mnt/nepi_config"
    sudo mkdir -p "/mnt/nepi_config"
    echo "Creating NEPI Config Folder links in Shared Config folder"
    sudo ln -sf $dconfig "/mnt/nepi_config/docker_cfg"
    sudo ln -sf $fconfig "/mnt/nepi_config/factory_cfg"
    sudo ln -sf $sconfig "/mnt/nepi_config/system_cfg"

    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /mnt/nepi_config
    sudo chmod -R 0775 /mnt/nepi_config
fi

##############################
## NEPI STORAGE FOLDER

# echo ""
# echo "Checking NEPI Storage Folders"
# echo "---------------------------"

NEPI_STORAGE=/mnt/nepi_storage

nfolder=${NEPI_STORAGE}
if [ ! -d "${nfolder}" ]; then
    echo "Creating NEPI Folder: ${nfolder}"
    sudo mkdir "${nfolder}"
fi
echo "Emptying Trash for NEPI Folder: ${nfolder}"
sudo rm -r ${nfolder}/.Trash*
sudo chown ${CONFIG_USER}:${CONFIG_USER} $nfolder
sudo chmod 0755 $nfolder

declare -a rfolders=(  
"${NEPI_STORAGE}/ai_models" 
"${NEPI_STORAGE}/ai_training" 
"${NEPI_STORAGE}/data" 
"${NEPI_STORAGE}/install" 
"${NEPI_STORAGE}/logs"  
"${NEPI_STORAGE}/nepi_src" 
"${NEPI_STORAGE}/tmp"
"${NEPI_STORAGE}/automation_scripts"  
"${NEPI_STORAGE}/databases"  
"${NEPI_STORAGE}/license" 
"${NEPI_STORAGE}/nepi_images" 
"${NEPI_STORAGE}/sample_data" 
"${NEPI_STORAGE}/user_cfg" 
)


for rfolder in "${rfolders[@]}"; do
    if [[ -n "$rfolder" ]]; then
        if [[ ! -d "$rfolder" ]]; then
            echo "Creating NEPI Folder: ${rfolder}"
            sudo mkdir -p $rfolder
            sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $rfolder
            sudo chmod -R 0775 $rfolder
        fi
    else
        echo "Can't Create Blank Folder"
    fi
done

###################
NEPI_OPT=/opt/nepi

nconfig=${NEPI_OPT}
if [ ! -d "${nconfig}" ]; then
    echo "Creating NEPI Folder: ${nconfig}"
    sudo mkdir "${nconfig}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $nconfig

nconfig=${NEPI_OPT}/etc
if [ ! -d "${nconfig}" ]; then
    echo "Creating NEPI Folder: ${nconfig}"
    sudo mkdir "${nconfig}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $nconfig

nconfig=${NEPI_OPT}/docker
if [ ! -d "${nconfig}" ]; then
    echo "Creating NEPI Folder: ${nconfig}"
    sudo mkdir "${nconfig}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $nconfig
    

nconfig=${NEPI_OPT}/bash
if [ ! -d "${nconfig}" ]; then
    echo "Creating NEPI Folder: ${nconfig}"
    sudo mkdir "${nconfig}"
fi
sudo chown ${CONFIG_USER}:${CONFIG_USER} $nconfig