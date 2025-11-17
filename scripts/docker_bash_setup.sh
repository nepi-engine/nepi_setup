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

export CONFIG_USER=${USER}


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)



####################################
# Run NEPI Bash Setup Script


script_file=nepi_bash_setup.sh
script_path=${SCRIPT_FOLDER}/${script_file}
source $script_path
