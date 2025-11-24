#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file configures a NEPI Docker installation environment


if [[ -z "$1" ]]; then
    DEMO_INSTALL=0
else
    DEMO_INSTALL=$1
fi

export CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    export CONFIG_USER=$SUDO_USER
fi

if [[ "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepihost'"
    exit 1
fi

sudo -v


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
