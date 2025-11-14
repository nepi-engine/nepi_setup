#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up the OS software requirements for a NEPI File System installation

sudo -v

sudo apt-get install iputils-ping -y
wait

export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" != 'nepi' ]]; then
   echo "Current user is ${CONFIG_USER}. This scripts must be run as nepi user."
   exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
else


    ######################################

    echo ""
    echo "########################"
    echo "NEPI ENVIRONMENT SETUP 2"
    echo "########################"
    echo ""



    ####################################
    # Run NEPI Bash Setup Script


    script_file=nepi_bash_setup.sh
    script_path=${SCRIPT_FOLDER}/${script_file}
    if ! source_script $script_path; then
        script_error=$?
        echo "Script ${script_path} failed with error ${script_error}"
        exit 1
    fi


    ####################################
    # Run NEPI Folder Setup Script

    script_file=nepi_folders_setup.sh
    script_path=${SCRIPT_FOLDER}/${script_file}
    if ! source_script $script_path; then
        script_error=$?
        echo "Script ${script_path} failed with error ${script_error}"
        exit 1
    fi

    TMP=/mnt/nepi_storage/tmp
    fix_folder $TMP
    cd $TMP


    ##########################
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


    systemctl&> /dev/null
    if [[ "$?" -eq 0 ]]; then
        SYSTEMD_SERVICE_PATH=/etc/systemd/system

        echo ""
        echo "########"
        echo "Disable apport to avoid crash reports on a display"
        sudo systemctl disable apport
        sudo systemctl stop apport
    fi


    sudo apt update
    sudo apt-get install --fix-broken -y 

    #############################################



    echo ""
    echo "########################"
    echo "Configuring Python"
    echo "########################"
    echo ""




    #######################
    # To Updgrade from an existing python version
    #######################

    #create requirements file from current dev install then run both as normal and sudo user
    # https://stackoverflow.com/questions/31684375/automatically-create-file-requirements-txt
    # pip3 freeze > requirements.txt
    # sed 's/==.*$//' requirements.txt > requirements_no_versions.txt
    # then
    # Copy to /mnt/nepi_storage/tmp
    # ssh into tmp folder on nepi

    # Remove old pythons
    #sudo apt remove --purge python3.x
    #sudo rm -r /usr/bin/python*
    #sudo rm -r /usr/lib/python*
    #sudo apt autoremove

    # sudo apt install --reinstall ca-certificates -y
    # sudo apt install software-properties-common -y
    # sudo add-apt-repository ppa:deadsnakes/ppa -y 
    # sudo apt update
    # sudo apt install python${NEPI_PYTHON} -f -y 

    # # Install pip
    # sudo apt remove python-pip
    # sudo apt remove python3-pip
    # sudo cd /usr/local/bin
    # sudo rm pip*
    # for python 3.8
    # sudo apt install python3-pip -y

    #######################
    # # Make sure there is user local package



    # Create USER python folder
    mkdir -p $(python -m site --user-site)
    fix_path "/home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages"
    fix_path  /home/${CONFIG_USER}/.local/bin
    fix_folder /home/${CONFIG_USER}/.local
    sudo ln -sf /usr/bin/pip3 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages/pip





    # Install support packages
    sudo apt install python${NEPI_PYTHON}-distutils -y
    sudo apt install python${NEPI_PYTHON}-venv -y
    sudo apt install python${NEPI_PYTHON}-dev -y 

    sudo apt update
    sudo apt-get install --fix-broken -y 

    # Install and Configure pip
    #sudo python${NEPI_PYTHON} -m pip install --upgrade pip

    sudo ln -sfn /usr/bin/python${NEPI_PYTHON} /usr/bin/python3
    sudo ln -sfn /usr/bin/python3 /usr/bin/python

    sudo rm /usr/bin/pip
    sudo ln -s /usr/bin/pip3 /usr/bin/pip

    # Downgrade stetup tools
    # sudo -H python${NEPI_PYTHON} -m pip install --upgrade setuptools
    sudo -H python${NEPI_PYTHON} -m pip install --no-input setuptools==68.0.0




    echo ""
    echo "########################"
    echo "Installing Python Apps"
    echo "########################"
    echo ""

    #
    sudo -H python${NEPI_PYTHON} -m pip install --no-input python-debian
    sudo -H python${NEPI_PYTHON} -m pip install --no-input virtualenv

    #sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input wheel
    sudo -H python${NEPI_PYTHON} -m pip install --no-input wheel

    sudo -H python${NEPI_PYTHON} -m pip install --no-input scikit-build 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input ninja 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input cmake

    sudo -H python${NEPI_PYTHON} -m pip install --no-input numpy

    sudo -H python${NEPI_PYTHON} -m pip install --no-input cffi

    #sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input netifaces
    sudo -H python${NEPI_PYTHON} -m pip install --no-input netifaces

    sudo -H python${NEPI_PYTHON} -m pip install --no-input pyserial 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input websockets 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input geographiclib 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input PyGeodesy 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input harvesters 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input WSDiscovery 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input python-gnupg 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input pip install lxml

    sudo -H python${NEPI_PYTHON} -m pip install --no-input onvif_zeep
    sudo -H python${NEPI_PYTHON} -m pip install --no-input onvif 
    sudo -H python${NEPI_PYTHON} -m pip install --no-input PyUSB

    sudo -H python${NEPI_PYTHON} -m pip install --no-input licenseheaders


    sudo -H python${NEPI_PYTHON} -m pip install --no-input yapf

    sudo -H python${NEPI_PYTHON} -m pip install --no-input python-gnupg

    #sudo -H python${NEPI_PYTHON} -m pip install --upgrade --no-input tornado

    sudo -H python${NEPI_PYTHON} -m pip install --no-input Flask
    sudo -H python${NEPI_PYTHON} -m pip install --no-input supervisor 

    sudo -H python${NEPI_PYTHON} -m pip install --upgrade --no-input scipy


    #sudo -H python${NEPI_PYTHON} -m pip install --no-input yap
    #sudo -H python${NEPI_PYTHON} -m pip install --no-input labelImg # For onboard training



    #sudo -H python${NEPI_PYTHON} -m pip install --no-input jetson-stats

    #############
    # Other general python utilities


    echo ""
    echo "########################"
    echo "Installing Solution Applications"
    echo "########################"
    echo ""

    echo "####################################################"

    ##########################
    sudo python3 -c "import cv2; print('cv2 is installed, version:', cv2.__version__)" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Python cv2 (OpenCV) is installed."
        # Optionally, print the version:
        sudo python3 -c "import cv2; print('Version:', cv2.__version__)"
    else
        echo "Python cv2 (OpenCV) is NOT installed. Will install"
        sudo python${NEPI_PYTHON} -m pip install --no-input opencv-python
    fi

    sudo python3 -c "import torch; print('torch is installed, version:', torch.__version__)" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Python torch is installed."
        # Optionally, print the version:
        sudo python3 -c "import torch; print('Version:', torch.__version__)"
    else
        echo "Python torch is NOT installed. Will install"
        sudo python${NEPI_PYTHON} -m pip install --no-input torch
    fi


    sudo python3 -c "import torchvision; print('torchvision is installed, version:', torchvision.__version__)" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Python torchvision is installed."
        # Optionally, print the version:
        python3 -c "import torchvision; print('Version:', torchvision.__version__)"
    else
        echo "Python torchvision is NOT installed. Will install"
        sudo python${NEPI_PYTHON} -m pip install --no-input torchvision
    fi

    sudo python3 -c "import open3d; print('open3d is installed, version:', open3d.__version__)" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Python open3d is installed."
        # Optionally, print the version:
        sudo python3 -c "import open3d; print('Version:', open3d.__version__)"
    else
        echo "Python open3d is NOT installed. Will install"
        sudo python${NEPI_PYTHON} -m pip install --no-input open3d #--ignore-installed
    fi



    #https://github.com/ultralytics/ultralytics/issues/21015
    #sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input ultralytics
    # sudo pip install git+https://github.com/ultralytics/ultralytics.git@main

    #sudo python${NEPI_PYTHON} -m pip install ultralytics

    #############
    # # Install additional python requirements
    # # Copy the requirements files from nepi_engine/nepi_env/setup to /mnt/nepi_storage/tmp
    # NEPI_REQ_SOURCE=$(dirname "$(pwd)")/resources/requirements
    # sudo cp ${NEPI_REQ_SOURCE}/nepi_requirements.txt ./
    # cat nepi_requirements.txt | sed -e '/^\s*#.*$/d' -e '/^\s*$/d' | xargs -n 1 sudo python${NEPI_PYTHON} -m pip install




    # echo "##################################"
    # echo ""
    # echo 'NEPI Environment Setup 1 Complete'
    # echo "##################################"
    # echo ""
    # echo ""
    # echo "##################################"
    # echo "Chcking for CUDA support on python installs"
    # echo ""
    # sudo python3 -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"
    # echo ""
    # echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    # echo ""
    # sudo python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
    # echo ""
    # echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    # echo ""
    # sudo python3 -c "import torchvision; print(torchvision.__version__)"
    # echo ""
    # echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    # echo ""
    # sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
    # echo ""
    # echo ""
    # echo "##################################"
    # echo "If CUDA support required for any of these packages,"
    # echo " and not supported in current configurations shown above,"
    # echo "install CUDA supported version manaully"

fi