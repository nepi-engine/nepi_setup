#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This DOCKER_CONFIG_FILE is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This script loads the nepi_docker_config.yaml values

DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml

if [[ -f "$DOCKER_CONFIG_FILE" ]]; then
    #echo "Updating Docker Config DOCKER_CONFIG_FILE from: ${DOCKER_CONFIG_FILE}"
    keys=($(yq e 'keys | .[]' ${DOCKER_CONFIG_FILE}))
    for key in "${keys[@]}"; do
        value=$(yq e '.'"$key"'' $DOCKER_CONFIG_FILE)
        export ${key}=$value
    done
else
    echo "Config DOCKER_CONFIG_FILE not found ${DOCKER_CONFIG_FILE}"
    exit 1
fi

