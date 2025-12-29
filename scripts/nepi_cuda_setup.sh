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

# This file configigues an installed NEPI File System

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
LICENSE_CHECK_FILE=${SCRIPT_FOLDER}/nepi_license_check.sh
source $LICENSE_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    exit 1
fi

CONFIG_USER=$(id -un)
if [[ ${CONFIG_USER} == 'root' ]]; then
    CONFIG_USER=$SUDO_USER
fi

if [[ "$CONFIG_USER" != 'nepi' ]]; then
    echo "Current user is ${CONFIG_USER}. This script must be run by user 'nepi'"
    exit 1
fi

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    exit 1
fi


echo "########################"
echo "NEPI CUDA SETUP"
echo "########################"

# Load System Config File
source $(dirname $(pwd))/config/load_system_config.sh
if [ $? -eq 1 ]; then
    echo "Failed to load ${SYSTEM_CONFIG_FILE}"
    exit 1
fi

#***************************************


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



nepistop


TMP=/mnt/nepi_storage/tmp

####################################
# Create USER python folder
mkdir -p ${HOME}/.local/lib/python${NEPI_PYTHON}/site-packages
####################################




####################################
# Unistall existing packages
####################################
#echo "Will uninstall existing packages if exist"

## NOTE:If you have CV2 installed and have issues, find and rename folder before running
# sudo python${NEPI_PYTHON} -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"
# sudo python${NEPI_PYTHON} -c "import inspect; import cv2; print(inspect.getfile(cv2))"
# sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input opencv-python
# sudo python${NEPI_PYTHON} -m pip uninstall opencv-python
# sudo apt-get purge -y '*opencv*'
# sudo rm -r /usr/local/lib/python3.8/dist-packages/cv2
# sudo rm -r /usr/lib/python3.8/dist-packages/cv2
# sudo rm -r /usr/local/include/opencv2 /usr/local/include/opencv 
# sudo rm -r /usr/include/opencv /usr/include/opencv2 
# sudo rm -r /usr/local/share/opencv /usr/local/share/OpenCV /usr/share/opencv /usr/share/OpenCV 
# sudo rm -r /usr/local/bin/opencv* /usr/local/lib/libopencv*





## Find missing deb files in
##https://repo.download.nvidia.com/jetson/
# find /var/lib/apt/lists -type f  |xargs rm -f >/dev/null 
# sudo dpkg --configure -a
# sudo apt-get clean
# sudo apt-get autoremove
# sudo apt-get update --fix-missing && sudo apt-get upgrade
# sudo apt-get update
# sudo apt --fix-broken install
# sudo py3clean .



# sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input open3d
# sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input tourch
# sudo -H python${NEPI_PYTHON} -m pip uninstall --no-input tourchvision


####################################
# Install Required Libriaries
####################################
sudo apt update
sudo apt install -y build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
sudo apt install -y libv4l-dev v4l-utils qv4l2 #v4l2ucp    
sudo apt install -y libopenblas-base libopenmpi-dev libomp-dev 



# Find missing deb files in
#https://repo.download.nvidia.com/jetson/
find /var/lib/apt/lists -type f  |xargs rm -f >/dev/null 
sudo dpkg --configure -a
sudo apt-get clean
sudo apt-get autoremove
sudo apt-get update --fix-missing && sudo apt-get upgrade -y
sudo apt-get update
sudo apt --fix-broken install
sudo py3clean .

#########################################################
# MAYBE Upgrade Cuda Version
########################################################

MIN_CUDA_VERSION=118

