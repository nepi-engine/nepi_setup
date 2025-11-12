#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up nepi bash aliases and util functions

sudo -v

echo "########################"
echo "NEPI USER PC SETUP"
echo "########################"

echo "Running Intitialization Scripts"

export CONFIG_USER=$USER # Required User

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



#####################################
# Script Functions

NEPI_USER_CONFIGS=(
NEPI_DEVICE_ID \
NEPI_IP \
NEPI_IN_CONAINTER \
)

function print_current_config(){
    echo ""
    echo "Current Settings"
    echo "---------------------"
    echo "NEPI_DEVICE_ID: ${NEPI_DEVICE_ID}"
    echo "NEPI_IP: ${NEPI_IP}"
    echo ""
}

function udpate_config_file(){
    config_file=$1
    update_yaml_value "NEPI_IN_CONTAINER" $NEPI_IN_CONTAINER $config_file
    update_yaml_value "NEPI_DEVICE_ID" $NEPI_DEVICE_ID $config_file
    update_yaml_value "NEPI_IP" $NEPI_IP $config_file

}







#####################################
# Update NEPI System Config if needed

nepi_in_container=1
## Check Selection
echo ""
echo "Is NEPI running in a container on your Host device. Defualt is: Yes"
select ovw in "Yes" "No" "Quit"; do
    case $ovw in
        Yes ) nepi_in_container=1; break;;
        No ) nepi_in_container=0; break;;
        Quit ) exit 1
    esac
done
export NEPI_IN_CONTAINER=$nepi_in_container



echo ""
PS3='Please enter your choice: '
options=( "USE CURRENT SETTINGS" "Update NEPI Device ID Name" "Update NEPI Static IP Address" "QUIT" )

while true; do
    #clear # Optional: Clear the screen before displaying the menu

    print_current_config
    select opt in "${options[@]}" ; do
        case $opt in
            "USE CURRENT SETTINGS")
                break 2 # Exit both the select and the while loop
                ;;
            "Update NEPI Device ID Name")
                read -p "Enter a new Device Name (Default=device1): " USER_INPUT
                echo ""
                if is_valid_did "$USER_INPUT"; then
                    export NEPI_DEVICE_ID=$USER_INPUT
                fi       
                echo ""
                break # Exit the select statement, re-display menu
            ;;
            "Update NEPI Static IP Address")
                read -p "Enter a new Static IP Address (Default=192.168.179.103): " USER_INPUT
                echo ""
                if is_valid_ipv4 "$USER_INPUT"; then
                    export NEPI_IP=$USER_INPUT
                fi
                echo ""
                break # Exit the select statement, re-display menu
                ;;
            "QUIT")
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
done
echo ""



echo "Running script with settings:"
echo "----------------------------"
print_current_config
echo ""

USER_CONFIG_FILE=/home/${USER}/nepi_system_config.yaml
echo "Updating NEPI CONFIG File: ${USER_CONFIG_FILE} "
if [[ -f "$USER_CONFIG_FILE" ]]; then
    udpate_config_file $USER_CONFIG_FILE
fi


echo " "
echo "################################# "
echo "Updating SSH Keys"
echo ""


###################
# Check for default key

NEPI_SSH_PKEY_SOURCE=${SCRIPT_FOLDER}/resources/etc/ssh/ssh_keys/private_keys
NEPI_SSH_PKEY_DEST=/home/${USER}/ssh_keys=/home/${USER}/ssh_keys
if [ ! -d $NEPI_SSH_PKEY_SOURCE ]; then
    : # Do Nothing
