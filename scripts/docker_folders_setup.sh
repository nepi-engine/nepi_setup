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

sudo -v
export CONFIG_USER=nepihost


# if [[ "$USER" != "$CONFIG_USER" ]]; then
#     echo "This script must be run by user account ${CONFIG_USER}."
#     echo "Log in as ${CONFIG_USER} and run again"
#     exit 1
# fi



SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)



####################################
# Run NEPI Bash Setup Script


script_file=nepi_folders_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo ""
	echo "Running ${script_file} script"
	source $script_path
	wait
else
    echo "Setup script not found ${script_file}"
    exit 1
fi
