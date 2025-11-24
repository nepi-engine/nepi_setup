#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up nepi bash aliases and util functions

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






SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



echo ""
echo "########################"
echo "NEPI FOLDERS SETUP"
echo "########################"
echo ""

ETC_SCRIPTS_FOLDER=$(dirname "${SCRIPT_FOLDER}")/resources/etc/scripts
script_file=check_config_folders.sh
script_path=${ETC_SCRIPTS_FOLDER}/${script_file}
if [[ -f "$script_path" ]]; then
	echo "Running ${script_file} script"
	source $script_path
	wait
fi

echo ""
echo "########################"
echo "NEPI Folders Setup Complete"
echo "########################"
echo ""