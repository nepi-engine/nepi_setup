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

LOAD_SCRIPT=${CONFIG_FOLDER}/load_docker_config.py




if [[ -f "$LOAD_SCRIPT" ]]; then


    success=0
    eval_cmd="load_vals=$(python3 $LOAD_SCRIPT )"  #2>/dev/null"
    eval "$eval_cmd"
    #echo "${load_vals}"
    
    for entry in $load_vals; do
        export ${entry}
    done

    if [[ "$success" -ne 1 ]]; then
        echo "Success = ${success}"
        exit 1
    fi


else
    echo "Load script not found ${LOAD_SCRIPT}"
    exit 1
fi
