

LITE_INSTALL=$1

# echo "Loading system config file...."
SYSTEM_FOLDER=/mnt/nepi_config/system_cfg/etc
SYSTEM_CONFIG_FILE=${SYSTEM_FOLDER}/nepi_system_config.yaml
SYSTEM_CONFIG_LOAD_FILE=${SYSTEM_FOLDER}/load_system_config.sh

if [[ -z $LITE_INSTALL ]]; then
    source ${SYSTEM_CONFIG_LOAD_FILE}
    if [[ ("$NEPI_INSTALL" != "FULL" && "$NEPI_INSTALL" != "LITE") || "$?" -eq 1 ]]; then
        echo "Failed to find NEPI install option at ${SYSTEM_CONFIG_FILE}"
        echo "Select Install Option:"
        options=("FULL" "LITE")
        select opt in "${options[@]}"; do
            case $opt in
                "FULL")
                    # echo "Installing in FULL mode"
                    LITE_INSTALL=0
                    export NEPI_INSTALL="FULL"
                    update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
                    break
                    ;;
                "LITE")
                    # echo "Installing in LITE mode"
                    LITE_INSTALL=1
                    export NEPI_INSTALL="LITE"
                    update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
                    break
                    ;;
                *)
                    echo "Invalid option, try agian"
                    ;;
            esac
        done
    elif [[ "$NEPI_INSTALL" == "FULL" ]]; then
        LITE_INSTALL=0
    elif [[ "$NEPI_INSTALL" == "LITE" ]]; then
        LITE_INSTALL=1
    fi

fi

if [[ -z $LITE_INSTALL ]]; then
    echo "Defaulting to NEPI_INSTALL: LITE"
    LITE_INSTALL=1
fi

export LITE_INSTALL=$LITE_INSTALL

if [[ "$LITE_INSTALL" -eq 0 ]]; then
    echo "Running in install mode: FULL"
elif [[ "$LITE_INSTALL" -eq 1 ]]; then
    echo "Running in install mode: LITE"
fi

if [[ -f "$SYSTEM_CONFIG_LOAD_FILE" ]]; then
    #echo "NEPI installing in ${NEPI_INSTALL} mode from ${SYSTEM_CONFIG_FILE}"
    if [[ $LITE_INSTALL -eq 0 ]]; then
        export NEPI_INSTALL="FULL"
        update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
    else
        export NEPI_INSTALL="LITE"
        update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
    fi
fi


