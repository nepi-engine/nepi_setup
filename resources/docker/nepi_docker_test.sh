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
## Redistributions in source code must retain this top-level comment block.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##

sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi
export CONFIG_USER=$CONFIG_USER

bfile=/home/${CONFIG_USER}/.bashrc
ufile=/home/${CONFIG_USER}/.nepi_bash_utils
afile=/home/${CONFIG_USER}/.nepi_docker_aliases

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


export NEPI_ACTIVE_FS=nepi_fs_a
export NEPI_FSA_TAG=nepi-3p2p0_rc6c-20251115-0543-jetson-ubuntu20p04_cuda11p4-20251115-dev1_0552


DOCKER_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
DOCKER_CONFIG_FILE=${DOCKER_FOLDER}/nepi_docker_config.yaml
update_yaml_value "NEPI_ACTIVE_FS" $NEPI_ACTIVE_FS "$DOCKER_CONFIG_FILE"
update_yaml_value "NEPI_FSA_TAG" $NEPI_FSA_TAG "$DOCKER_CONFIG_FILE"


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
UPDATE_CONFIG=0
script_file=nepi_docker_dev.sh 
script_path=${SCRIPT_FOLDER}/${script_file}
if ! source_script $script_path $UPDATE_CONFIG; then
    script_error=$?
    echo "Script ${script_path} failed with error ${script_error}"
    exit 1
fi

#/nepi_start_all 
export NEPI_RUNNING_FS=$NEPI_ACTIVE_FS
export NEPI_RUNNING_TAG=$NEPI_FSA_TAG
export NEPI_RUNNING_ID=$(sudo docker container ls  | grep $NEPI_RUNNING_FS | awk '{print $1}')

if [[ -n "$NEPI_RUNNING_ID" ]]; then
    echo "Logging into NEPI Container ID ${NEPI_RUNNING_ID}"
    sudo docker exec --privileged -it -u $NEPI_USER $NEPI_RUNNING_ID /bin/bash -c "su ${NEPI_USER}"
else
    echo "NEPI Container Failed to Start"
fi

# AS ROOT
#sudo docker exec --privileged -it -e UDEV=1 $NEPI_RUNNING_ID /bin/bash


# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_time_start"
# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_network_start"
# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_dhcp_start"
# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_ssh_start"
# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_samba_start"
# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_engine_start"
# sudo docker exec  $NEPI_RUNNING_ID /bin/bash -c "/opt/nepi/scripts/nepi_license_start"


