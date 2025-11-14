#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file runs setup script debug fixes 
CONFIG_USER=$(id -un 1000)

if [[ -z "$SCRIPT_FOLDER" ]]; then
    SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
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