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
    return 
fi


USER_CHECK_FILE=${SCRIPT_FOLDER}/nepi_user_check.sh
source $USER_CHECK_FILE
if [[ "$?" -ne 0 ]]; then
    return 
fi


NEPI_UTILS_SOURCE=$(dirname "${SCRIPT_FOLDER}")/resources/bash/nepi_bash_utils
source $NEPI_UTILS_SOURCE


if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"
    return 
fi


echo "########################"
echo "NEPI CUDA SETUP"
echo "########################"

# # Load System Config File
# source $(dirname $(pwd))resources/etc/load_system_config.sh
# if [ $? -eq 1 ]; then
#     echo "Failed to load ${SYSTEM_CONFIG_FILE}"
#     return 
# fi

#***************************************


##########################
NEPI_ARCH=unknown
if is_valid_jetson; then
    NEPI_ARCH=jetson
    MIN_CUDA_VERSION=11.8
elif is_valid_arm64; then
    NEPI_ARCH=arm64
    MIN_CUDA_VERSION=11.8
elif is_valid_amd64; then
    NEPI_ARCH=amd64
    MIN_CUDA_VERSION=12.1
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

echo ""
echo "######################################"
echo "Installing Required Libriaries"
echo "######################################"
echo ""

sudo apt update
sudo apt install build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev \
     libswscale-dev python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
     libdc1394-22-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
     libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev \
     libv4l-dev v4l-utils qv4l2 libopenblas-base libopenmpi-dev libomp-dev \
     dkms linux-headers-$(uname -r)

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
# Upgrade Cuda Version
########################################################




function get_cuda_version(){

        if nvcc --version  >/dev/null 2>&1; then
          string=$(nvcc --version) 
          key=release
          value=$(echo "$string" | grep "${key}" | awk '{print $NF}' | cut -d'.' -f1-2)
          echo "${value#V}"
        else
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
}
export -f get_cuda_version



echo ""
echo "######################################"
echo "Checking for minimum CUDA version ${MIN_CUDA_VERSION}"
cur_cuda_version=$(get_cuda_version)
echo "Got CUDA version ${cur_cuda_version}"
cur_cuda_version="${cur_cuda_version//./}"
if [[ "$cur_cuda_version" -lt "${MIN_CUDA_VERSION//./}" ]]; then
    echo "Installing Cuda ${MIN_CUDA_VERSION}"
    echo "######################################"
    cd $TMP

    cur_folder=$(pwd)
    tmp_folder="/home/${CONFIG_USER}/tmp"
    if [[ ! -d $tmp_folder ]]; then
        mkdir $tmp_folder
    fi
    cd $tmp_folder
    if is_valid_jetson; then
        #https://developer.nvidia.com/cuda-11-8-0-download-archive?target_os=Linux&target_arch=aarch64-jetson&Compilation=Native&Distribution=Ubuntu&target_version=20.04&target_type=deb_local
        # wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/arm64/cuda-ubuntu2004.pin

        # sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
        # wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-tegra-repo-ubuntu2004-11-8-local_11.8.0-1_arm64.deb
        # sudo dpkg -i cuda-tegra-repo-ubuntu2004-11-8-local_11.8.0-1_arm64.deb
        # sudo cp /var/cuda-tegra-repo-ubuntu2004-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
        sudo apt-get install cuda-toolkit-11-8
        sudo apt update
        sudo apt install -y cuda

    elif is_valid_arm64; then
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/arm64/cuda-keyring_1.0-1_all.deb
        sudo dpkg -i cuda-keyring_1.0-1_all.deb

        sudo apt-get update
        sudo apt-get -y install cuda-11-8

    elif is_valid_amd64; then
        wget https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run
        echo ""
        echo "#######################################"
        echo "Ready to install Cuda ${MIN_CUDA_VERSION}"
        echo ""
        echo "When promted:"
        echo "enter 'accetp'"
        echo "Disable all install options except 'CUDA Toolkit'"
        echo "Select the 'Install' option"
        echo ""
        printf "Press Enter to continue..."
        read
        echo ""
        echo "Cuda installation will take several minutes"
        sudo sh cuda_12.1.1_530.30.02_linux.run
        sudo apt install pciutils
        sudo update-pciids
        echo "#######################################"
    else
        arch_val=$(uname -m)
        echo "Arch ${arch_val} not supported yet"
        return 
    fi



        cd $cur_folder
        sudo rm -r "/home/${CONFIG_USER}/tmp/*"
        

        export PATH=/usr/local/cuda-${MIN_CUDA_VERSION}/bin${PATH:+:${PATH}}
        export LD_LIBRARY_PATH=/usr/local/cuda-${MIN_CUDA_VERSION}/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

        SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
        source ${SCRIPT_FOLDER}/nepi_bash_setup.sh

        nvcc --version
        nvidia-smi

    new_cuda_version=$(get_cuda_version)
    echo "Got CUDA version ${new_cuda_version}"
    new_cuda_version="${new_cuda_version//./}"
    if [[ "$new_cuda_version" -lt "${MIN_CUDA_VERSION//./}" ]]; then
        echo "Minimum CUDA Version not setup"
        return 
    else
        #############################
        echo ""
        echo "Updating Bash Variables"
        source "${SCRIPT_FOLDER}/.nepi_bash_setup"
        

        # cat /home/${CONFIG_USER}/.bashrc

        # Source nepi aliases before exit
        echo " "
        echo "Sourcing bashrc with CUDA SETUP"
        sleep 1 & source /home/nepihost/.bashrc
        wait

        #sudo update-alternatives --config cuda-11

    fi

   


