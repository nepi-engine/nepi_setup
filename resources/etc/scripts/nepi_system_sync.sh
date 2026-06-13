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


# This script syncs the /opt/nepi folders with system wide folders

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


ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


################## 
# Fix Folder Owners
echo "Fixing NEPI Foder Owners to Config User: ${CONFIG_USER}"
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
sudo chmod 0775 /opt/nepi
sudo chown 1000:1000 /mnt/nepi_config
sudo chmod 0750 /mnt/nepi_config
sudo chown 1000:1000 /mnt/nepi_storage
sudo chmod 0750 /mnt/nepi_storage





#############################
echo ""
echo "Updating System Files and Folders"

#############################
# Sync System Config ETC Files and Folders

SOURCE_PATH=/mnt/nepi_config/system_cfg/etc 
UPDATE_PATH=/opt/nepi/etc
CONFIG_FILENAME=nepi_system_config.yaml

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}

# sudo sed -i "/NEPI_IP/d" "$SOURCE_FILE" >/dev/null 2>&1
# sudo sed -i "/NEPI_IP/d" "${SOURCE_FILE}.bak" >/dev/null 2>&1

# sudo sed -i "/NEPI_IP/d" "$UPDATE_FILE" >/dev/null 2>&1
# sudo sed -i "/NEPI_IP/d" "${UPDATE_FILE}.bak" >/dev/null 2>&1


echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"

if [[ ! -f $SOURCE_FILE ]]; then
    sudo cp $UPDATE_FILE $SOURCE_FILE 
fi

sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/

# echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"
  
# sudo rsync -ar ${UPDATE_PATH}/ ${SOURCE_PATH}/

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown 1000:1000 ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}



#############################
# Sync Docker Config folders

# Synce from /mnt/nepi_config/docker_cfg first

SOURCE_PATH=/mnt/nepi_config/docker_cfg
UPDATE_PATH=/opt/nepi/docker_cfg
CONFIG_FILENAME=nepi_docker_config.yaml

SOURCE_FILE=${SOURCE_PATH}/${CONFIG_FILENAME}
UPDATE_FILE=${UPDATE_PATH}/${CONFIG_FILENAME}


if [[ ! -f $UPDATE_FILE ]]; then
    echo "Copying from ${SOURCE_FILE} to ${UPDATE_FILE}"
    sudo cp $SOURCE_FILE $UPDATE_FILE 
fi

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
sync_yaml_files $UPDATE_FILE $SOURCE_FILE 
sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/

echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"

sudo rsync -ar ${UPDATE_PATH}/ ${SOURCE_PATH}/

sudo chown 1000:1000 ${SOURCE_PATH}
sudo chmod 775 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 775 ${UPDATE_PATH}



# ######################################
# ## Sync License Files

# SOURCE_PATH=/mnt/nepi_storage/license
# UPDATE_PATH=/opt/nepi/license

# echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
# if [[ -d "${SOURCE_PATH}" ]]; then
#     sudo rsync -arh --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
# fi

# echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"
# if [[ -d "${UPDATE_PATH}" ]]; then
#     sudo rsync -arh --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
# fi


# sudo chown 1000:1000 ${SOURCE_PATH}
# sudo chmod 775 ${SOURCE_PATH}

# sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
# sudo chmod 775 ${UPDATE_PATH}


######################################
## Sync Bash Files

SOURCE_PATH=/home/${CONFIG_USER} 
UPDATE_PATH=/opt/nepi/bash/${CONFIG_USER}

echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
if [[ -d "${SOURCE_PATH}" ]]; then
    sudo rsync -arh --exclude='*/' ${SOURCE_PATH}/ ${UPDATE_PATH}/
fi

echo "Syncing files from ${UPDATE_PATH} to ${SOURCE_PATH}"
if [[ -d "${UPDATE_PATH}" ]]; then
    sudo rsync -arh --exclude='*/' ${UPDATE_PATH}/ ${SOURCE_PATH}/
fi


sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
sudo chmod 755 ${SOURCE_PATH}

sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
sudo chmod 755 ${UPDATE_PATH}




################## 
# Fix Folder Owners
sudo chown ${CONFIG_USER}:${CONFIG_USER} /opt/nepi
sudo chmod 0775 /opt/nepi
sudo chown 1000:1000 /mnt/nepi_config
sudo chmod 0775 /mnt/nepi_config
sudo chown 1000:1000 /mnt/nepi_storage
sudo chmod 0775 /mnt/nepi_storage