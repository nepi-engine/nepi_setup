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


# This file configures a NEPI Docker installation environment


if [[ -v "$1" ]]; then
    DEMO_INSTALL=$1
else
    DEMO_INSTALL=0
fi

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepihost'"
    exit 1
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



####################################
# Run NEPI Bash Setup Script


script_file=nepi_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi
