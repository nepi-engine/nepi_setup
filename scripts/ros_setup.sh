#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##


# This file sets up the ROS package 

sudo -v

# sudo apt
# sudo apt install iputils-ping -y
# wait

export CONFIG_USER=$(id -un 1000)

if [[ "$CONFIG_USER" != 'nepi' ]]; then
   echo "Current user is ${CONFIG_USER}. This scripts must be run as nepi user."
   exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE




echo "########################"
echo "NEPI ROS SETUP"
echo "########################"


NEPI_ROS=NOETIC


# UPDATE NEPI Python Vesion
pyver=$(python3 --version | awk '{print $2}')
if [[ -n "$pyver" ]]; then
    pyver="${pyver%.*}"
else
    pyver=3
fi
NEPI_PYTHON=$pyver



echo ""
echo "Installing ROS ${NEPI_ROS}"

# Create and change to tmp install folder

TMP=/mnt/nepi_storage/tmp
fix_folder $TMP
cd $TMP


echo ""
echo "Fixing installs"
#find /var/lib/apt/lists -type f  |xargs rm -f >/dev/null \
# sudo apt-get update --fix-missing && sudo apt-get upgrade
# sudo dpkg --configure -a
# sudo apt-get clean
# sudo apt-get autoremove
sudo apt-get update
sudo apt --fix-broken install
echo ""

############################################
## Setup ROS
############################################
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


fi













