#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file loads the nepi_system_config.yaml values

# Load System Config File
CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

# Load NEPI DOCKER CONFIG
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

FILE=${SCRIPT_FOLDER}/nepi_docker_config.yaml
 
if [[ -f "$FILE" ]]; then
    #echo "Updating Docker Config file from: ${FILE}"
    keys=($(yq e 'keys | .[]' ${FILE}))
    for key in "${keys[@]}"; do
        value=$(yq e '.'"$key"'' $FILE)
        export ${key}=$value
    done
else
    echo "Config file not found ${FILE}"
    exit 1
fi

