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

source /home/${USER}/.org_bash_utils
wait


########################
# Update system folders
source_ext=org

target_path=/etc
source_path=${target_path}.${repace_ext}
path_sync $source_path $target_pat

### Backup USR LIB SYSTEMD target_path
target_path=/usr/lib/systemd/system
source_path=${target_path}.${repace_ext}
path_sync $source_path $target_pat

### Backup RUN SYSTEMD target_path
target_path=/run/systemd/system
source_path=${target_path}.${repace_ext}
path_sync $source_path $target_pat

### Backup USR LIB SYSTEMD USER target_path
target_path=/usr/lib/systemd/user
source_path=${target_path}.${repace_ext}
path_sync $source_path $target_pat


# # Restore BASHRC file
# target_path=/home/${USER}/.bashrc.org
target_path=${USER}/.bashrc
source_path=${target_path}.${repace_ext}
path_sync $source_path $target_pat

# echo  "NEPI Disable Complete. Reboot Your Machine"
