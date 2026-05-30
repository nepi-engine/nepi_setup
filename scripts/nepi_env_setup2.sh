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


   



    # Uninstall Problem Packages
    sudo python${NEPI_PYTHON} -m pip uninstall typing

    sudo python3 -m pip uninstall --upgrade torch
    sudo python3 -m pip uninstall --upgrade torchvision
    sudo python3 -m pip install --upgrade pip
    sudo python3 -m pip install --ignore-installed ultralytics


    if is_valid_rpi; then
        cur_dir=$(pwd)
        sudo update-pciids
        HAILO_SW_VERSION=$(get_hailo_installed_version)
        if [[ "$HAILO_SW_VERSION" != '0' ]]; then
            echo ""
            echo "######################################"
            echo "Installing hailort Version ${HAILO_SW_VERSION} "
            echo "######################################"
            echo ""

            sudo apt install  dkms libglib2.0-0 ffmpeg x11-utils bison flex libelf-dev \
            libgstreamer-plugins-base1.0-dev python-gi-dev libgirepository1.0-dev libzmq3-dev gcc-9 g++-9 \
            libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev \
            gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x \
            gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio \
            python3-gi python3-gi-cairo gir1.2-gtk-3.0 -y

            cur_folder=$(pwd)
            if [[ ! -d "${NEPI_STORAGE}/tmp" ]]; then
                sudo mkdir - p "${NEPI_STORAGE}/tmp"
                
            fi
            if [[ -d "${NEPI_STORAGE}/tmp" ]]; then
                sudo chown ${CONFIG_USER}:${CONFIG_USER} "${NEPI_STORAGE}/tmp"
                cd "${NEPI_STORAGE}/tmp"
            else
                cd "/home/${CONFIG_USER}"
                mkdir tmp
                cd tmp
            fi
            
            hailo_version=
            hailo_link="https://github.com/hailo-ai/hailort/archive/refs/tags/v${HAILO_SW_VERSION}.zip"
            hailo_folder="hailort-${HAILO_SW_VERSION}"
            hailo_zip="hailort.zip"

            if [[ -f ${hailo_zip} ]]; then
                sudo rm -r $hailo_zip
            fi
            if [[ ! -f ${hailo_zip} ]]; then
                sudo wget ${hailo_link} -O ${hailo_zip}
                if [[ "$?" -ne 0 ]]; then
                    echo ""
                    echo "Failed to download from link: ${hailo_link}"
                    echo ""
                    sudo rm ${hailo_zip}
                fi
            else
                sudo chown ${CONFIG_USER}:${CONFIG_USER} $hailo_zip
            fi

            if [[ -f ${hailo_zip} ]]; then
                echo ""
                echo "Unzipping file ${hailo_zip}"
                echo ""
                sudo unzip -o -q $hailo_zip
                if [ $? -eq 0 ]; then
                    #sudo rm ${hailo_zip} > /dev/null 2>&1
                    success_storage=1
                else
                    echo ""
                    echo "Failed to unzip file: ${hailo_zip}"
                    echo ""
                    #sudo rm ${hailo_zip} > /dev/null 2>&1
                fi
            else
                echo ""
                echo "Failed to find file: ${hailo_zip}"
                echo ""
            fi

            if [[ -f ${hailo_zip} ]]; then
                sudo rm ${hailo_zip} > /dev/null 2>&1
            fi

            if [[ -d $hailo_folder && -n $hailo_folder ]]; then
                sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $hailo_folder
                cd $hailo_folder
                mkdir build
                cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DHAILO_BUILD_EXAMPLES=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5  && sudo cmake --build build --config release --target install

                # Build pyHailoRT
                cd $hailo_folder
                python3 -m venv hailo_venv
                source hailo_venv/bin/activate

                pip install --upgrade pip setuptools wheel

                cd hailort/libhailort/bindings/python/platform/
                sudo apt update
                sudo apt install build-essential gcc g++ ccache

                ### Update cmake_args in setup.py line 81 to
                # cmake_args = [
                #     f"-B{build_dir}",
                #     f"-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                #     f"-DCMAKE_BUILD_TYPE={_build_type}",
                #     f"-DCMAKE_LIBRARY_OUTPUT_DIRECTORY={build_dir}",
                #     f'-DPYBIND11_PYTHON_VERSION="{python_version}"',
                # ]

                export CC=/usr/bin/gcc
                export CXX=/usr/bin/g++
                python3 setup.py bdist_wheel --plat-name=linux_aarch64

                deactivate
            fi

            
            if hailortcli fw-control identify; then




                    # if is_valid_halio_sw; then
                    #     echo ""
                    #     echo "######################################"
                    #     echo "Installing HAILO Apps "
                    #     echo "######################################"
                    #     echo ""
                    #     cur_dir=$(pwd)
                    #     nepihome
                    #     if [[ -d 'hailo-rpi5-examples' ]]; then
                    #         git clone https://github.com/hailo-ai/hailo-rpi5-examples.git
                    #         cd hailo-rpi5-examples

                    #     fi
                    #     cd $cur_dir
                    # fi
            fi
        fi
        cd $cur_dir
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