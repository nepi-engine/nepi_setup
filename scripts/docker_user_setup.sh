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

LITE_INSTALL=$1

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $LITE_INSTALL
if [[ "$?" -ne 0 ]]; then
    return 1
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 1
fi


if [[ $LITE_INSTALL == 0 ]]; then
    CONFIG_USER=nepihost
else
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
fi
export CONFIG_USER=$CONFIG_USER


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
echo "Script Folder: ${SCRIPT_FOLDER}"
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

# Load System Config File
echo "Loading NEPI SYSTEM CONFIG"
nepi_config_loaded=0
NEPI_SETUP_CONFIG_FILE=${RESOURCES_FOLDER}/etc/load_system_config.sh
NEPI_SYSTEM_CONFIG_FILE=${NEPI_SYSTEM_CONFIG}/etc/load_system_config.sh
if [[ -f $NEPI_SYSTEM_CONFIG_FILE ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SYSTEM_CONFIG_FILE}"
    source ${NEPI_SYSTEM_CONFIG_FILE} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        nepi_config_loaded=1
    fi
elif [[ -f $NEPI_SETUP_CONFIG_FILE && $nepi_config_loaded -eq 0 ]]; then
    echo "Loading NEPI SYSTEM CONFIG from: ${NEPI_SETUP_CONFIG_FILE}"
    source ${NEPI_SETUP_CONFIG_FILE}  >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "Failed to load ${NEPI_SETUP_CONFIG_FILE}"
    fi
fi




if ! [ $(id -u) = 0 ]; then
    echo 'This scripts must be run as root user. Type "sudo su" and retry'
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)




###############
# Create a tmp folder for config user
sudo mkdir -p /tmp/$CONFIG_USER
sudo chmod -R 0777 /tmp/$CONFIG_USER

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

echo "########################"
echo "NEPI USER SETUP"
echo "########################"


###########
CONFIG_USER=$CONFIG_USER
SYS_USER_1=nepi
SYS_USER_2=nepiadmin

########

SYS_USER_1_PW=nepi
SYS_USER_2_PW=nepiadmin


echo ""
echo "###################################"
echo "Setting NEPI ROOT USER"
echo "###################################"
echo ""

sudo adduser root dialout
sudo usermod -aG dialout root >/dev/null 2>&1
sudo usermod -aG tty root >/dev/null 2>&1
sudo usermod -aG i2c root >/dev/null 2>&1
sudo usermod -aG video root >/dev/null 2>&1
sudo usermod -aG docker root >/dev/null 2>&1
sudo usermod -aG netdev root >/dev/null 2>&1

echo ""
echo "###################################"
echo "Setting NEPI CONFIG USER: ${CONFIG_USER}"
echo "###################################"
echo ""

if id -u "$CONFIG_USER" >/dev/null 2>&1; then
    echo "User $CONFIG_USER exists."
    
else
    echo "User $CONFIG_USER does not exist, creating"
    #sudo useradd -m -s /bin/bash -p "$(openssl passwd -1 ${CONFIG_USER_PW})" ${CONFIG_USER}
    #sudo useradd $CONFIG_USER -s /bin/bash -g sudo -
    sudo groupdel "$CONFIG_USER" >/dev/null 2>&1
    sudo adduser --gecos "$CONFIG_USER" --disabled-password "$CONFIG_USER"
    CONFIG_USER_PW=nepi
    echo "${CONFIG_USER}:${CONFIG_USER_PW}" | sudo chpasswd
fi    


###################################
# Configure NEPI System Accounts

function new_system_user(){
    user=$1
    password=$2
    echo ""
    echo "###################################"
    echo "Setting NEPI SYSTEM USER: ${user}"
    echo "###################################"
    echo ""
    # if grep -q "\b${user}\b" /etc/group;  then
    #         sudo groupdel $user
    # fi
    if id -u "$user" >/dev/null 2>&1; then
        echo "User $user exists."
        
    else
        echo "User $user does not exist, creating"
        sudo useradd -m -s /bin/bash -p "$(openssl passwd -1 ${password})" ${user}
    fi    
    if id -u $user; then
        echo "Configuring NEPI System User account $user"
        echo "${user}:${password}" | sudo chpasswd
        # sudo usermod -aG $user $user    
        sudo usermod -aG sudo $user >/dev/null 2>&1
        sudo usermod -aG $CONFIG_USER $user >/dev/null 2>&1
        sudo adduser ${user} dialout
        sudo usermod -aG dialout ${user} >/dev/null 2>&1
        sudo usermod -aG tty ${user} >/dev/null 2>&1
        sudo usermod -aG i2c ${user} >/dev/null 2>&1
        sudo usermod -aG video ${user} >/dev/null 2>&1
        sudo usermod -aG docker ${user} >/dev/null 2>&1
        sudo usermod -aG netdev ${user} >/dev/null 2>&1
        sudo usermod -aG $SUDO_USER  ${user} >/dev/null 2>&1
        sudo usermod -aG $user ${SUDO_USER} >/dev/null 2>&1
        
        sudo usermod -s /sbin/nologin $user
		
        sudo chown ${user}:${user} /home/${user}
        sudo chmod 0755 /home/${user}

       

    else
        echo "Failed to create user account $user"
        echo "Manual create an Adminstrator user account name ${user}"
        echo "Then rerun this script"
        return 
    fi

}

