#!/bin/bash
##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi

if [[ "$CONFIG_USER" != 'nepi' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi'"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

echo "########################"
echo "NEPI ENGINE CLEAR"
echo "########################"

echo "Running Intitialization Scripts"



# This script deletes all nepi folders/files in the nepi system
cd /opt/nepi/nepi_engine
sudo find . -type d -name 'nepi_*' -exec rm -rf {} +
sudo chown -R nepi:nepi ./*
# Run Nepi deploy and build complete scripts to rebuild system