else
    echo "######################################"
    echo ""
fi



#################################
# Install cupy-cuda
echo ""
echo "######################################"
echo 'Installing cupy'
echo "######################################"
echo ""

cur_cuda_version=$(get_cuda_version)
CUDA_ARCH="${cur_cuda_version%%.*}"
#sudo -H python${NEPI_PYTHON} -m pip install -upgrade cython
sudo -H python${NEPI_PYTHON} -m pip install cupy-cuda${CUDA_ARCH}x



# #################################
# # Install open3d with cuda support
# ##################################

echo "######################################"
echo 'Installing CUPY'
echo "######################################"

cuda_ver=$(get_cuda_version)
cupy_ver=${cuda_ver%%.*}
sudo pip install cupy-cuda${cupy_ver}x


# #################################
# # Install open3d with cuda support
# ##################################
# #https://github.com/devshank3/JetScan/blob/master/Software_O3D/README.md

echo "######################################"
echo 'Installing Open3d with Cuda Support'
echo "######################################"

# ### AMD ###


if [[ ${NEPI_ARCH} == 'amd64' ]]; then
    sudo pip3 install "cmake<4"
    cmake --version   # confirm it now shows 3.x

    cd /mnt/nepi_storage/tmp
    sudo rm -rf Open3D Open3D-for-Jetson   
    git clone --recursive https://github.com/isl-org/Open3D
    cd Open3D
    git checkout v0.18.0    
    git submodule update --init --recursive

    util/install_deps_ubuntu.sh

    apt-cache rdepends libc++-7-dev libomp-7-dev 2>/dev/null | grep -i ros

    dpkg -l | grep -E 'clang-10|libc\+\+-10|libomp-10'

    which nvcc

    mkdir build && cd build

    sudo CUDACXX=$(which nvcc) cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_CUDA_MODULE=ON \
        -DBUILD_GUI=ON \
        -DENABLE_HEADLESS_RENDERING=OFF \
        -DUSE_SYSTEM_GLEW=OFF \
        -DUSE_SYSTEM_GLFW=OFF \
        -DBUILD_TENSORFLOW_OPS=OFF \
        -DBUILD_PYTORCH_OPS=OFF \
        -DBUILD_UNIT_TESTS=OFF \
        -DPYTHON_EXECUTABLE=$(which python3) \
        ..

    sudo make -j$(nproc)

    sudo python3 -m pip uninstall open3d

    sudo make install
    sudo make install-pip-package -j$(nproc)

    sudo python3 -m pip install --upgrade pip

    find /mnt/nepi_storage/tmp/Open3D/build -name "*.whl"
    # Then
    sudo python3 -m pip install --force-reinstall <path-to-the-.whl>
    #Test

    sudo python3 -c "import open3d; from open3d._build_config import _build_config;print(open3d.__version__) ;print(_build_config)"
    sudo python3 -c "from open3d.visualization import rendering"

