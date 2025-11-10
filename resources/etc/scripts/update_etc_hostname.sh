#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc hostname and hosts files and processes


export CONFIG_USER=$(id -un 1000)

if [[ -f "/home/nepi/.nepi_system_aliases" ]]; then
    CONFIG_USER=nepi
    bfile=/home/nepi/.bashrc
    ufile=/homenepi/.nepi_bash_utils
    afile=/home/nepi/.nepi_system_aliases
elif [[ -f "/home/nepihost/.nepi_docker_aliases" ]]; then
    CONFIG_USER=nepihost
    bfile=/home/nepihost/.bashrc
    ufile=/home/nepihost/.nepi_bash_utils
    afile=/home/nepihost/.nepi_docker_aliases
elif [[ -f "/home/${CONFIG_USER}/.nepi_docker_aliases" ]]; then
    bfile=/home/${CONFIG_USER}/.bashrc
    ufile=/home/${CONFIG_USER}/.nepi_bash_utils
    afile=/home/${CONFIG_USER}/.nepi_docker_aliases
else
    echo "NEPI Aliases bash file not found"
    exit 1
fi

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi

ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -n "$1" ]]; then
    LOAD_NEPI_CONFIG=$1
fi

if [[ "$LOAD_NEPI_CONFIG" -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi


echo ""
echo "UPDATING ETC HOSTNAME AND HOSTS"

# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then

    if [[ "$NEPI_MANAGES_HOSTNAME" -eq 1 ]]; then

        cur_hostname=$(hostname)
        echo "Checking current Hostname ${cur_hostname} against set Hostname ${NEPI_DEVICE_ID}"
        
        if [[ "${NEPI_DEVICE_ID}" != "${cur_hostname}" ]]; then

            ######################
            # Update ETC HOSTNAME File
            file=${ETC_FOLDER}/hostname
            echo "Updating hostname file: ${file}"
            if [ -f "${file}.blank" ]; then
                if [ ! -f "$file" ]; then
                    sudo rm $file
                fi
                sudo cp -a ${file}.blank $file

            
                entry="${NEPI_DEVICE_ID}"
                echo $entry
                echo "Updating NEPI IP in ${file}"
                if grep -qnw $file -e ${entry}; then
                    echo "Found NEPI IP in ${file} ${entry} "
                else
                    echo "Adding NEPI IP in ${file}"
                    echo $entry | sudo tee -a $file
                fi

                #sudo cp -R -a ${NEPI_CONFIG}/docker_cfg/${file} $file
                sudo rm -r /etc/hostname
                sudo cp -R -a $file /etc/hostname

            else
                echo "FAILED TO FIND SOURCE ${file}.blank"
            fi


            ###########
            # Update Hosts File
            file=${ETC_FOLDER}/hosts
            if [[ -f "${file}.blank" ]]; then
                echo "Updating hosts file: ${file}"

                if [ ! -f "$file" ]; then
                    sudo rm $file
                fi
                sudo cp -a ${file}.blank $file

                echo "Updating NEPI IP in ${file}"

                entry="${NEPI_IP} ${NEPI_USER}"
                echo "Adding NEPI IP in ${file}"
                echo "${NEPI_IP} ${NEPI_DEVICE_ID}" | sudo tee -a $file
                echo $entry | sudo tee -a $file
                echo "${entry}-${NEPI_DEVICE_ID}" | sudo tee -a $file

                entry="${NEPI_IP} ${NEPI_ADMIN_USER}"
                echo $entry | sudo tee -a $file
                echo "${entry}-${NEPI_DEVICE_ID}" | sudo tee -a $file

                entry="${NEPI_IP} ${NEPI_HOST_USER}"
                echo $entry | sudo tee -a $file
                echo "${entry}-${NEPI_DEVICE_ID}" | sudo tee -a $file

                sudo rm -r /etc/hosts
                sudo cp -R -a $file /etc/hosts
            else
                echo "FAILED TO FIND SOURCE ${file}.blank"
            fi
            
            ###################
            # Restart Service
            echo "Restarting hostnamed service"
            sudo hostnamectl set-hostname ${NEPI_DEVICE_ID}
            sudo systemctl restart systemd-hostnamed


            source ${ETC_SCRIPTS_FOLDER}/update_bash_config.sh
            

        fi

    fi

fi


############################
# Update NEPI Docker Config if needed
docker_config_setting="NEPI_ETC_HOSTNAME_UPDATE"
if [[ "$NEPI_IN_CONTAINER" -eq 1 ]]; then
    echo "Updating NEPI Docker Setting ${docker_config_setting}"
    docker_config_file=${NEPI_CONFIG}/docker_cfg/nepi_docker_config.yaml
    if [[ "$USER" == "$NEPI_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        update_val=1
        if [[ -f "$docker_config_file" ]]; then
            update_yaml_value $docker_config_setting $update_val $docker_config_file
        fi
    elif [[ "$USER" == "$NEPI_HOST_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        update_val=0
        if [[ -f "$docker_config_file" ]]; then
            update_yaml_value $docker_config_setting $update_val $docker_config_file
        fi
    fi
fi


