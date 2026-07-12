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
## Redistributions in source code must retain this top-level comment block,
## Along with any License Check related code and checks.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##


# Updates the NEPI docker management scripts on a provisioned device from this
# nepi_setup checkout. Unlike docker_files_setup.sh, this script is safe to
# re-run on a working system: it never touches the live nepi_docker_config.yaml
# (or any other yaml state files) and never deletes files it does not own.
#
# The running nepi_docker.service keeps executing the previously loaded script,
# so updates take effect after: sudo systemctl restart nepi_docker
# (note this restarts the NEPI container).

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
USER_CHECK_FILE=${SCRIPT_FOLDER}/nepi_user_check.sh
source $USER_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

RSYNC_EXCLUDES="--exclude nepi_docker_config.yaml --exclude *.blank --exclude *.bak"

#############################
echo ""
echo "Updating Docker Management Scripts"
SOURCE_PATH=${RESOURCES_FOLDER}/docker

for UPDATE_PATH in /opt/nepi/docker_cfg /mnt/nepi_config/docker_cfg; do

    if [[ ! -d $UPDATE_PATH ]]; then
        echo "Skipping missing folder ${UPDATE_PATH}"
        continue
    fi

    echo "Syncing docker scripts from ${SOURCE_PATH} to ${UPDATE_PATH}"
    sudo rsync -ar ${RSYNC_EXCLUDES} ${SOURCE_PATH}/ ${UPDATE_PATH}/

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 775 ${UPDATE_PATH}

done

echo ""
echo "Docker management scripts updated."
echo "Run 'sudo systemctl restart nepi_docker' to activate them (this restarts the NEPI container)."
