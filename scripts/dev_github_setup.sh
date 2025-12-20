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
echo "NEPI DEV GITHUB SETUP"
echo "########################"

echo "Running Intitialization Scripts"


CONFIG_USER=$(id -un)

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_SOURCE_FOLDER=$(dirname "${SCRIPT_FOLDER}")/resources/etc

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE




if [[ ${CONFIG_USER} != 'nepi' && ${CONFIG_USER} != 'nepihost' ]]; then

    if ! is_valid_internet >/dev/null 2>&1; then
        echo "No Internet Connection Detected.  Connect and rerun this script"
        exit 1
    fi


    echo " "
    echo "################################# "
    echo "Checking Github SSH Key"
    echo ""

    ssh -T git@github.com >/dev/null 2>&1
    if [[ "$?" -lt 2 ]]; then
        key_file=$(ssh -G git@github.com 2>/dev/null | grep -im1 '^IdentityFile' | cut -d' ' -f2) >/dev/null
        key_name=$(basename "${key_file}")
        echo "GitHub SSH key authenticated with key file ${key_file}"
    else
        key_name=id_ed25519_nepi
        key_file=/home/${CONFIG_USER}/.ssh/${key_name}
        if [[ ! -f $key_file ]]; then
            echo "Creating NEPI GitHub ssh_key ${key_name}"
            echo ""
            ssh-keygen -t ed25519 -f ${key_file} -q -N "" -C "nepi_github_ssh_key"

        fi
        config_file=/home/${CONFIG_USER}/.ssh/config
        touch ${config_file}
        if grep -qnw $config_file -e ${key_name}; then
            : #echo "Already Done"
        else
            echo 'Host github.com' | sudo tee -a $config_file
            echo '   AddKeysToAgent yes' | sudo tee -a $config_file
            echo '   UseKeychain yes' | sudo tee -a $config_file
            echo '   IdentityFile '${key_file} | sudo tee -a $config_file
        fi
      
        eval "$(ssh-agent -s)"
        ssh-add ${key_file}

    fi



fi

echo " "
echo "################################# "
echo "NEPI DEV GITHUB SETUP COMPLETE"
echo "################################# "
echo " "

ssh -T git@github.com >/dev/null 2>&1
if [[ "$?" -gt 1 ]]; then

    echo "*** ADD YOUR NEW NEPI GITHUB SSH KEY TO YOUR GITHUB ACCOUNT BEFORE PROCEEDING ***"
    echo ""
    echo "1) Log Into Your GitHub Account at www.github.com"
    echo "2) Click on your User Icon, and select 'Settings"
    echo "3) Select 'SSH and GPG keys' from the left sidebar menu"
    echo "4) Click the 'New SSH key' button in the top right"
    echo "5) Enter the following information in the boxes provided,"
    echo "   Then click the 'Add SSH key' button"
    echo ""
    echo "<< TITLE >>"
    echo ${key_name}
    echo ""
    echo "<< KEY_TYPE >>"
    echo "Authentication Key"
    echo ""
    echo "<< KEY >>"
    echo $(cat ${key_file}.pub)
    echo ""
fi