new_system_user ${SYS_USER_1} ${SYS_USER_1_PW}
new_system_user ${SYS_USER_2} ${SYS_USER_2_PW}


if id -u "$CONFIG_USER" >/dev/null 2>&1; then
    echo "Configuring NEPI Base User account $CONFIG_USER"
    # sudo rm -r /home/${CONFIG_USER}
    # sudo mkdir -p /home/${CONFIG_USER}
    # sudo cp -r /etc/skel/. /home/${CONFIG_USER}/
    # sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /

    if [[ $CONFIG_USER == "nepihost" ]]; then
        echo "${CONFIG_USER}:${CONFIG_USER_PW}" | sudo chpasswd

        if is_valid_rpi && [ -f "/etc/lightdm/lightdm.conf" ]; then
            update_text_value "/etc/lightdm/lightdm.conf" "autologin-user=" "autologin-user=nepihost" 
        fi
    fi
    #sudo usermod -aG $CONFIG_USER $CONFIG_USER
    sudo usermod -aG sudo $CONFIG_USER >/dev/null 2>&1
    sudo usermod -aG $SYS_USER_1 $CONFIG_USER >/dev/null 2>&1
    sudo usermod -aG $SYS_USER_2 $CONFIG_USER >/dev/null 2>&1
    sudo adduser ${CONFIG_USER} dialout
    sudo usermod -aG dialout ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG tty ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG i2c ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG video ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG docker ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG netdev ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG ${SUDO_USER} ${CONFIG_USER} #>/dev/null 2>&1


	#sudo usermod -s /bin/bash ${CONFIG_USER} # Fix no login user
	#sudo chsh -s /bin/bash ${CONFIG_USER} # Fix no login user


        
    # if [[ "$SUDO_USER" != "$CONFIG_USER" ]]; then
    #     if [[ -d "/home/${SUDO_USER}/nepi_setup" ]]; then
    #         sudo cp -R /home/${SUDO_USER}/nepi_setup /home/${CONFIG_USER}/nepi_setup
    #     fi
    # fi
    # sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}/nepi_setup

    if [[ $CONFIG_USER == "nepihost" ]]; then
        # Updated the Desktop
        dfolder=/home/${CONFIG_USER}/Desktop
        if [[ -d "$dfolder" ]]; then
            if find "$dfolder" -maxdepth 0 -empty | read; then
                echo "Desktop folder cleaned"
            else
                sudo rm ${dfolder}/*
                echo "Desktop folder cleaned"
            fi
        fi
    fi
   
    sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${CONFIG_USER}
    sudo chmod 0755 /home/${CONFIG_USER}



else
    echo "Failed to create user account $CONFIG_USER"
    echo "Manual create an Adminstrator user account name ${CONFIG_USER}"
    echo "Then rerun this script"
    return 
fi




echo ""
echo "###################################"
echo "Changing Non-NEPI user IDs and Groups"
echo "###################################"
echo ""

cur_users=$(awk -F':' '1000 <= $3 && $3 <= 2000 {print $1, $3}' /etc/passwd)
echo "Current Users:"
echo $cur_users

OLD_UID_START=1000
OLD_UID_END=1999
NEW_UID_START=2000

# Require root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   return 
fi

function update_text_value(){
  FILE=$1
  KEY=$2
  UPDATE=$3
  if [ -f "$FILE" ]; then
    if grep -q "$KEY" "$FILE"; then
      sed -i "/^$KEY/c\\$UPDATE" "$FILE"
    else
      echo "$UPDATE" | sudo tee -a $FILE
    fi
  else
    echo "File not found ${FILE}"
  fi
}
export -f update_text_value


# Function to update user and group IDs
update_user_and_group() {
    local username=$1
    local old_uid=$2
    local old_gid=$3
    local new_uid=$4
    local new_gid=$5

    echo "Updating user '$username' (UID $old_uid -> $new_uid, GID $old_gid -> $new_gid)..."

    file=/etc/passwd
    key="${username}:"
    fline=$(cat $file | grep ${key})
    fline=${fline//${uid}/${new_uid}}
    fline=${fline//${gid}/${new_gid}}
    echo "Updating etc passwd file with ${fline}"
    update_text_value $file $key $fline

    file=/etc/group
    key="${username}:x:"
    fline=$(cat $file | grep ${key})
    fline=${fline//${gid}/${new_gid}}
    echo "Updating etc group file with ${fline}"
    update_text_value $file $key $fline
    # # Step 3: Update file ownership on the entire filesystem
    echo "Updating file ownership across in ${username} home folder."
    sudo chown -R ${new_uid}:${new_gid} /home/${username}

    echo "User '$username' updated successfully."
}



if [[ "$LITE_INSTALL" -eq 0 ]]; then

    # Read /etc/passwd and process users
    while IFS=':' read -r username _ uid gid _ _ _; do

        # Check if the UID is within the 1000-1999 range and is not a system user
        if [[ $uid -ge $OLD_UID_START && $uid -le $OLD_UID_END ]]; then
            echo "Checking user ${username} against nepi users"
            if [[  "$username" == 'nepihost' || "$username" == 'nepi'  || "$username" == 'nepiadmin' ]]; then
                is_nepi_user=1
            else
                is_nepi_user=0
            fi
            if [[  "$is_nepi_user" -eq 0 ]]; then
                # Calculate the new UID by adding 1000 to the old UID
                new_uid=$((uid + 1000))
                new_gid=$new_uid

                echo "Updating Non-NEPI user account ${username} ID and Group from ${uid} to ${new_uid}"
                echo "Updating Non-NEPI user account ${username} ID and Group from ${gid} to ${new_gid}"
                # Check if the group ID is the same as the user ID
                # This is the default behavior on many modern Linux systems
                update_user_and_group "$username" "$uid" "$gid" "$new_uid" "$new_gid"
            fi
        fi
    done < /etc/passwd

    echo "All Non-NEPI users have been updated."
    cur_users=$(awk -F':' '1000 <= $3 && $3 <= 3000 {print $1, $3}' /etc/passwd)
    echo "Updated User:"
    echo $cur_users

    echo ""
    echo "###################################"
    echo "Changing NEPI user IDs and Groups"
    echo "###################################"
    echo ""

    echo ""
    echo "Updating NEPI User IDs and Groups if Needed"


    # Read /etc/passwd and process users
    username=${CONFIG_USER}
    uid=$(id -u "$username")
    gid=$(id -g "$username")
    new_uid=1000
    new_gid=$new_uid
    if [[ "$uid" -ne "$new_uid" || "$gid" -ne "$new_gid" ]]; then
        update_user_and_group "$username" "$uid" "$gid" "$new_uid" "$new_gid"
    fi
    sudo chown ${username}:${username} /home/${username}
    sudo chmod 0755 /home/${username}

    username=${SYS_USER_1}
    uid=$(id -u "$username")
    gid=$(id -g "$username")
    new_uid=1001
    new_gid=$new_uid
    if [[ "$uid" -ne "$new_uid" || "$gid" -ne "$new_gid" ]]; then
        update_user_and_group "$username" "$uid" "$gid" "$new_uid" "$new_gid"
        sudo usermod -s /sbin/nologin $username
    fi
    sudo chown ${username}:${username} /home/${username}
    sudo chmod 0755 /home/${username}

    username=${SYS_USER_2}
    uid=$(id -u "$username")
    gid=$(id -g "$username")
    new_uid=1002
    new_gid=$new_uid
    if [[ "$uid" -ne "$new_uid" || "$gid" -ne "$new_gid" ]]; then
        update_user_and_group "$username" "$uid" "$gid" "$new_uid" "$new_gid"
        sudo usermod -s /sbin/nologin $username
    fi
    sudo chown ${username}:${username} /home/${username}
    sudo chmod 0755 /home/${username}
else 
    sudo usermod -aG $cur_users  ${CONFIG_USER} >/dev/null 2>&1
    sudo usermod -aG $cur_users  ${SYS_USER_1} >/dev/null 2>&1
    sudo usermod -aG $cur_users  ${SYS_USER_2} >/dev/null 2>&1
fi



####################
# Remove the repo
if [[ -d /home/${CONFIG_USER}/nepi_setup ]]; then
    sudo rm -r /home/${CONFIG_USER}/nepi_setup
fi



# echo "###################################"
# echo "Adding NEPI users to sudo users"
# echo "###################################"

source_file=${SOURCE_ETC_PATH}/docker/sudo/sudoers 
dest_file=/etc/sudoers
if [[ -f "$source_file" ]]; then
    sudo cp $source_file $dest_file
fi
sudo chown root:root $dest_file
sudo chmod 0440 $dest_file



echo ""
echo "All NEPI user IDs have been processed."
cur_users=$(awk -F':' '1000 <= $3 && $3 <= 3000 {print $1, $3}' /etc/passwd)
echo "Updated User:"
echo $cur_users

sudo chmod -R 0777 /tmp/nepi

echo ""
echo "########################"
echo "NEPI User Account Setup Complete"
echo "########################"


if [[ "$LITE_INSTALL" -eq 0 ]]; then
    echo ""
    echo "*** REBOOT YOUR DEVICE ***"
fi
