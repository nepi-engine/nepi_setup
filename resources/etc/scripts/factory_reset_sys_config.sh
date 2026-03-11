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
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

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


###########################
## Factory Reset System Config
SOURCE_PATH=/mnt/nepi_config/factory_cfg
UPDATE_PATH=/mnt/nepi_config/system_cfg
echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then

    sudo rsync -arh --delete ${SOURCE_PATH}/ ${UPDATE_PATH}/

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 755 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 755 ${UPDATE_PATH}
else
    echo "No Factory Config found at: ${SOURCE_PATH}"
fi