fi

### JETSON and ARM ###
if [[ ${NEPI_ARCH} == 'arm64' || ${NEPI_ARCH} == 'jetson' ]]; then
    # sudo apt install clang-7 libglu1-mesa-dev libc++-7-dev libc++abi-7-dev ninja-build libxi-dev libxcomposite-dev libxxf86vm-dev -y
    # sudo apt-get install libosmesa6-dev -y
    # 4) Build Open3D in a virtual python environment. 
    # NOTE: **The make process below took over an 5 hours to run. Maybe faster with rosstop
    # Ref https://www.open3d.org/docs/0.13.0/arm.html
    # Ref https://www.open3d.org/docs/0.11.0/compilation.html
    # Ref https://www.open3d.org/docs/latest/tutorial/Advanced/headless_rendering.html


    ###############
    # SSH INTO NEPI and STOP NEPI
    nepistop

    ##########
    # a) CHECK Cuda Min version 11.5

    cuda_req=11.5
    cuda_cur=$(get_cuda_version)
    if awk "BEGIN {exit !($cuda_cur < $cuda_req)}"; then
        
        # CUDA 11.5.2 from
        # https://developer.download.nvidia.com/compute/cuda/opensource/

        cd /mnt/nepi_storage/tmp
        

        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/cuda-ubuntu2004.pin
        sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
        wget https://developer.download.nvidia.com/compute/cuda/11.5.2/local_installers/cuda-repo-ubuntu2004-11-5-local_11.5.2-495.29.05-1_arm64.deb
        sudo dpkg -i cuda-repo-ubuntu2004-11-5-local_11.5.2-495.29.05-1_arm64.deb
        sudo apt-key add /var/cuda-repo-ubuntu2004-11-5-local/7fa2af80.pub
        sudo apt-get update
        sudo apt-get -y install cuda
        sudo update-alternatives --install /usr/local/cuda cuda /usr/local/cuda-11.5 1150
        
        get_cuda_version
        file="/home/nepi/.nepi_bash_utils"
        sed -i 's/11.4/11.5/g' $file
        sbrc
        get_cuda_version
        
        sudo rm -r /usr/local/cuda-${cuda_cur}
    fi

    ######
    #### RUN NEPISTART then COMMIT NEPI CONTAINER #####
    ######
    ##########



    # b) Setup python virtual environment. SSH into your NEPI device and type the following
    # Just run once, then use the source and deactivate to enter/exit venv

    cd /mnt/nepi_storage/tmp
    python3.8 -m venv open3d_venv

 
    ##########
    # c)

    # USE 18.0 Commit
    git clone --branch v0.18.0 --depth 1 https://github.com/intel-isl/Open3D
    #git clone --recursive https://github.com/intel-isl/Open3D
    cd /mnt/nepi_storage/tmp/Open3D
    git submodule update --init --recursive
    mkdir build


    ##########
    # # d)Edit the CMakeLists.txt 
    # line 328. Change "find_package(Python3 3.6" line to
    # find_package(Python3 X.X EXACT COMPONENTS

    python_version=$(get_python_version)
    file=/mnt/nepi_storage/tmp/Open3D/CMakeLists.txt
    cp $file ${file}.bak
    update_text_value $file "find_package(Python3" "find_package(Python3 ${python_version} EXACT COMPONENTS"

    ##########
    # e) Build Open3D cpp and python modules
    sudo python3 -m pip uninstall open3d
    cd /mnt/nepi_storage/tmp
    source open3d_venv/bin/activate
    
    export DISPLAY=:1
    sudo apt update && sudo apt install texinfo bison flex -y
    sudo apt install libgl1-mesa-dri libgl1-mesa-glx mesa-utils -y
    
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install gcc-13 g++-13 -y
    sudo apt install libstdc++-13-dev -y

    sudo apt install build-essential -y
    sudo apt install clang-7 libglu1-mesa-dev libc++-7-dev libc++abi-7-dev ninja-build libxi-dev libxcomposite-dev libxxf86vm-dev -y
    sudo apt-get install libx11-dev libosmesa6-dev -y
    
    sudo python3 -m pip install pybind11-stubgen

    cd /mnt/nepi_storage/tmp/Open3D
    util/install_deps_ubuntu.sh



    #######################################
    # BUILD WITH GUI (WILL FAIL AT SOME POINT IF IN CONTAINER WITH NO DISPLAY)
    cuda_version=$(get_cuda_version)
    file=/mnt/nepi_storage/tmp/Open3D/CMakeLists.txt
    APPEND=0
    update_text_value $file "option(BUILD_GUI" 'option(BUILD_GUI                  "Builds new GUI"                           ON )' $APPEND
    update_text_value $file "option(ENABLE_HEADLESS_RENDERING" 'option(ENABLE_HEADLESS_RENDERING  "Use OSMesa for headless rendering"        OFF)' $APPEND
    cd /mnt/nepi_storage/tmp/Open3D/build
    sudo CUDACXX=/usr/local/cuda-${cuda_version}/bin/nvcc cmake \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.6 \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_CUDA_MODULE=ON \
        -DBUILD_GUI=ON \
        -DENABLE_HEADLESS_RENDERING=OFF \
        -DUSE_SYSTEM_GLEW=OFF \
        -DUSE_SYSTEM_GLFW=OFF \
        -DBUILD_TENSORFLOW_OPS=OFF \
        -DBUILD_PYTORCH_OPS=OFF \
        -DBUILD_UNIT_TESTS=OFF \
        -DPYTHON_EXECUTABLE=$(which python3) \
        ..

    # RERUN UNTIL COMPLETES WITH NO ERRORS
    sudo make -j$(nproc)
   
   
    ########################
    # BUILD WITH NO GUI
    cuda_version=$(get_cuda_version)
    file=/mnt/nepi_storage/tmp/Open3D/CMakeLists.txt
    APPEND=0
    update_text_value $file "option(BUILD_GUI" 'option(BUILD_GUI                  "Builds new GUI"                           OFF )' $APPEND
    update_text_value $file "option(ENABLE_HEADLESS_RENDERING" 'option(ENABLE_HEADLESS_RENDERING  "Use OSMesa for headless rendering"        ON)' $APPEND
    cd /mnt/nepi_storage/tmp/Open3D/build
    sudo CUDACXX=/usr/local/cuda-${cuda_version}/bin/nvcc cmake \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.6 \
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
        -DPYTHON_EXECUTABLE=$(which python3) \
        ..

    # RUN AND IGNORE ERRORS
    sudo make -j$(nproc)

    #########################
    # REPEAT GUI AND HEADLESS MAKES Until BUILD WITH NO ERRORS
    #######################################
  
    # MAKE INSTALLS
    sudo make install
    sudo make install-pip-package -j$(nproc)

    # RUN TESTS
    sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
    sudo python3 -c "from open3d.visualization import rendering"

    cd /mnt/nepi_storage/tmp/Open3D/examples/python/Advanced
    python headless_rendering.py


    ##################################
    # INSTALL PYTHON BYNDINGS
    sudo make install-pip-package -j$(nproc)

    # RUN TESTS
    sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
    sudo python3 -c "from open3d.visualization import rendering"

    cd /mnt/nepi_storage/tmp/Open3D/examples/python/Advanced
    python headless_rendering.py


    # DEACTIVATE VENV
    deactivate


    # RUN TESTS
    sudo python3 -c "import open3d; from open3d._build_config import _build_config; print(_build_config)"
    sudo python3 -c "from open3d.visualization import rendering"

    cd /mnt/nepi_storage/tmp/Open3D/examples/python/Advanced
    python headless_rendering.py