function get_cuda_version(){
    lspci | grep -i nvidia >/dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
          cuda_version=0
          cuda_path=/usr/local
          declare -a files
          for file in "$cuda_path"/*; do
              if [[ -d "$file" && "$file" == *cuda-* ]]; then # Check if the item is a regular file
                  cuda_version=${file##*-}
              fi
          done
          echo $cuda_version
        fi
    else
        echo 0
        return 1
    fi
}

cuda_version=$(get_cuda_version)
cuda_version="${cuda_version//./}"
if [[ "$cuda_version" -lt $MIN_CUDA_VERSION ]]; then
    echo "######################################"
    echo "Installing Cuda ${MIN_CUDA_VERSION}"
    echo "######################################"
    cd $TMP


    #https://forums.developer.nvidia.com/t/jetson-agx-orin-jetpack-5-1-and-cuda-upgrade-from-11-4-to-11-8-failed-need-a-bit-of-help/270185
    apt-get install cuda-toolkit-11-8


    #############################
    echo ""
    echo "Updating Bash Variables"

    sed -i 's/cuda-11.4/cuda_11.8/g' /home/${CONFIG_USER}/.bashrc

    cat /home/${CONFIG_USER}/.bashrc

    # Source nepi aliases before exit
    echo " "
    echo "Sourcing bashrc with CUDA SETUP"
    sleep 1 & source /home/nepihost/.bashrc
    wait

    sudo update-alternatives --config cuda-11


fi



#################################
# Install cupy-cuda
##################################
echo 'Installing cupy'

CUDA_ARCH=11
#sudo -H python${NEPI_PYTHON} -m pip install -upgrade cython
sudo -H python${NEPI_PYTHON} -m pip install cupy-cuda${CUDA_ARCH}x



#################################
# Install open3d with cuda support
##################################
echo 'Installing Open3d with Cuda Support'


cd $TMP
git clone --recursive https://github.com/intel-isl/Open3D
cd Open3D
git submodule update --init --recursive
util/install_deps_ubuntu.sh


#b)Edit the CMakeLists.txt 

# Open3D build options
vi CMakeLists.txt

option(BUILD_SHARED_LIBS          "Build shared libraries"                   ON )
option(BUILD_EXAMPLES             "Build Open3D examples programs"           ON )
option(BUILD_UNIT_TESTS           "Build Open3D unit tests"                  OFF)
option(BUILD_BENCHMARKS           "Build the micro benchmarks"               OFF)
option(BUILD_PYTHON_MODULE        "Build the python module"                  ON )
option(BUILD_CUDA_MODULE          "Build the CUDA module"                    ON )
option(BUILD_WITH_CUDA_STATIC     "Build with static CUDA libraries"         ON )


line 328. Change "find_package(Python3 3.6" line to
find_package(Python3 3.8 EXACT COMPONENTS


#d) Build Open3D cpp and python modules

cd /mnt/nepi_storage/tmp/Open3D
mkdir build
cd build


##f) For headless rendering, remake with the following options. Takes about 30min to rebuild.
sudo CUDACXX=/usr/local/cuda-11.8/bin/nvcc cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_CUDA_MODULE=ON \
    -DBUILD_GUI=OFF \
    -DENABLE_HEADLESS_RENDERING=ON \
    -DUSE_SYSTEM_GLEW=OFF \
    -DUSE_SYSTEM_GLFW=OFF \
    -DBUILD_TENSORFLOW_OPS=OFF \
    -DBUILD_PYTORCH_OPS=OFF \
    -DBUILD_UNIT_TESTS=OFF \
    -DPYTHON_EXECUTABLE=$(which python) \
    ..

sudo make -j$(nproc)

sudo make install

# Install Open3D python package (optional)
sudo make install-pip-package -j$(nproc)


# OR************

# sudo CUDACXX=/usr/local/cuda-11/bin/nvcc cmake \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DBUILD_SHARED_LIBS=ON \
#     -DBUILD_CUDA_MODULE=ON \
#     -DBUILD_GUI=ON \
#     -DBUILD_TENSORFLOW_OPS=OFF \
#     -DBUILD_PYTORCH_OPS=OFF \
#     -DBUILD_UNIT_TESTS=OFF \
#     -DPYTHON_EXECUTABLE=$(which python) \
#     ..

# sudo make -j$(nproc)

# *******************

# sudo make install

# # Install Open3D python package (optional)
# sudo make install-pip-package -j$(nproc)


# e) test the install. Run Open3D GUI (optional, available on when -DBUILD_GUI=ON)
# ./Open3D/Open3D



# c) First install the new cuda open3d package
# # You will get an error on this step. Ignore it

# cd /mnt/nepi_storage/tmp/Open3D/build/lib/python_package/pip_package/
# pip install open3d-0.18.0+84b8e071e-cp38-cp38-manylinux_2_31_aarch64.whl --ignore-installedpyt
# sudo pip install open3d-0.18.0+84b8e071e-cp38-cp38-manylinux_2_31_aarch64.whl --ignore-installed

# # Check installed open3d module version

# pip freeze | grep open3d

# d) Next install standard open3d-cpu without overwriting the cuda version to fix python import error
# # You will get an error on this step. Ignore it

# pip install open3d --ignore-installed
# sudo pip install open3d --ignore-installed

# # Check installed open3d module version still the cuda version from step b

# pip freeze | grep open3d

# pip install setuptools==45.2.0
# sudo pip install setuptools==45.2.0



#e) check python open3d module import

sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"


# ############################################
# # Install cv2 with cuda support
# ############################################


# Run CMake with CUDA flags and other desired options. Adjust CUDA_ARCH_BIN to match your gpu architecture 
# _ OPTIONS
#Jetson ORIN 8.7
#Jetson XAVIER 7.2
#Jetson TX2	6.2
#Jetson NANO 5.3

CUDA_ARCH_BIN=8.7

# declare -A cuda_archs
# cuda_archs["ORIN"]=8.7
# cuda_archs["XAVIER"]=7.2
# cuda_archs["TX2"]=6.2
# cuda_archs["NANO"]=5.3

# # Iterate through the dictionary to find a match
# for key in "${!cuda_archs[@]}"; do
#   if [[ "$key" == "$NEPI_HW_MODEL" ]]; then
#     CUDA_ARCH_BIN="${cuda_archs[$key]}"
#     break # Exit the loop once a match is found
#   fi
# done




# echo 'Installing CV2 with Cuda support'
# cd $TMP
# #############
# ### TO DO: DOWNLOAD and INSTALL From NEPI PREMADE BUILD PACKAGE
# git clone https://github.com/opencv/opencv.git
# git clone https://github.com/opencv/opencv_contrib.git

# cd opencv
# git checkout 4.x
# cd ../opencv_contrib
# git checkout 4.x

# cd ../opencv
# mkdir build



# # https://stackoverflow.com/questions/42638342/cannot-install-opencv-3-1-0-with-python3-cmake-not-including-or-linking-python

# cmake -D CMAKE_BUILD_TYPE=Release \
#     -D ENABLE_CXX11=ON \
#     -D FFMPEG=ON \
#     -D CMAKE_INSTALL_PREFIX=/usr/local \
#     -D WITH_TBB=ON \
#     -D BUILD_NEW_PYTHON_SUPPORT=ON \
#     -D WITH_V4L=ON \
#     -D WITH_QT=ON \
#     -D WITH_OPENGL=ON \
#     -D WITH_GTK=ON \
#     -D WITH_GTK_2_X=ON \
#     -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
#     -D WITH_CUDA=ON \
#     -D WITH_CUDNN=ON \
#     -D OPENCV_DNN_CUDA=ON \
#     -D CUDA_ARCH_BIN="${CUDA_ARCH_BIN}" \
#     -D CUDA_ARCH_PTX="" \
#     -D OPENCV_GENERATE_PKGCONFIG=ON \
#     -D WITH_GSTREAMER=ON \
#     -D WITH_LIBV4L=ON \
#     -D BUILD_opencv_python3=ON \
#     -D BUILD_EXAMPLES=ON \
#     -D PYTHON3_EXECUTABLE=$(which python3) \
#     -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
#     -D PYTHON_INCLUDE_DIR2=$(python3 -c "from os.path import dirname; from distutils.sysconfig import get_config_h_filename; print(dirname(get_config_h_filename()))") \
#     -D PYTHON_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") \
#     -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") \
#     -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
#     -D BUILD_TESTS=OFF \
#     -D BUILD_PERF_TESTS=OFF \
#     -D BUILD_EXAMPLES=OFF \
#     ..

# make -j$(nproc)
# cd ./../..
# ###################

# # Install CV2 Build
# cd opencv/build
# sudo make install
# sudo ldconfig
# cd ./../..

# # echo "Updating bashrc file with CV2 SETUP"
# # BASHRC=${HOME}/.bashrc
# # if grep -qnw $BASHRC -e "##### CV2 SETUP #####" ; then
# #     echo "Done"
# # else
# #     echo " " | sudo tee -a $BASHRC
# #     echo "##### CV2 SETUP #####" | sudo tee -a $BASHRC
# #     #echo '/usr/lib/python3/dist-packages/cv2/python-3.10
# # fi
# # sudo cp $BASHRC /root/.bashrc


# ## Fix no python cv2 issue
# # https://github.com/opencv/opencv/issues/21359#issuecomment-1003005474
# # https://github.com/dusty-nv/jetson-containers/issues/237


# # Check if cuda support
# sudo python${NEPI_PYTHON} -c "import cv2; print(cv2.__version__);print(cv2.getBuildInformation())"





# ############################################
# # installed pytorch for jetson
# ############################################

# # uninstall old version if present
# sudo python${NEPI_PYTHON} -m pip uninstall torch
# sudo python -m pip uninstall torch







# Follow these instructions:
# https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform/index.html
# another reference
# https://medium.com/@yixiaozengprc/set-up-pytorch-environment-on-nvidia-jetson-platform-9eda291db716
# https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/index.html


# a. 
# sudo apt-get -y update
# sudo apt-get -y install python3-pip libopenblas-dev

# b. Setup Pytorch in NEPI device
# Go or create temp folder and install:
# cd /mnt/nepi_storage/tmp


# nvcc --version
# sudo apt-cache show nvidia-jetpack


# Dowload latest version for your jetpack version from
# Find pytorch version for jetpack version
# https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048
# another resource
# https://developer.download.nvidia.com/compute/redist/jp/

# Copy link address and 

# wget <link to whl file>
# export TORCH_INSTALL=<whl location>

# Ex
# 5.0.2
# wget https://developer.download.nvidia.com/compute/redist/jp/v502/pytorch/torch-1.13.0a0+d0d6b1f2.nv22.10-cp38-cp38-linux_aarch64.whl

# export TORCH_INSTALL=/mnt/nepi_storage/tmp/torch-1.13.0a0+d0d6b1f2.nv22.10-cp38-cp38-linux_aarch64.whl

# 5.1.2
# wget https://developer.download.nvidia.cn/compute/redist/jp/v512/pytorch/torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl

# export TORCH_INSTALL=/mnt/nepi_storage/tmp/torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl


# c. Setup Pytorch in NEPI device 3

# sudo python${NEPI_PYTHON} -m pip install --upgrade pip
# #sudo python${NEPI_PYTHON} -m install numpy=='1.24.4'
# sudo python${NEPI_PYTHON} -m pip install --no-cache $TORCH_INSTALL

# # test install
# sudo python${NEPI_PYTHON} -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"

# ############################################
# # install torchvision
# ############################################
# # Fix NEPI package versions

# # uninstall old version if present
# sudo python${NEPI_PYTHON} -m pip uninstall torchvision
# python3 -m pip uninstall torchvision

# python3 -m pip uninstall setuptools
# sudo python${NEPI_PYTHON} -m pip uninstall setuptools
# sudo python${NEPI_PYTHON} -m pip install setuptools==49.4.0
# sudo python${NEPI_PYTHON} -c "import setuptools; print(setuptools.__version__)"


# # uninstall old version if present
# sudo python${NEPI_PYTHON} -m pip uninstall typing
# python3 -m pip uninstall typing



# # Switch to CUDA 11.4 during install
# #MAYBE? Move cuda-11.8 folder somewhere during install
# CUDA_HOME=/usr/local/cuda-11.4
# export CUDA_PATH=${CUDA_HOME} 
# export CUDA_HOME=${CUDA_HOME} 
# export CUPY_NVCC_GENERATE_CODE=current
# export LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${CUDA_HOME}/targets/aarch64-linux/lib:$LD_LIBRARY_PATH
# export PATH=:${CUDA_HOME}/bin:${PATH}

# ####### Install Torchvision

# Installing Torchvision
# Instructions can be found https://forums.developer.nvidia.com/t/pytorch-forjetson/


# https://forums.developer.nvidia.com/t/how-to-install-torchvision-with-torch1-14-0-with-cuda-11-4/245657/2
# a. find compatable version to torch version https://pypi.org/project/torchvision/

# sudo python${NEPI_PYTHON} -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"

# NOTE: You can find the torch and torchvision compatibility matrix here:
# https://github.com/pytorch/vision 

# then look under "Tags" find version, then click the "tar.gz" file link

# b. download and install On your PC Download 
# Example:

# for torch 1.13
# wget https://github.com/pytorch/vision/archive/refs/tags/v0.14.0.tar.gz

# for torch 2.0
# wget https://github.com/pytorch/vision/archive/refs/tags/v0.16.2.tar.gz


# c. copy to your /mnt/nepi_storage/tmp/ folder and unzip 
# connect NEPI to internet

# sshn in

# sudo apt-get install libjpeg-dev zlib1g-dev libpython3-dev libopenblas-dev libavcodec-dev libavformat-dev libswscale-dev
# cd /mnt/nepi_storage/tmp/

# Example
# sudo chmod +x v0.14.0.tar.gz
# tar -xvzf v0.14.0.tar.gz
# sudo chown -R nepi:nepi vision-0.14.0
# cd vision-0.14.0
# export BUILD_VERSION=0.14.0
# sudo python${NEPI_PYTHON} setup.py install

# tar -xvzf vision-0.16.2.tar.gz
# sudo chown -R nepi:nepi vision-0.16.2
# cd vision-0.16.2
# export BUILD_VERSION=0.16.2
# sudo python${NEPI_PYTHON} setup.py install


# #Check Installed
# sudo python${NEPI_PYTHON} -c "import torchvision; print(torchvision.__version__)"


# rosstop
# rosstart # Look for errors

# sudo python3.8 -m pip install -U torch torchvision



# ###############################
# # Install ultralytics for yolov5 ai model support
# ###########################################
# 1) 
# then add this to bashrc
# vi ~/.bashrc

# export SETUPTOOLS_USE_DISTUTILS=stdlib

# #in nepi tmp folder
# ##git clone https://github.com/ultralytics/ultralytics.git
# ##cd ultralytics
# ##pip install -e '.[dev]'

# pip install -U ultralytics


# then reboot

# *** Must Do ***

# 2) May need to do twice
# power cycle

# rosstop
# rosstart

# connect nepi to internet
# connect camera

# Connect NEPI to internet and start a yolov5 model from RUI AI detector





##################################
# FIX SOME JETSON ISSUES
##################################
# Work-around opencv path installation issue on Jetson (after jetpack installation)
# https://github.com/jetsonhacks/buildLibrealsense2TX/issues/13

echo 'Fixing Some Jetson Issues'
sudo ln -s /usr/include/opencv4/opencv2/ /usr/include/opencv
sudo ln -s /usr/lib/aarch64-linux-gnu/cmake/opencv4 /usr/share/OpenCV



##################################
echo 'Cuda Software Support Complete'
##################################