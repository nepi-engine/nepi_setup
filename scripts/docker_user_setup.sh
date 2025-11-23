#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up NEPI Docker users


if ! [ $(id -u) = 0 ]; then
   echo 'This scripts must be run as root user. Type "sudo su" and retry'
   exit 1
fi

###############
# Ask Some Questions

DEMO_INSTALL=1

echo "Is this a DEMO installation"
read -p "$1 ([y]es or [N]o): " choice
case "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" in
    y|yes) DEMO_INSTALL=1 ;;
    *) DEMO_INSTALL=0 ;;
esac








###############
# Create a tmp folder for all users
sudo mkdir -p /tmp/nepihost
sudo chmod -R 0777 /tmp/nepihost

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

echo "########################"
echo "NEPI USER SETUP"
echo "########################"


###########
CONFIG_USER=nepihost
SYS_USER_1=nepi
SYS_USER_2=nepiadmin

########
CONFIG_USER_PW=nepi
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
    echo "${CONFIG_USER}:${CONFIG_USER_PW}" | sudo chpasswd
fi    
if id -u "$CONFIG_USER" >/dev/null 2>&1; then
    echo "Configuring NEPI Base User account $CONFIG_USER"
    # sudo rm -r /home/${CONFIG_USER}
    # sudo mkdir -p /home/${CONFIG_USER}
    # sudo cp -r /etc/skel/. /home/${CONFIG_USER}/
    # sudo chown -R ${CONFIG_USER}:${CONFIG_USER} /

    echo "${CONFIG_USER}:${CONFIG_USER_PW}" | sudo chpasswd
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
    sudo usermod -aG $SUDO_USER ${CONFIG_USER} >/dev/null 2>&1


	#sudo usermod -s /bin/bash ${CONFIG_USER} # Fix no login user
	#sudo chsh -s /bin/bash ${CONFIG_USER} # Fix no login user


        
    if [[ "$SUDO_USER" != "$CONFIG_USER" ]]; then
        if [[ -d "/home/${SUDO_USER}/nepi_setup" ]]; then
            sudo cp -r "/home/${SUDO_USER}/nepi_setup" "/home/${CONFIG_USER}/nepi_setup"
        fi
    fi

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
   
        sudo chown ${CONFIG_USER}:${CONFIG_USER} /home/${user}
        sudo chmod 0755 /home/${CONFIG_USER}


    sudo usermod -aG sudo $SUDO_USER >/dev/null 2>&1
    sudo usermod -aG $SYS_USER_1 $SUDO_USER >/dev/null 2>&1
    sudo usermod -aG $SYS_USER_2 $SUDO_USER >/dev/null 2>&1
    sudo adduser ${SUDO_USER} dialout
    sudo usermod -aG dialout ${SUDO_USER} >/dev/null 2>&1
    sudo usermod -aG tty ${SUDO_USER} >/dev/null 2>&1
    sudo usermod -aG i2c ${SUDO_USER} >/dev/null 2>&1
    sudo usermod -aG video ${SUDO_USER} >/dev/null 2>&1
    sudo usermod -aG docker ${SUDO_USER} >/dev/null 2>&1
    sudo usermod -aG $CONFIG_USER ${SUDO_USER} >/dev/null 2>&1


else
    echo "Failed to create user account $CONFIG_USER"
    echo "Manual create an Adminstrator user account name ${CONFIG_USER}"
    echo "Then rerun this script"
    exit 1
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
        sudo usermod -aG $SUDO_USER  ${user} >/dev/null 2>&1

        sudo usermod -s /sbin/nologin $user
		
        sudo chown ${user}:${user} /home/${user}
        sudo chmod 0755 /home/${user}

        sudo usermod -aG $user ${SUDO_USER} >/dev/null 2>&1
        
    else
        echo "Failed to create user account $user"
        echo "Manual create an Adminstrator user account name ${user}"
        echo "Then rerun this script"
        exit 1
    fi

}

new_system_user ${SYS_USER_1} ${SYS_USER_1_PW}
new_system_user ${SYS_USER_2} ${SYS_USER_2_PW}




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
   exit 1
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



if [[ "$DEMO_INSTALL" -eq 0 ]]; then

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
fi


# echo "###################################"
# echo "Adding NEPI users to existing groups"
# echo "###################################"

# UID_START=1000
# UID_END=1999
# # Read /etc/passwd and process users
# while IFS=':' read -r username _ uid gid _ _ _; do
#     if [[ $uid -ge $UID_START && $uid -le $UID_END ]]; then
#         if [[  "$username" == 'nepihost' || "$username" == 'nepi'  || "$username" == 'nepiadmin' ]]; then
#             is_nepi_user=1
#         else
#             is_nepi_user=0
#         fi
#         if [[  "$is_nepi_user" -eq 0 ]]; then
#             sudo usermod -aG $username nepihost 
#             sudo usermod -aG $username nepi 
#             sudo usermod -aG $username nepiadmin 
#         fi
#     fi
# done < /etc/passwd



####################
# Remove the repo
# if [[ "$CONFIG_USER" == 'nepihost' ]]; then
#     rm -r /home/nepihost/nepi_setup
# else
#     rm -r /home/nepi/nepi_setup
# fi



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

echo ""
echo "*** REBOOT YOUR DEVICE ***"