fi

# ############################################
# # Install cv2 with cuda support
# ############################################


# Run CMake with CUDA flags and other desired options. Adjust CUDA_ARCH_BIN to match your gpu architecture 
# _ OPTIONS
#Jetson ORIN 8.7
#Jetson XAVIER 7.2
#Jetson TX2	6.2
#Jetson NANO 5.3

# CUDA_ARCH_BIN=8.7

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


# # uninstall old version if present
# sudo python${NEPI_PYTHON} -m pip uninstall typing
# python3 -m pip uninstall typing


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

# for torch 2.4
# wget https://github.com/pytorch/vision/archive/refs/tags/v0.19.1.tar.gz

# c. copy to your /mnt/nepi_storage/tmp/ folder and unzip 
# connect NEPI to internet

# sshn in

# sudo apt-get install libjpeg-dev zlib1g-dev libpython3-dev libopenblas-dev libavcodec-dev libavformat-dev libswscale-dev
# cd /mnt/nepi_storage/tmp/

cd /mnt/nepi_storage/tmp
python3.8 -m venv torchv_venv
source torchv_venv/bin/activate
sudo python${NEPI_PYTHON} -m pip install setuptools==49.4.0

# Example
# sudo chmod +x v0.14.0.tar.gz
# tar -xvzf v0.14.0.tar.gz
# sudo chown -R nepi:nepi vision-0.14.0
# cd vision-0.14.0
# export BUILD_VERSION=0.14.0
# sudo python${NEPI_PYTHON} setup.py install

