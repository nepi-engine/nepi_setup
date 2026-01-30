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
SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


# This file sets up the ROS package 

sudo -v

sudo apt-get install iputils-ping -y
wait

export CONFIG_USER=$(id -un)


SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE



if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
else

    ######################################


    echo "########################"
    echo "NEPI ROS SETUP"
    echo "########################"


    #########################################

    # UPDATE NEPI Python Vesion
    pyver=$(python3 --version | awk '{print $2}')
    if [[ -n "$pyver" ]]; then
        pyver="${pyver%.*}"
    else
        pyver=3
    fi
    NEPI_PYTHON=$pyver




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

    NEPI_ROS=NOETIC

    echo ""
    echo "Installing ROS ${NEPI_ROS}"
    export ros_version="${NEPI_ROS,,}"


    if [[ "$ros_version" == 'noetic' ]]; then

        HAS_ROS=$(dpkg -l | grep ros-)
        if [[ ! -z "$HAS_ROS" ]]; then
            echo "ROS alread installed"
        else

            #######################################
            # Uninstall ROS if reinstalling/updating
            # sudo apt remove ros-noetic-*
            # sudo apt autoremove
            # After that, it's recommended to remove ROS-related environment variables from your .bashrc file 
            # and delete the ROS installation directory, typically 
            # sudo rm -r /opt/ros/*

            #  Install ros
            #  https://wiki.ros.org/noetic/Installation/Ubuntu

            cd $TMP
            sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
            sudo apt-get install curl -y # if you haven't already installed curl
            curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
            sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654
            sudo apt-get update --fix-missing
            ####################
            # Do if ROS not installed
            sudo apt-get install ros-noetic-desktop-full -y

        fi

        sudo apt update
        sudo apt --fix-broken install

        source /opt/ros/noetic/setup.bash
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< python3-rosdep"
        sudo apt-get install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
        sudo rosdep init
        sudo rosdep update

        #sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654
        sudo apt-get update --fix-missing
        
        # Then
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< ros-noetic-catkin"
        sudo apt-get install ros-noetic-catkin -y
        sudo python${NEPI_PYTHON} -m pip install git+https://github.com/catkin/catkin_tools.git


        #sudo apt-get update --fix-missing
        sudo apt update
        sudo apt --fix-broken install

        # If needed remove old packages if installed
        #sudo apt remove ros-noetic-cv-bridge -y
        #sudo apt remove ros-noetic-web-video-server -y
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< rosbridge-server "
        sudo apt install -y ros-${ros_version}-rosbridge-server 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< pcl-ros"
        sudo apt install -y ros-${ros_version}-pcl-ros 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< cv-bridge"
        sudo apt install -y ros-${ros_version}-cv-bridge 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< web-video-server"
        sudo apt install -y ros-${ros_version}-web-video-server 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< camera-info-manager"
        sudo apt install -y ros-${ros_version}-camera-info-manager 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< tf2-geometry-msgs"
        sudo apt install -y ros-${ros_version}-tf2-geometry-msgs 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< mavros"
        sudo apt install -y ros-${ros_version}-mavros 
        sudo apt install -y ros-${ros_version}-mavros ros-${ros_version}-mavros-extras ros-${ros_version}-mavros-msgs
        wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh
        sudo bash ./install_geographiclib_datasets.sh
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< mavros-extras"
        sudo apt install -y ros-${ros_version}-mavros-extras 
        echo "<<<<<<<<<<<<<<<<<<<<<<<<< serial"
        sudo apt install -y ros-${ros_version}-serial 

        sudo -H python${NEPI_PYTHON} -m pip install --no-input rospy_message_converter
        # Deprecated ROS packages?
        #sudo apt install -y ros-${ros_version}-tf-conversions
        #sudo apt install -y ros-${ros_version}-diagnostic-updater 
        #sudo apt install -y ros-${ros_version}-vision-msgs


        #########################################
        # Install Some Driver Libs
        #########################################
        export ros_version="${NEPI_ROS,,}"
        source /opt/ros/noetic/setup.bash

        sudo apt-get update --fix-missing
        sudo apt --fix-broken install
        

        # # Install Driver Support Libs
        cd $TMP
        sudo apt-get install -y ros-${ros_version}-nmea-navsat-driver
        sudo apt-get install -y ros-${ros_version}-microstrain-inertial-driver

        # Install PIX4 & Mavros
        # cd $TMP
        # echo "<<<<<<<<<<<<<<<<<<<<<<<<< PX4-Autopilot"
        # git clone https://github.com/PX4/PX4-Autopilot.git --recursive
        # bash ./PX4-Autopilot/Tools/setup/ubuntu.sh


        # echo "##################################"
        # echo ""
        # echo 'NEPI ROS Setup 1 Complete'
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

fi















