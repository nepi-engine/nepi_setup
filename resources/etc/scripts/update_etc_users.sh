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

# This script updates etc user settings


sudo -v

if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -un)
    if [[ ${CONFIG_USER} == 'root' ]]; then
        CONFIG_USER=$SUDO_USER
    fi
fi
if [[ ! -n $CONFIG_USER ]]; then
    CONFIG_USER=$(id -nu 1000)
fi
export CONFIG_USER=$CONFIG_USER

ufile=/home/${CONFIG_USER}/.nepi_bash_utils

if [[ -f "$ufile" ]]; then
    source $ufile
else
    echo "NEPI Utils bash file not found at: ${ufile}"
    exit 1
fi


ETC_SCRIPTS_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ETC_FOLDER=$(dirname ${ETC_SCRIPTS_FOLDER})

LOAD_NEPI_CONFIG=1
if [[ -v $1 ]]; then
    if [[ $1 -eq 0 ]]; then
        LOAD_NEPI_CONFIG=0
        #echo "Skipping NEPI System Config load"
    fi
fi

USER_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml
if [[ -v $2 ]]; then
    if [[ -n $2 ]]; then
        USER_CONFIG_FILE=${2}
        #echo "Skipping NEPI System Config load"
    fi
fi

if [[ $LOAD_NEPI_CONFIG -eq 1 || ! -v NEPI_USER ]]; then
    # Load System Config File
    #echo "Loading NEPI SYSTEM CONFIG"
    source ${ETC_FOLDER}/load_system_config.sh
    if [ $? -eq 1 ]; then
        echo "Failed to load ${ETC_FOLDER}/load_system_config.sh"
        exit 1
    fi
fi


echo ""
echo "UPDATING ETC USERS"

nepi_user_pw_changed=0
nepi_host_user_pw_changed=0
nepi_admin_user_pw_changed=0

function check_password() {
    username=$1
    pcheck=$2
    echo "$pcheck" | su -c true "$username" >/dev/null 2>&1
    error=$?
    if [[ $error -eq 0 ]]; then
        return 0
    else
        ret=$(echo "$pcheck" | su -c true "$username" 2>/dev/null)
        if [[ ${ret} == 'This account is currently not available.' ]]; then
            return 0
        else
            return 1
        fi
    fi
}


function change_password() {
        username=$1
        password=$2

        if [[ ${password} == "encrypted" ]]; then
            echo "Password for ${username} encrypted" 
            return 1
        fi
        if check_password ${username} ${password} ; then
            echo "Password unchanged" 
            return 1
        fi        

        if is_valid_pw $password; then

            OLD_HASH=$(sudo grep "^${username}:" /etc/shadow | cut -d: -f2)

            echo "${username}:${password}" | sudo chpasswd

            # After chpasswd
            NEW_HASH=$(sudo grep "^${username}:" /etc/shadow | cut -d: -f2)

            if [ "$OLD_HASH" != "$NEW_HASH" ]; then
                echo "Updated password for user ${username}"
                return 0
            else
                return 1
            fi
        else
            echo "Password update for user ${username} failed. Not valid password" 
            return 1
        fi
}

if [[ -d /home/${NEPI_USER} ]]; then
    #echo "Checking password for ${NEPI_USER} ${NEPI_USER_PW}"
    if change_password $NEPI_USER $NEPI_USER_PW ; then 
        nepi_user_pw_changed=$?
    fi
    update_yaml_value "NEPI_USER_PW" "encrypted" $USER_CONFIG_FILE


    sudo chown ${NEPI_USER}:${NEPI_USER} /home/${NEPI_USER}
    sudo chmod 0755 /home/${NEPI_USER}
fi

if [[ -d /home/${NEPI_HOST_USER} ]]; then
    #echo "Checking password for ${NEPI_HOST_USER} ${NEPI_HOST_PW}"
        if change_password $NEPI_HOST_USER $NEPI_HOST_PW; then 
            nepi_host_user_pw_changed=$? 
        fi
        update_yaml_value "NEPI_HOST_PW" "encrypted" $USER_CONFIG_FILE

    sudo chown ${NEPI_HOST_USER}:${NEPI_HOST_USER} /home/${NEPI_HOST_USER}
    sudo chmod 0755 /home/${NEPI_HOST_USER}
fi