# sudo chmod +x v0.16.2.tar.gz
# tar -xvzf v0.16.2.tar.gz
# cd vision-0.16.2
# export BUILD_VERSION=0.16.2
# sudo python${NEPI_PYTHON} setup.py install


sudo chmod +x v0.19.1.tar.gz
tar -xvzf v0.19.1.tar.gz
sudo chown -R nepi:nepi vision-0.19.1
cd vision-0.19.1
export BUILD_VERSION=0.19.1
sudo python${NEPI_PYTHON} setup.py install

deactivate
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
### Install Driver Support Libs
##################################
    cuda_version=$(get_cuda_version)

    if [[ ${cuda_version} != '0' ]]; then
        cur_folder=$(pwd)
        tmp_folder="/home/${CONFIG_USER}/tmp"
        if [[ ! -d $tmp_folder ]]; then
            mkdir $tmp_folder
        fi
        cd $tmp_folder

        sudo chmod 0766 /home/${CONFIG_USER}/.local/bin

        if [[ ${NEPI_ARCH} == 'jetson' ]]; then
            #https://www.stereolabs.com/developers/release/4.1
            wget https://download.stereolabs.com/zedsdk/4.1/l4t35.1/jetsons -O 'zstd.run'
            sudo sudo apt install zstd nvidia-utils-515 linux-generic-hwe-20.04 -y
        elif [[ ${NEPI_ARCH} == 'arm64' ]]; then
            # https://www.stereolabs.com/developers/release/4.2
            wget https://download.stereolabs.com/zedsdk/4.2/cu11/ubuntu20 -O 'zstd.run'
            sudo sudo apt install zstd nvidia-utils-515 linux-generic-hwe-20.04 -y
        elif [[ ${NEPI_ARCH} == 'amd64' ]]; then
            #https://www.stereolabs.com/developers/release/4.2
            wget https://download.stereolabs.com/zedsdk/4.2/cu12/ubuntu20 -O 'zstd.run'
            sudo sudo apt install zstd nvidia-utils-535 linux-generic-hwe-20.04 -y
        fi

            # To continue you have to accept the EULA. Accept  [Y/n] ?Y
            # Installing...
            # Installation path: /usr/local/zed
            # Checking CUDA version...
            # OK: Found CUDA 11.8
            # Do you want to also install the static version of the ZED SDK (AI module will still require libsl_ai.so) [Y/n] ?Y
            # Do you want to install the AI module (required for Object detection and Neural Depth, recommended), cuDNN 8.9 and TensorRT 8.6 will be installed [Y/n] ?n
            # Install samples (recommended) [Y/n] ?Y
            # Installation path: /usr/local/zed/samples/
            # Dependencies installation complete
            # Do you want to install the Python API (recommended) [Y/n] ?Y

        chmod +x zstd.run
        ./zstd.run

        cd $cur_folder
        sudo rm -r "/home/${CONFIG_USER}/tmp/*"
    fi

    np_required=1.23.5
    np_version=$(python -c "import numpy; print(numpy.__version__)") 
    if [[ ${np_version//./} != ${np_required//./} ]]; then
        python${NEPI_PYTHON} -m pip uninstall numpy
        python -c "import numpy; print(numpy.__version__)"
        #sudo -H python${NEPI_PYTHON} -m pip install --no-input numpy==1.23.5
    fi



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