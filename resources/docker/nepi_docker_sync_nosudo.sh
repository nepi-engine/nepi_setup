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

# This script syncs to NEPI Docker files and folders 
# First from /opt/nepi to /mnt/nepi_config
# Then back from /mnt/nepi_config to /opt/nepi


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



################## 
# Fix Folder Owners
echo "Fixing NEPI Foder Owners to Config User: ${CONFIG_USER}"
chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
chmod 0775 /opt/nepi
chown 1000:1000 /mnt/nepi_config
chmod 0750 /mnt/nepi_config
chown 1000:1000 /mnt/nepi_storage
chmod 0750 /mnt/nepi_storage





#############################
echo ""
echo "Updating System Files and Folders"

#############################
# Sync System Config ETC Files and Folders

# Sync from /mnt/nepi_config/system_cfg/etc first

SOURCE_PATH=/mnt/nepi_config/system_cfg/etc 
UPDATE_PATH=/opt/nepi/etc
CONFIG_FILENAME=nepi_system_config.yaml

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}


echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -f $SOURCE_FILE ]]; then
    cp $UPDATE_FILE $SOURCE_FILE 
fi

sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
rsync -ar --exclude=${CONFIG_FILENAME} ${SOURCE_PATH}/ ${UPDATE_PATH}/

echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}" 
rsync -ar ${UPDATE_PATH}/ ${SOURCE_PATH}/


chown 1000:1000 ${SOURCE_PATH}
chmod 775 ${SOURCE_PATH}

chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
chmod 775 ${UPDATE_PATH}



#############################
# Sync Docker Config folders

# Synce from /opt/nepi first

SOURCE_PATH=/opt/nepi/docker_cfg
UPDATE_PATH=/mnt/nepi_config/docker_cfg
CONFIG_FILENAME=nepi_docker_config.yaml

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}


echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ ! -f $SOURCE_FILE ]]; then
    cp $UPDATE_FILE $SOURCE_FILE 
fi

sync_yaml_files $SOURCE_FILE $UPDATE_PATH 

rsync -ar --exclude=${CONFIG_FILENAME} --exclude=${CONFIG_FILENAME}.bak ${SOURCE_PATH}/ ${UPDATE_PATH}/

echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"
rsync -ar ${UPDATE_PATH}/ ${SOURCE_PATH}/

chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
chmod 775 ${SOURCE_PATH}

chown 1000:1000 ${UPDATE_PATH}
chmod 775 ${UPDATE_PATH}



# ######################################
# ## Sync License Files

# SOURCE_PATH=/mnt/nepi_storage/license
# UPDATE_PATH=/opt/nepi/license

# echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
# if [[ -d "${SOURCE_PATH}" ]]; then
#     rsync -arh --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
# fi

# echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"
# if [[ -d "${UPDATE_PATH}" ]]; then
#     rsync -arh --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
# fi


# chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
# chmod 775 ${SOURCE_PATH}

# chown 1000:1000 ${UPDATE_PATH}
# chmod 775 ${UPDATE_PATH}


######################################
## Sync Bash Files

SOURCE_PATH=/home/${CONFIG_USER} 
UPDATE_PATH=/opt/nepi/bash/${CONFIG_USER}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then
    rsync -arh --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
fi

echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"
if [[ -d "${UPDATE_PATH}" ]]; then
    rsync -arh --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
fi


chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
chmod 755 ${SOURCE_PATH}

chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
chmod 755 ${UPDATE_PATH}




################## 
# Fix Folder Owners
chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
chmod 0775 /opt/nepi
chown 1000:1000 /mnt/nepi_config
chmod 0775 /mnt/nepi_config
chown 1000:1000 /mnt/nepi_storage
chmod 0775 /mnt/nepi_storage