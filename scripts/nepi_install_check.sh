

LITE_INSTALL_START=$1

NEPI_INSTALL_START=$NEPI_INSTALL

# echo ""
# echo "**********"
# echo "Install Check Started with ${LITE_INSTALL_START},${NEPI_INSTALL}"

# echo "Loading system config file...."
SYSTEM_FOLDER=/mnt/nepi_config/system_cfg/etc
SYSTEM_CONFIG_FILE=${SYSTEM_FOLDER}/nepi_system_config.yaml
SYSTEM_CONFIG_LOAD_FILE=${SYSTEM_FOLDER}/load_system_config.sh

if [[ ! -f $SYSTEM_CONFIG_FILE ]]; then
    echo ""
    echo "Updating NEPI Config Folders"
    SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
    SOURCE_PATH=$(dirname "${SCRIPT_FOLDER}")/resources/etc
    UPDATE_PATH=$SYSTEM_FOLDER
    
    if [[ ! -d $SYSTEM_FOLDER ]]; then
    	sudo mkdir -p $SYSTEM_FOLDER
    	sudo chown ${CONFIG_USER}:${CONFIG_USER} $SYSTEM_FOLDER
    fi


    find $UPDATE_PATH -mindepth 1 -maxdepth 1 -type d -exec sudo rm -rf {} +
    echo "Syncing files from ${SOURCE_PATH} to ${UPDATE_PATH}"
    sudo rsync -ar ${SOURCE_PATH}/ ${UPDATE_PATH}/

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${SOURCE_PATH}
    sudo chmod 775 ${SOURCE_PATH}

    sudo chown ${CONFIG_USER}:${CONFIG_USER} ${UPDATE_PATH}
    sudo chmod 775 ${UPDATE_PATH}

fi

if [[ -z $LITE_INSTALL_START ]]; then
    source ${SYSTEM_CONFIG_LOAD_FILE}
    if [[ "$?" -eq 1 ]]; then
        echo "Failed to Load NEPI System Config file ${SYSTEM_CONFIG_FILE}"
    fi
    NEPI_INSTALL_START=$NEPI_INSTALL
    #echo "Install Check Updated with ${LITE_INSTALL},${NEPI_INSTALL}"
    if [[ ("$NEPI_INSTALL" != "FULL" && "$NEPI_INSTALL" != "LITE") ]]; then
        
        echo "Select Install Option:"
        options=("FULL" "LITE")
        select opt in "${options[@]}"; do
            case $opt in
                "FULL")
                    # echo "Installing in FULL mode"
                    LITE_INSTALL=0
                    export NEPI_INSTALL="FULL"
                    break
                    ;;
                "LITE")
                    # echo "Installing in LITE mode"
                    LITE_INSTALL=1
                    export NEPI_INSTALL="LITE"
                    break
                    ;;
                *)
                    echo "Invalid option, try agian"
                    ;;
            esac
        done
    fi

fi

if [[ "$NEPI_INSTALL" == "FULL" ]]; then
    LITE_INSTALL=0
elif [[ "$NEPI_INSTALL" == "LITE" ]]; then
    LITE_INSTALL=1
fi

if [[ -z $LITE_INSTALL ]]; then
    echo "Defaulting to NEPI_INSTALL: LITE"
    LITE_INSTALL=1
fi

export LITE_INSTALL=$LITE_INSTALL

if [[ "$LITE_INSTALL" -eq 0 ]]; then
    export NEPI_INSTALL="FULL"
    update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
    echo "Running in install mode: FULL"
elif [[ "$LITE_INSTALL" -eq 1 ]]; then
    export NEPI_INSTALL="LITE"
    update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
    echo "Running in install mode: LITE"
fi

source ${SYSTEM_CONFIG_LOAD_FILE}

# echo "Install Check Ending with ${LITE_INSTALL},${NEPI_INSTALL}"
# echo "**********"
# echo ""


