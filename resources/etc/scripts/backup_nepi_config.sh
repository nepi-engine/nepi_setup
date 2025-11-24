#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script creates a backup of the NEPI Host's original system configuration
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

back_ext=nepi
overwrite=1

### Backup ETC folder
folder=/etc
folder_back=${folder}.${back_ext}
path_backup $folder $folder_back $overwrite

### Backup USR LIB SYSTEMD folder
folder=/usr/lib/systemd/system
folder_back=${folder}.${back_ext}
path_backup $folder $folder_back $overwrite

### Backup RUN SYSTEMD folder
folder=/run/systemd/system
folder_back=${folder}.${back_ext}
path_backup $folder $folder_back $overwrite

### Backup USR LIB SYSTEMD USER folder
folder=/usr/lib/systemd/user
folder_back=${folder}.${back_ext}
path_backup $folder $folder_back $overwrite


