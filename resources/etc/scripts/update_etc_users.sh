#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script updates etc user settings


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
echo "UPDATING ETC USERS"

pw_changed=0

echo ""
echo "########"
echo "Updating nepi user passwords"

function update_password() {
        username=$1
        password=$2

        OLD_HASH=$(sudo grep "^${username}:" /etc/shadow | cut -d: -f2)

        echo "${username}:${password}" | sudo chpasswd

        # After chpasswd
        NEW_HASH=$(sudo grep "^${username}:" /etc/shadow | cut -d: -f2)

        if [ "$OLD_HASH" != "$NEW_HASH" ]; then
            return 0
        else
            return 1
        fi
}


if update_password $NEPI_USER $NEPI_USER_PW; then pw_changed=1 fi
if update_password $NEPI_HOST_USER $NEPI_HOST_PW; then pw_changed=1 fi
if update_password $NEPI_ADMIN_USER $NEPI_ADMIN_PW; then pw_changed=1 fi




if [[ "$NEPI_ALLOWS_USERS" -eq 0 ]]; then

    echo ""
    echo "########"
    echo "Removing Non-NEPI user IDs and Groups"

    cur_users=$(awk -F':' '1000 <= $3 && $3 <= 2000 {print $1, $3}' /etc/passwd)
    echo "Current Users:"
    echo $cur_users

    OLD_UID_START=1000
    OLD_UID_END=2999

    # Function to update user and group IDs
    remove_user() {
        local username=$1
        echo "Removiong non-NEPI user '$username'"
        sudo deluser $username
        echo "Removing ${username} home folder."
        sudo rm -r /home/${username}
        echo "User '$username' removed successfully."
    }

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
                remove_user "$username"
            fi
        fi
    done < /etc/passwd

    echo "Updated Users:"
    echo $cur_users

fi



# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
        echo ""
        echo "########"
        echo "Configuring nepi Samba passwords"
        echo -e "$NEPI_USER_PW\n$NEPI_USER_PW" | sudo smbpasswd -a -s "$NEPI_USER" >/dev/null 2>&1
        sudo usermod -a -G $NEPI_HOST_USER $NEPI_USER > /dev/null

        echo -e "$NEPI_HOST_PW\n$NEPI_HOST_PW" | sudo smbpasswd -a -s "$NEPI_HOST_USER" >/dev/null 2>&1
        sudo usermod -a -G $NEPI_USER $NEPI_HOST_USER > /dev/null

        echo -e "$NEPI_ADMIN_PW\n$NEPI_ADMIN_PW" | sudo smbpasswd -a -s "$NEPI_ADMIN_USER" >/dev/null 2>&1
        sudo usermod -a -G $NEPI_HOST_USER $NEPI_ADMIN_USER >/dev/null 2>&1

        if [[ "$pw_changed" -eq 1 ]]; then
                sudo systemctl restart sshd
        fi

fi