else
    echo "Installing NEPI SSH Private Keys from: ${NEPI_SSH_PKEY_SOURCE} "
    if [[ ! -d "$NEPI_SSH_PKEY_DEST=/home/${USER}/ssh_keys" ]]; then
        mkdir -p $NEPI_SSH_PKEY_DEST=/home/${USER}/ssh_keys
    fi
    sudo chmod 600 $NEPI_SSH_PKEY_SOURCE/*
    sudo cp -p $NEPI_SSH_PKEY_SOURCE/* $NEPI_SSH_PKEY_DEST=/home/${USER}/ssh_keys
fi
sudo chown 0600 ${USER}:${USER} $NEPI_SSH_PKEY_DEST=/home/${USER}/ssh_keys/*

###############
# Check for available key options
NEPI_SSH_PKEY_DEST=/home/${USER}/ssh_keys=/home/${USER}/ssh_keys
sel_ssh_file=$(select_file_from_folder $NEPI_SSH_DEST | tail -n 1)
if [[ -n "$sel_ssh_file"  ]]; then
    sel_ssh_path=${NEPI_SSH_DEST}/${sel_ssh_file}
    if [[ -f "$sel_ssh_path" ]]; then
        NEPI_SSH_FILE=$sel_ssh_file
        NEPI_SSH_SOURCE=$sel_ssh_path
    fi
fi
echo "Using SSH Key file: ${NEPI_SSH_SOURCE}"
export NEPI_SSH_KEY_FILE=$NEPI_SSH_FILE



#################
# Update Key Path
sudo chmod 0700 $NEPI_SSH_DEST
sudo chown -R ${USER}:${USER} $NEPI_SSH_DEST





echo " "
echo "################################# "
echo "Updating ETC Hosts File"
echo ""

file=/etc/hosts
bfile=${file}.org
if [[ ! -f "$bfile" ]]; then
    path_backup $file $bfile
fi

sudo cp -a $bfile $file

echo "Updating NEPI IP in ${file}"

echo "${NEPI_IP} nepi" | sudo tee -a $file
echo "${NEPI_IP} nepi-${NEPI_DEVICE_ID}" | sudo tee -a $file
echo "${NEPI_IP} nepihost" | sudo tee -a $file
echo "${NEPI_IP} nepihost-${NEPI_DEVICE_ID}" | sudo tee -a $file
echo "${NEPI_IP} nepiadmin" | sudo tee -a $file
echo "${NEPI_IP} nepiadmin-${NEPI_DEVICE_ID}" | sudo tee -a $file
echo "${NEPI_IP} nepiuser" | sudo tee -a $file
echo "${NEPI_IP} nepiuser-${NEPI_DEVICE_ID}" | sudo tee -a $file



#####################################
echo " "
echo "################################# "
echo "Updating Bash Files"
echo ""

echo "Updating NEPI aliases files with NEPI_IP: ${NEPI_IP}"
BASHRC=/home/${USER}/.bashrc


NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
NEPI_UTILS_DEST=/home/${USER}/.nepi_bash_utils
echo "Installing NEPI utils file from ${NEPI_UTILS_SOURCE} to  ${NEPI_UTILS_DEST} "
if [ -f "$NEPI_UTILS_DEST" ]; then
    sudo rm $NEPI_UTILS_DEST
fi
sudo cp $NEPI_UTILS_SOURCE $NEPI_UTILS_DEST
sudo chown -R ${USER}:${USER} $NEPI_UTILS_DEST

NEPI_ALIASES_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_pc_aliases
NEPI_ALIASES_DEST=/home/${USER}/.nepi_pc_aliases
echo "Installing NEPI aliases file from ${NEPI_ALIASES_SOURCE} to ${NEPI_ALIASES_DEST} "
if [ -f "$NEPI_ALIASES_DEST" ]; then
    sudo rm $NEPI_ALIASES_DEST
fi
sudo cp $NEPI_ALIASES_SOURCE $NEPI_ALIASES_DEST
sudo chown -R ${USER}:${USER} $NEPI_ALIASES_DEST

#############
echo "Updating user bashrc files"
### Backup USER BASHRC file if needed
file=$BASHRC
bfile=${BASHRC}.org
path_backup $file $bfile

sudo cp $bfile $BASHRC
sudo chown ${USER}:${USER} $BASHRC
sudo chmod 755 $BASHRC

# Add additional user bashrc statements
# Add NEPI SETTINGS
echo ' ' | sudo tee -a $BASHRC
echo '##### NEPI SETTINGS #####' | sudo tee -a $BASHRC
echo 'export NEPI_IP='${NEPI_IP} | sudo tee -a $BASHRC
echo 'export NEPI_DEVICE_ID='${NEPI_DEVICE_ID} | sudo tee -a $BASHRC
echo 'export NEPI_RECOVERY_DEVICE_ID=device1' | sudo tee -a $BASHRC
echo 'export NEPI_RECOVERY_IP=192.168.179.103' | sudo tee -a $BASHRC
echo 'export NEPI_IN_CONTAINER='${NEPI_IN_CONTAINER} | sudo tee -a $BASHRC
echo 'export NEPI_SSH_KEY_FILE='${NEPI_SSH_KEY_FILE} | sudo tee -a $BASHRC


if grep -qnw $BASHRC -e "##### Source NEPI Aliases #####" ; then
    : #echo "Already Done"
else
    echo ' ' | sudo tee -a $BASHRC
    echo '##### Source NEPI Aliases #####' | sudo tee -a $BASHRC
    echo 'if [ -f '${NEPI_ALIASES_DEST}' ]; then' | sudo tee -a $BASHRC
    echo '    . '${NEPI_ALIASES_DEST} | sudo tee -a $BASHRC
    echo 'fi' | sudo tee -a $BASHRC
fi

sudo chown ${USER}:${USER} ~/.bashrc
sudo chmod 0644 ~/.bashrc

echo ""
echo "Sourcing updated bash files"
source $BASHRC
wait



echo " "
echo "################################# "
echo "Clearing Known Hosts"
echo ""

ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "nepi" >/dev/null 2>&1
ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "nepihost" >/dev/null 2>&1



echo " "
echo "################################# "
echo "Installing Required Software"
echo ""

if command -v yq &>/dev/null; then
    : # Do nothing here
else
    echo ">>>>>>>>>>>>>>>"
    echo "Installing yq software"
    sudo add-apt-repository ppa:rmescandon/yq -y
    sudo apt update
    sudo apt install yq -y
fi
if command -v git &>/dev/null; then
    : # Do nothing here
else
    echo ">>>>>>>>>>>>>>>"
    echo "Installing git software"
    sudo apt install git -y
    sudo apt install gitk -y
fi

#sudo apt install nmap -y




echo " "
echo "################################# "
echo "NEPI USER PC Setup Complete"
echo "################################# "
echo " "
echo " "
echo "To see a list of NEPI command line shortcuts run: nepihelp"
