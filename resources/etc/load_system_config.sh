#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This script loads the nepi_system_config.yaml values

CONFIG_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
 
CONFIG_FILE=${CONFIG_FOLDER}/nepi_system_config.yaml



if [[ -f "$CONFIG_FILE" ]]; then

    success=0
    eval $(python ${CONFIG_FOLDER}/load_system_config.py 2>/dev/null)

    if [[ "$success" -eq 0 ]]; then
        #sudo echo "Updating NEPI Config file from: ${CONFIG_FILE}"
        keys=($(yq e 'keys | .[]' ${CONFIG_FILE}))
        for key in "${keys[@]}"; do
            value=$(yq e '.'"$key"'' $CONFIG_FILE)
            export ${key}=$value
        done
    fi

else
    echo "Config file not found ${CONFIG_FILE}"
    exit 1
fi
