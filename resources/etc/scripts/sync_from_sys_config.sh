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

# This script syncs the factory and system config folders to the current etc folder
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
## Check Folders
load_nepi_config=0
. ${ETC_SCRIPTS_FOLDER}/check_config_folders.sh $load_nepi_config

##############################
## Sync from Config Folders

# Sync from system
source_config_path=/mnt/nepi_config/system_cfg
sync_to_config_folder $source_config_path 'nepi_cfg' 


