#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script Updates NEPI ETC Files

echo ""
echo "########################"
echo "STARTING NEPI ETC UPDATE PROCESS"
echo "########################"
echo ""

source /home/${USER}/.nepi_bash_utils
wait


#############################
# Load the config file

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

if [ ! -f "${SCRIPT_FOLDER}/load_system_config.sh" ]; then
  echo  "Could not find system config file at: ${SCRIPT_FOLDER}/load_system_config.sh"
else
    source ${SCRIPT_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SYSTEM_CONFIG_DEST}"
        exit 1
    fi

    #############################
    # Sync with existing configs
    #############################
    echo "Updating NEPI ETC folder ${SCRIPT_FOLDER} from Factory and System config folders)"
    #############

    UPDATE_PATH=$SCRIPT_FOLDER

    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}${UPDATE_PATH}/../*
    sudo chmod -R 775 ${UPDATE_PATH}/../*

    # Sync with factory configs first
    FSOURCE_PATH=${NEPI_CONFIG}/factory_cfg
    if [ ! -d "${FSOURCE_PATH}/etc" ]; then
        sudo mkdir -p ${FSOURCE_PATH}/etc
    fi
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${FSOURCE_PATH}
    sudo chmod -R 775 ${FSOURCE_PATH}
    sudo rsync -arh ${FSOURCE_PATH}/etc/ ${UPDATE_PATH}/

    # Sync with system config
    SSOURCE_PATH=${NEPI_CONFIG}/system_cfg
    if [ ! -d "${SSOURCE_PATH}/etc" ]; then
        sudo mkdir -p ${SSOURCE_PATH}/etc
    fi
    if find "$SSOURCE_PATH" -maxdepth 0 -empty | read; then
      sudo rsync -arh ${FSOURCE_PATH}/etc/ ${SSOURCE_PATH}/  
    fi
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${SSOURCE_PATH}
    sudo chmod -R 775 ${SSOURCE_PATH}
    sudo rsync -arh ${SSOURCE_PATH}/etc/ ${UPDATE_PATH}/

    # Fix Update Path permissions
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${FSOURCE_PATH}
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${SSOURCE_PATH}
    sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}${UPDATE_PATH}/../*
    sudo chmod -R 775 ${UPDATE_PATH}/../*

    ########################
    # Configure NEPI Host Services
    ########################

    # systemctl_active=0
    # check=$(systemctl is-active --quiet your_script_name.service >/dev/null 2>&1)
    # if [[ "$?" -eq 0 ]]; then
    #     echo "Systemctl daemon is running."
    #     systemctl_active=1
    # else
    #     echo "Systemctl daemon not running."
    # fi
    
    # supervisor_active=0
    # if pgrep supervisord > /dev/null; then
    #     echo "Supervisord daemon is running."
    #     supervisor_active=0
    # else
    #     echo "Supervisord daemon not running."
    # fi


    # First Backup original if needed
    if [[ "$NEPI_MANAGES_ETC" -eq 1 ]]; then
        back_ext=org
        overwrite=0

        ### Backup ETC folder if needed
        folder=/etc
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite

        ### Backup USR LIB SYSTEMD folder if needed
        folder=/usr/lib/systemd/system
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite

        ### Backup RUN SYSTEMD folder if needed
        folder=/run/systemd/system
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite

        ### Backup USR LIB SYSTEMD USER folder if needed
        folder=/usr/lib/systemd/user
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite
    fi





    #######################################
    ### Setup NEPI Docker Service

    if [[ "$NEPI_MANAGES_ETC" -eq 1 ]]; then
        ##################################
        # Setting Up NEPI Managed Services on Host


        echo "Setting Up NEPI Managed Services"
        etc_source=$SCRIPT_FOLDER

        ###########################################
        if [[ ( "$NEPI_MANAGES_HOSTNAME" -eq 1 && ( "$USER" == "$NEPI_HOST_USER"  || ( "$USER" == "$NEPI_USER" && "$NEPI_IN_CONTAINER" -eq 0 ))) ]]; then

            #########################################
            # Update ETC HOSTS File
            file=${etc_source}/hosts
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

            ######################
            # Update ETC HOSTNAME File
            file=${etc_source}/hostname
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


            echo "Restarting hostnamed service"
            sudo systemctl restart systemd-hostnamed
        fi

        ###########################################
        if [[ "$NEPI_MANAGES_TIME" -eq 1 ]]; then
            # Install NTP Sources
            echo " "
            echo "Configuring chrony.conf"
            #### TODO: Edit conf file with NEPI_NTP_IP ########## 
            #sudo rm -r /etc/chrony/chrony.conf
            sudo cp ${etc_source}/chrony/chrony.conf /etc/chrony/chrony.conf
            ###
            sudo timedatectl set-ntp false
            sudo systemctl enable chrony
            sudo systemctl restart chrony
        fi


        ###########################################
        if [[ "$NEPI_MANAGES_NETWORK" -eq 1 ]]; then


            if [[ "$USER" == "$NEPI_HOST_USER" ]]; then
                ####### Add NEPI IP Addr to eth0
                    #sudo ip addr add ${NEPI_IP}/24 dev eth0

                # OR?

                    # # Set up static IP addr.
                    # echo "Updating Network interfaces.d"
                    # sudo rm -r /etc/network/interfaces.d
                    # sudo cp -a -r ${etc_source}/network/interfaces.d /etc/network/

                    # echo "Updating Network interfaces"
                    # sudo rm -r /etc/network/interfaces
                    # sudo cp -a -r ${etc_source}/network/interfaces /etc/network/interfaces

                    # # Set up DHCP
                    # echo "Updating Network dhclient.conf"
                    # sudo rm -r /etc/dhcp/dhclient.conf
                    # sudo cp -a -r ${etc_source}/dhcp/dhclient.conf /etc/dhcp/dhclient.conf

                    # # # Set up WIFI
                    # # if [[ ! -d "/etc/wpa_supplicant" ]]; then
                    # #     sudo mkdir /etc/wpa_supplicant
                    # # fi
                    
                    # sudo rm -r /etc/wpa_supplicant
                    # sudo cp -a -r ${etc_source}/wpa_supplicant /etc/


                # Some usefull commmands
                # sudo apt install netplan.io -y
                # sudo apt install ifupdown -y 
                # sudo apt install net-tools -y 
                # sudo apt install iproute2 -y


                #sudo systemctl stop NetworkManager
                #sudo systemctl stop networking.service


                # # RESTART NETWORK
                # #sudo ip addr flush eth0 && 
                # sudo systemctl enable -now networking.service
                # sudo ifdown --force --verbose eth0
                # sudo ifup --force --verbose eth0

                # # Remove and restart dhclient
                # sudo dhclient -r
                # sudo dhclient
                # sudo dhclient -nw
                # #ps aux | grep dhcp

            fi

            if [[ "$USER" == "$NEPI_USER" ]]; then

                    # Set up static IP addr.
                echo "Updating Network interfaces.d"
                sudo rm -r /etc/network/interfaces.d
                sudo cp -a -r ${etc_source}/network/interfaces.d /etc/network/

                echo "Updating Network interfaces"
                sudo rm -r /etc/network/interfaces
                sudo cp -a -r ${etc_source}/network/interfaces /etc/network/interfaces

                # Set up DHCP
                echo "Updating Network dhclient.conf"
                sudo rm -r /etc/dhcp/dhclient.conf
                sudo cp -a -r ${etc_source}/dhcp/dhclient.conf /etc/dhcp/dhclient.conf

                # # Set up WIFI
                # if [[ ! -d "/etc/wpa_supplicant" ]]; then
                #     sudo mkdir /etc/wpa_supplicant
                # fi
                
                sudo rm -r /etc/wpa_supplicant
                sudo cp -a -r ${etc_source}/wpa_supplicant /etc/

            fi

            
        fi


    ########################################
    # Setup NEPI etc sync process service
    ########################################
    # sudo cp -r ${etc_source}/lsyncd/lsyncd.blank /etc/lsyncd/lsyncd.conf
    # sudo chown -R ${USER}:${USER} /etc/lsyncd/lsyncd.conf


    if [[ "$USER" == "$NEPI_USER" ]]; then
         echo "Configuring NEPI Sync Service"

        # lsyncd_file=/etc/lsyncd/lsyncd.conf
        # etc_sync=$etc_source
        # etc_dest=${NEPI_CONFIG}/docker_cfg/etc
        # echo "" | sudo tee -a $lsyncd_file
        # echo "sync {" | sudo tee -a $lsyncd_file
        # echo "    default.rsync," | sudo tee -a $lsyncd_file
        # echo '    source = "'${etc_sync}'/",' | sudo tee -a $lsyncd_file
        # echo '    target = "'${etc_dest}'/",' | sudo tee -a $lsyncd_file
        # echo "}" | sudo tee -a $lsyncd_file
        # echo " " | sudo tee -a $lsyncd_file

        # Make sure lsyncd is only started manually by nepi_launch.sh script
        # sudo systemctl disable lsyncd

        # # Setup NEPI ETC to OS Host ETC Link Service
        # echo "Setting Up NEPI ETC Sycn service"
        # sudo cp -r ${etc_source}/lsyncd /etc/
        # sudo chown -R ${CONFIG_USER}:${CONFIG_USER} ${etc_source}/lsyncd

        #sudo systemctl enable lsyncd
        #sudo systemctl restart lsyncd
    #elif [[ "$USER" == "$NEPI_HOST_USER"]]; then
    #    : # pass
    fi

    #########################################
    # Setup supervisor service
    #########################################
    if [[ "$USER" == "$NEPI_USER" && "$NEPI_IN_CONTAINER" -eq 1 ]]; then
        echo "Restarting NEPI Services"
        sudo supervisorctl restart all
    fi

    # Backup NEPI folders
    if [[ "$NEPI_MANAGES_ETC" -eq 1 ]]; then
        back_ext=nepi
        overwrite=1

        ### Backup ETC folder
        folder=/etc
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite

        ### Backup USR LIB SYSTEMD folder
        folder=/usr/lib/systemd/system
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite

        ### Backup RUN SYSTEMD folder
        folder=/run/systemd/system
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite

        ### Backup USR LIB SYSTEMD USER folder
        folder=/usr/lib/systemd/user
        folder_back=${folder}.${back_ext}
        path_backup $folder $folder_back $overwrite
    fi

fi

echo ""
echo "########################"
echo "NEPI ETC UPDATE COMPLETE"
echo "########################"
echo ""











