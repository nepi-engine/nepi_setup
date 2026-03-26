



# echo "Loading system config file...."
SYSTEM_FOLDER=/mnt/nepi_config/system_cfg/etc
SYSTEM_CONFIG_FILE=${SYSTEM_FOLDER}/nepi_system_config.yaml
SYSTEM_CONFIG_LOAD_FILE=${SYSTEM_FOLDER}/load_system_config.sh

if [[ ! -f "$SYSTEM_CONFIG_LOAD_FILE" ]]; then
    echo "Docker Config Load file not found at: ${SYSTEM_CONFIG_LOAD_FILE}"
    echo "Run 'nepiupdate' and try again"
elif [[ -z "$1" ]]; then
    source ${SYSTEM_CONFIG_LOAD_FILE}
    if [[ "$NEPI_INSTALL" != "FULL" && "$NEPI_INSTALL" != "LITE" || "$?" -eq 1 ]]; then
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
    else
        #echo "NEPI installing in ${NEPI_INSTALL} mode from ${SYSTEM_CONFIG_FILE}"
        if [[ "$NEPI_INSTALL" == "FULL" ]]; then
            # echo "Installing in FULL mode"
            LITE_INSTALL=0
            export NEPI_INSTALL="FULL"
            update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE

        elif [[ "$NEPI_INSTALL" == "LITE" ]]; then
            # echo "Installing in LITE mode"
            LITE_INSTALL=1
            export NEPI_INSTALL="LITE"
            update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
        fi
    fi
elif [[ "$1" -eq 0 ]]; then
    export NEPI_INSTALL="FULL"
    update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
elif [[ "$1" -eq 1 ]]; then
    export NEPI_INSTALL="LITE"
    update_yaml_value "NEPI_INSTALL" $NEPI_INSTALL $SYSTEM_CONFIG_FILE
fi

if [[ "$LITE_INSTALL" -eq 0 ]]; then
    echo "Running in setup mode: FULL"
elif [[ "$LITE_INSTALL" -eq 1 ]]; then
    echo "Running in setup mode: LITE"
fi