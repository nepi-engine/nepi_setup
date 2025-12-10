#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs NEPI Docker utility software packages

sudo -v



echo "########################"
echo "NEPI DOCKER UTILS SETUP"
echo "########################"


echo "Running Intitialization Scripts"

export CONFIG_USER=nepi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

. ${SCRIPT_FOLDER}/script_setup.sh
if [[ "$?" -ne 0 ]]; then
    echo "Script Setup Failed. Exiting"
    exit 1
fi 


#################################

sudo apt update

echo ""
echo "Installing Chromium Browser"
sudo snap remove --purge chromium
sudo snap install chromium
#sudo apt install chromium-browser -y
#chromium-browser --disable-features=DnsOverHttps


if command -v code &> /dev/null; then
    echo "Visual Studio Code is installed and accessible."
else
    echo ""
    echo "Installing visual code editor"
    
    if [[ $NEPI_ARCH -eq arm64 ]]; then
        curl -L https://aka.ms/linux-arm64-deb > code_arm64.deb
        sudo apt install ./code_arm64.deb
        wait
        sudo rm code_arm64.deb
    elif [[ $NEPI_ARCH -eq amd64 ]]; then
        sudo snap install code --channel=edge --classic
    fi

fi


##################################
echo ""
echo 'NEPI Docker Utis Setup Complete'
##################################

