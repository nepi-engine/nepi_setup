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

if [[ -f "/home/nepi/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepi

elif [[ -f "/home/nepihost/.nepi_bash_utils" ]]; then
    CONFIG_USER=nepihost
else
    echo ".nepi_bash_utils file not found"
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


