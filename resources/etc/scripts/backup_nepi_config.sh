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

# This script creates a backup of the NEPI Host's original system configuration
sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    id -nu 1000
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


