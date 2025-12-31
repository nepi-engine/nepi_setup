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


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    exit 1
fi

# This file sets up nepi bash aliases and util functions



echo "########################"
echo "NEPI DEV ANNOTATION SETUP"
echo "########################"


CONFIG_USER=$(id -un)

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_SOURCE_FOLDER=$(dirname "${SCRIPT_FOLDER}")/resources/etc

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


if pip list | grep labelImg; then
    echo "labelImg package Installled"
else
    sudo apt update
    sudo apt install pyqt5-dev-tools python3-lxml git -y
    sudo apt install python3-venv python3-pip -y
    cd ~/
    python3 -m venv labelimg_env
    source labelimg_env/bin/activate
    sudo python -m pip install --upgrade pip
    sudo python -m pip install --upgrade setuptools wheel twine check-wheel-contents
    #sudo python3 -m pip install --ignore-installed label-studio
    echo ""
    echo "###################################"
    echo " Installing labelImg"
    echo "  THIS MAY TAKE SEVERAL MINUTES TO COMPLETE"
    echo "  AND MAY LOOK LIKE PROCESS IF FROZEN"
    echo "###################################"
    echo ""
    sudo python3 -m pip install --ignore-installed labelImg
    deactivate
    sudo rm -r labelimg_env

    if pip list | grep labelImg; then
        echo "labelImg package Installled"
    fi

fi



echo " "
echo "################################# "
echo "NEPI DEV ANNOTATION SETUP"
echo "################################# "
echo " "



