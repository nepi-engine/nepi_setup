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
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    exit 1
fi


# This file runs setup script debug fixes 
sudo -v

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER="$(id -un 1000)"
fi
if [[ ${CONFIG_USER} != 'nepi' || ${CONFIG_USER} != 'nepihost' ]]; then
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

if [[ "$CONFIG_USER" != 'nepi' && "$CONFIG_USER" != 'nepihost' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi' or 'nepihost'"
    exit 1
fi
####################
# Add your commands to test
####################



echo "##################################"
echo ""
echo 'NEPI Environment Setup 1 Complete'
echo "##################################"
echo ""
echo ""
echo "##################################"
echo "Chcking for CUDA support on python installs"
echo ""
sudo python3 -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"
echo ""
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
sudo python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
echo ""
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
sudo python3 -c "import torchvision; print(torchvision.__version__)"
echo ""
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
echo ""
echo ""
echo "##################################"
echo "If CUDA support required for any of these packages,"
echo " and not supported in current configurations shown above,"
echo "install CUDA supported version manaully"