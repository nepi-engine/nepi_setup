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
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    exit 1
fi

# This file sets up nepi bash aliases and util functions

sudo -v

echo "########################"
echo "NEPI USER GIT SETUP"
echo "########################"

echo "Running Intitialization Scripts"

sudo -v

CONFIG_USER=$(id -un)

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



#####################################
# Git Setup



PRIVATE_KEY='NOT SET'


https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent


echo " "
echo "################################# "
echo "NEPI USER GIT Setup Complete"
echo "################################# "
echo " "

if [[ "$PRIVATE_KEY" != 'NOT SET' ]]; then
    echo " "
    echo "Log into your GitHub account and add the following private key to your account:"
    echo ""
    echo $PRIVATE_KEY
    echo ""
fi
