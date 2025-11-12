#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file installs the NEPI RUI File System installation

sudo -v

echo "########################"
echo "NEPI RUI Setup"
echo "########################"




SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



######################################dps#

NEPI_ARCH=unknown
if is_valid_jetson; then
    NEPI_ARCH=arm64
elif is_valid_arm64; then
    NEPI_ARCH=arm64
elif is_valid_amd64; then
    NEPI_ARCH=amd64
else
    arch_val=$(uname -m)
    echo "Arch ${arch_val} not supported yet"
    exit 1
fi

pyver=$(python3 --version | awk '{print $2}')
if [[ -n "$pyver" ]]; then
    pyver="${pyver%.*}"
else
    pyver=3
fi
NEPI_PYTHON=$pyver




#######################################
## Configure NEPI RUI Software

export CONFIG_USER=nepi
NEPI_BASE=/opt/nepi
NEPI_STORAGE=/mnt/nepi_storage


rui_source_path=${NEPI_STORAGE}/nepi_src/nepi_engine_ws/src/nepi_rui
rui_dest_path=${NEPI_BASE}/nepi_rui

if [[ ! -d "$rui_source_path" ]]; then
    echo "NEPI RUI Source folder not found at ${rui_source_path}"
    echo "Clone or Deploy nepi_engine_ws source code and try again"
else

    echo "Setting up NEPI RUI Folder ${rui_dest_path}"

    if [[ ! -d "$NEPI_BASE" ]]; then
        sudo mkdir -p $NEPI_BASE
    fi
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $NEPI_BASE

    if [[ ! -d "$rui_dest_path" ]]; then
        sudo mkdir -p $rui_dest_path
    fi
    sudo chown ${CONFIG_USER}:${CONFIG_USER} $rui_dest_path

    sudo rsync -arp ${rui_source_path} ${NEPI_BASE}
    printf "\n${HIGHLIGHT}*** NEPI RUI Deploy Finished ***\n"


    if [[ -d "${rui_dest_path}/.nvmrc" ]]; then
        sudo rm -r ${rui_dest_path}/.nvmrc
    fi
    sudo echo 14.1.0 >> ${rui_dest_path}/.nvmrc

    #sudo chown -R ${NEPI_USER}:${NEPI_USER} ${rui_dest_path}

    sudo python${NEPI_PYTHON} -m pip install --user virtualenv

    if [[ ! -d "/home/nepi/.nvm" ]]; then
        sudo mkdir /home/nepi/.nvm
    fi
    sudo chown -R nepi:nepi /home/nepi/.nvm
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
    #curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    wait

    export NVM_DIR="/home/nepi/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    source ~/.bashrc
    nvm install 14.1.0
    nvm use 14.1.0
    
    cd ${rui_dest_path}
    python${NEPI_PYTHON} -m virtualenv venv
    source devenv.sh
        python${NEPI_PYTHON} -m pip install -r requirements.txt
        cd ${rui_dest_path}/src/rui_webserver/rui-app
        npm install # Intalls packages from package.json in folders
        npm install -g yarn
        npm install --save rtsp-relay express
        npm install --save react-app-rewired
        npm install --save react-zoom-pan-pinch
        npm install --save ffmpeg-kit-react-native   
        
        #npm run build
    deactivate


    # # Build RUI
    # cd ${rui_dest_path}
    # source ./devenv.sh
    # cd src/rui_webserver/rui-app
    # npm run build
    # deactivate

    #########################################
    # Enable NEPI RUI Service

    systemctl&> /dev/null
    if [[ "$?" -eq 0 ]]; then
            #########################################
            # Setup NEPI Engine services
            #########################################
            echo ""
            echo "Enabling NEPI RUI Service"

            sudo systemctl enable nepi_rui
    fi


fi
##############################
echo "NEPI RUI Setup Complete"
##############################


# # Run RUI
# #sudo ${rui_dest_path}/etc/start_rui.sh
# #rosrun nepi_rui run_webserver.py
