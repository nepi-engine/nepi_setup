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

sudo -v


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
USER_CHECK_FILE=${SCRIPT_FOLDER}/nepi_user_check.sh
source $USER_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
echo "Script Folder: ${SCRIPT_FOLDER}"
RESOURCES_FOLDER=$(dirname ${SCRIPT_FOLDER})/resources

NEPI_UTILS_SOURCE=${RESOURCES_FOLDER}/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE

# Load System Config File
#echo "Loading NEPI SYSTEM CONFIG"
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

sudo apt-get install iputils-ping -y
wait


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
        return 
    fi


    ####################################
    # Run NEPI Folder Setup Script

    script_file=nepi_folders_setup.sh
    script_path=${SCRIPT_FOLDER}/${script_file}
    if ! source_script $script_path; then
        script_error=$?
        echo "Script ${script_path} failed with error ${script_error}"
        return 
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
        return 
    fi





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
    
    REQUIRED_VERSION=3.8.10
    
    # sudo apt install python3.8 -y


    pyver=$(python3 --version | awk '{print $2}')



    if [[ $pyver != $REQUIRED_VERSION ]]; then 
       echo "Incorrect Python version"
       echo "Current version: ${pyver}"
       echo "Required version ${REQUIRED_VERSION}"
       return 1
    else 
        echo "Correct Python version"
    fi

    #######################
    # # Make sure there is user local package
    NEPI_PYTHON=3.8
    sudo apt update
    sudo apt install software-properties-common -y
    sudo apt install --reinstall ca-certificates -y
    sudo add-apt-repository ppa:deadsnakes/ppa -y 
    sudo apt update

    # Create USER python folder
    mkdir -p $(python -m site --user-site)
    NEPI_PYTHON=3.8
    fix_path "/home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages" 755
    fix_path /home/${CONFIG_USER}/.local/bin 755
    fix_folder /home/${CONFIG_USER}/.local 755
    sudo chown -R nepi:nepi /home/nepi/.local
    sudo chmod -R u+rwX /home/nepi/.local
    sudo ln -sf /usr/bin/pip3 /home/${CONFIG_USER}/.local/lib/python${NEPI_PYTHON}/site-packages/pip


    # Install support packages
    sudo apt install python${NEPI_PYTHON}-distutils -y
    sudo apt install python${NEPI_PYTHON}-venv -y
    sudo apt install python${NEPI_PYTHON}-dev -y 
    ####

    sudo apt update
    sudo apt install python3-pip -y
    # pip3 --version



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
    python${NEPI_PYTHON} -m pip uninstall numpy
    sudo -H python${NEPI_PYTHON} -m pip install --force-reinstall --no-input numpy==1.23.5

    sudo -H python${NEPI_PYTHON} -m pip install --no-input python-debian \
        virtualenv wheel  scikit-build ninja cmake cryptography \
        python-dotenv cffi netifaces pyserial websockets \
        geographiclib PyGeodesy harvesters WSDiscovery python-gnupg \
        lxml onvif_zeep PyUSB usb PyYAML declxml licenseheaders \
        yapf python-gnupg Flask supervisor  colormath pandas scipy \
        empty
    
    sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input typing -y

    #sudo -H python${NEPI_PYTHON} -m pip install --no-input yap
    #sudo -H python${NEPI_PYTHON} -m pip install --no-input labelImg # For onboard training

    if is_valid_jetson; then
        sudo -H python${NEPI_PYTHON} -m pip install --no-input jetson-stats
    fi

    #############
    # Other general python utilities

    ########################
    ## Remove issue packackes
    sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input typing -y


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
        sudo python${NEPI_PYTHON} -m pip install --upgrade traitlets
        sudo python${NEPI_PYTHON} -m pip install --upgrade packaging
        sudo python${NEPI_PYTHON} -m pip install --upgrade ipython
        sudo pip install jupyter-client==6.1.7
        sudo python${NEPI_PYTHON} -m pip install --no-input open3d --ignore-installed
    fi


    # Uninstall Problem Packages
    sudo python${NEPI_PYTHON} -m pip uninstall typing

    sudo python${NEPI_PYTHON} -m pip install ultralytics



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



    #################
    np_required=1.23.5
    np_version=$(python -c "import numpy; print(numpy.__version__)") 
    if [[ ${np_version//./} != ${np_required//./} ]]; then
        python${NEPI_PYTHON} -m pip uninstall numpy
        sudo -H python${NEPI_PYTHON} -m pip uninstall numpy
        sudo rm -r /usr/lib/python3/dist-packages/numpy
        sudo -H python${NEPI_PYTHON} -m pip install --force-reinstall --no-input numpy==${np_required}
        python -c "import numpy; print(numpy.__version__)"
        sudo dpkg --configure -a
    fi

    # which python # (or where python on Windows) to see the executable path
    # python -c "import numpy; print(numpy.__version__)"
    # python -c "import numpy; print(numpy.__file__)"
    # python -c "import sys; print(sys.path)" # to see the search path for modules




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