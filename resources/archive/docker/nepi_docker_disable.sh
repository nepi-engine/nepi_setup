#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script Stops a Running NEPI Container

CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
wait
echo "NEPI Disable Script"
# Load NEPI SYSTEM CONFIG
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

ETC_FOLDER=${SCRIPT_FOLDER}/etc
if [ ! -d "$ETC_FOLDER" ]; then
    echo "Failed to find ETC folder at ${ETC_FOLDER}"
    exit 1
fi


source ${ETC_FOLDER}/load_system_config.sh
wait
if [ $? -eq 1 ]; then
    echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
    exit 1
fi


########################
# Disable NEPI Docker System
########################
echo "Disabling NEPI DOCKER service: nepi_docker"
sudo systemctl disable nepi_docker

source_ext=org


echo "Updating etc"
target_path=/etc
source_path=${target_path}.${source_ext}
path_sync $source_path $target_path

### Backup USR LIB SYSTEMD USER target_path
echo "Updating /usr/lib/systemd/user"
target_path=/usr/lib/systemd/user
source_path=${target_path}.${source_ext}
path_sync $source_path $target_path

### Backup RUN SYSTEMD target_path
echo "Updating /run/systemd/system"
target_path=/run/systemd/system
source_path=${target_path}.${source_ext}
path_sync $source_path $target_path

### Backup USR LIB SYSTEMD target_path
echo "Updating /usr/lib/systemd/system"
target_path=/usr/lib/systemd/system
source_path=${target_path}.${source_ext}
path_sync $source_path $target_path



# # # Restore BASHRC file
# target_path=${USER}/.bashrc
# source_path=${target_path}.${source_ext}
# path_sync $source_path $target_path

# # Restore docker file
target_path=/etc/docker/daemon.json
source_path=${target_path}.${source_ext}
path_sync $source_path $target_path


echo  "NEPI Disable Complete. Reboot Your Machine"