if [[ -d /home/${NEPI_ADMIN_USER} ]]; then
    #echo "Checking password for ${NEPI_ADMIN_USER} ${NEPI_ADMIN_PW}"
    if change_password $NEPI_ADMIN_USER $NEPI_ADMIN_PW; then 
        nepi_admin_user_pw_changed=$? 
    fi
    update_yaml_value "NEPI_ADMIN_PW" "encrypted" $USER_CONFIG_FILE

    sudo chown ${NEPI_ADMIN_USER}:${NEPI_ADMIN_USER} /home/${NEPI_ADMIN_USER}
    sudo chmod 0755 /home/${NEPI_ADMIN_USER}
fi


# if [[ "$NEPI_ALLOWS_USERS" -eq 0 ]]; then

#     echo ""
#     echo "########"
#     echo "Removing Non-NEPI user IDs and Groups"

#     cur_users=$(awk -F':' '1000 <= $3 && $3 <= 2000 {print $1, $3}' /etc/passwd)
#     echo "Current Users:"
#     echo $cur_users

#     OLD_UID_START=1000
#     OLD_UID_END=2999

#     # Function to update user and group IDs
#     remove_user() {
#         username=$1
#         echo "Removiong non-NEPI user '$username'"
#         sudo deluser $username
#         echo "Removing ${username} home folder."
#         sudo rm -r /home/${username}
#         echo "User '$username' removed successfully."
#     }

#     allow_users=1
#     if [[ "$NEPI_ALLOWS_USERS" -eq 0 ]]; then
#         allow_users=0
#     fi

#     # Read /etc/passwd and process users
#     while IFS=':' read -r username _ uid gid _ _ _; do

#         # Check if the UID is within the 1000-1999 range and is not a system user
#         if [[ $uid -ge $OLD_UID_START && $uid -le $OLD_UID_END ]]; then
#             echo "Checking user ${username} against nepi users"
#             if [[  "$username" == 'nepihost' || "$username" == 'nepi'  || "$username" == 'nepiadmin' ]]; then
#                 is_nepi_user=1
#             else
#                 is_nepi_user=0
#             fi
#             if [[  "$allow_users" -eq 0 && "$is_nepi_user" -eq 0 ]]; then
#                 remove_user "$username"
#             fi
#         fi
#     done < /etc/passwd

#     echo "Updated Users:"
#     echo $cur_users

# fi



# Update ETC files if systemd is running (Not in Container)
systemctl&> /dev/null
if [[ "$?" -eq 0 ]]; then
        needs_restart=0
        if [[ "$nepi_user_pw_changed" -eq 1 && ${NEPI_USER_PW} != 'encrypted' ]]; then
                echo ""
                echo "########"
                echo "Configuring nepi Samba passwords"
                echo -e "$NEPI_USER_PW\n$NEPI_USER_PW" | sudo smbpasswd -a -s "$NEPI_USER" >/dev/null 2>&1
                sudo usermod -a -G $NEPI_HOST_USER $NEPI_USER > /dev/null
                needs_restart=1
        fi

        if [[ "$nepi_host_user_pw_changed" -eq 1 && ${NEPI_HOST_PW} != 'encrypted' ]]; then
                echo ""
                echo "########"
                echo "Configuring nepihost Samba passwords"
                echo -e "$NEPI_HOST_PW\n$NEPI_HOST_PW" | sudo smbpasswd -a -s "$NEPI_HOST_USER" >/dev/null 2>&1
                sudo usermod -a -G $NEPI_USER $NEPI_HOST_USER > /dev/null
                needs_restart=1
        fi

        if [[ "$nepi_admin_user_pw_changed" -eq 1 && ${NEPI_ADMIN_PW} != 'encrypted' ]]; then
                echo ""
                echo "########"
                echo "Configuring nepiadmin Samba passwords"
                echo -e "$NEPI_ADMIN_PW\n$NEPI_ADMIN_PW" | sudo smbpasswd -a -s "$NEPI_ADMIN_USER" >/dev/null 2>&1
                sudo usermod -a -G $NEPI_HOST_USER $NEPI_ADMIN_USER >/dev/null
                needs_restart=1
        fi

        if [[ $needs_restart -eq 1 ]]; then
            echo "Restarting sshd service"
            sudo systemctl restart sshd
            echo "Restarting smbd service"
            sudo systemctl restart smbd
        fi

fi




