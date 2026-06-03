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

LITE_INSTALL=$1

sudo -v

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
INSTALL_CHECK_FILE=${SCRIPT_FOLDER}/nepi_install_check.sh
source $INSTALL_CHECK_FILE $LITE_INSTALL
if [[ "$?" -ne 0 ]]; then
    return 
fi


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
USER_UTILS_SOURCE=/home/${CONFIG_USER}/.nepi_bash_utils
if [[ -f $USER_UTILS_SOURCE ]]; then
    source $USER_UTILS_SOURCE
fi

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


# Run NEPI System Config Load if exists
NEPI_SYS_CONFIG_FILE=/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml

if ! is_valid_internet; then
    echo "No Internet Connection Detected.  Connect and rerun this script"

else



    sudo update-pciids
    

    cur_dir=$(pwd)
    echo "Host updating HAILO HW Version"
    NEPI_HAILO_HW_VERSION=$(get_hailo_hw_version)
    export NEPI_HAILO_HW_VERSION=$NEPI_HAILO_HW_VERSION
    update_yaml_value "NEPI_HAILO_HW_VERSION" $NEPI_HAILO_HW_VERSION $NEPI_SYS_CONFIG_FILE
    echo $NEPI_HAILO_HW_VERSION


    NEPI_HAILO_FW_VERSION=$(get_hailo_fw_version)
    if [[ "$NEPI_HAILO_FW_VERSION" != "0" ]]; then
        NEPI_HAILO_SW_VERSION=$NEPI_HAILO_FW_VERSION
    else
        NEPI_HAILO_SW_VERSION=0
    fi

    echo ""
    echo "NEPI_HAILO_HW_VERSION: ${NEPI_HAILO_HW_VERSION}"
    echo "NEPI_HAILO_SW_VERSION: ${NEPI_HAILO_SW_VERSION}"
    echo ""
    
    if [[ "$NEPI_HAILO_SW_VERSION" != "0" ]]; then
            cur_hailo_sw=$(get_hailo_sw_version)

            echo ""
            echo "######################################"
            echo "Installing HAILO Software "
            echo "######################################"
            echo ""





            sudo apt install  dkms libglib2.0-0 ffmpeg x11-utils bison flex libelf-dev \
            libgstreamer-plugins-base1.0-dev python-gi-dev libgirepository1.0-dev libzmq3-dev gcc-9 g++-9 \
            libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev \
            gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x \
            gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio \
            python3-gi python3-gi-cairo gir1.2-gtk-3.0 -y >/dev/null 2>&1



            cur_folder=$(pwd)



            echo "#########"
            echo "Updating HAILO Softare and Firmware Version to ${NEPI_HAILO_SW_VERSION} "


            hailo_folder="hailort-${NEPI_HAILO_SW_VERSION}"
           
           export build_folder="/home/${CONFIG_USER}/hailo"
            if [[ ! -d $build_folder ]]; then
                sudo mkdir -p $build_folder
            fi
            sudo chown ${CONFIG_USER}:${CONFIG_USER} $build_folder
            cd $build_folder
          
            export install_dir="${build_folder}/${hailo_folder}"
           
           if [[ -d $install_dir ]]; then
                echo "Found existing software at ${install_dir}"
           else
                cd $build_folder
                if [[ -f ${hailo_zip} ]]; then
                    sudo rm -r $hailo_zip
                fi
                if [[ ! -f ${hailo_zip} ]]; then
                
                    hailo_link="https://github.com/hailo-ai/hailort/archive/refs/tags/v${NEPI_HAILO_SW_VERSION}.zip"
                    echo $hailo_link
                    hailo_zip="hailort-${NEPI_HAILO_SW_VERSION}.zip"
                    # CHECK VERSION: nepihost@device1:~/hailo/hailort-4.20.0$ hailortcli fw-control identify
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
                        sudo chown -R ${CONFIG_USER}:${CONFIG_USER} $hailo_folder
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

                # if [[ -f ${hailo_zip} ]]; then
                #     sudo rm ${hailo_zip} > /dev/null 2>&1
                # fi


            fi


            if [[ -d $install_dir ]]; then



                echo "#########"
                echo "Installing HailoRT Version ${NEPI_HAILO_SW_VERSION} "

                sudo apt remove hailo-all -y 2> /dev/null
                # sudo apt remove hailort -y 2> /dev/null
                # sudo rm -r /usr/local/bin/hailortcli
                # sudo rm -f /usr/bin/hailortcli
                # sudo apt-get remove --purge -y hailort hailort-pcie-driver hailo-tappas-core hailo-all hailofw
                # sudo dpkg --purge hailort-pcie-driver hailort hailo-tappas-core hailo-all hailofw
                # sudo rm -r /usr/local/hailo

                # sudo rm -rf /usr/lib/libhailort*
                # sudo rm -rf /usr/include/hailo



                sudo apt install -f dkms -y 2> /dev/null
                # sudo apt install -f hailo-all -y 
                # sudo apt install -f hailort -y
                #sudo apt update && sudo apt update --fix-missing

                PYTHON_VERSION=$(get_python_version)
                if [[ -d "/usr/local/lib/python${PYTHON_VERSION}/dist-packages/hailo_platform" ]]; then
                    sudo rm -r "/usr/local/lib/python${PYTHON_VERSION}/dist-packages/hailo_platform"
                fi

                sudo chown ${CONFIG_USER}:${CONFIG_USER} $install_dir
                cd $install_dir
                mkdir build
                cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DHAILO_BUILD_EXAMPLES=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5  && sudo cmake --build build --config release --target install

                # Build pyHailoRT
                cd $install_dir
                python3 -m venv hailo_venv
                source hailo_venv/bin/activate

                pip install --upgrade pip setuptools wheel

                platform_dir=${install_dir}/hailort/libhailort/bindings/python/platform
                cd ${platform_dir}
                sudo apt install build-essential gcc g++ ccache 

                ## Make changes then hit enter to continue

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
                
                if [[ ! -d "/usr/local/lib/python${PYTHON_VERSION}/dist-packages/hailo_platform" ]]; then
                    sudo cp -R ${platform_dir}/hailo_platform /usr/local/lib/python${PYTHON_VERSION}/dist-packages/
                fi
                #pip uninstall typing
                

            fi

            cd $cur_dir
    fi

    if [[ "$NEPI_MODE" == "SYSTEM" ]]; then
        echo "Host updating HAILO SW Version"
        NEPI_HAILO_SW_VERSION=$(get_hailo_sw_version)
        export NEPI_HAILO_SW_VERSION=$NEPI_HAILO_SW_VERSION
        update_yaml_value "NEPI_HAILO_SW_VERSION" $NEPI_HAILO_SW_VERSION $NEPI_SYS_CONFIG_FILE
        echo $NEPI_HAILO_SW_VERSION
    fi
    if [[ -z $NEPI_HAILO_SW_VERSION ]]; then
        NEPI_HAILO_SW_VERSION=0
    fi

fi

            # if [[ -d $install_dir ]]; then
            #     #hailortcli fw-control identify

            #     hailo_sw_version=$(get_hailo_sw_version)
            #     hailo_fw_version=$(get_hailo_fw_version)
            #     if [[ "$HAILO_FW_VERSION" != $"NEPI_HAILO_SW_VERSION" ]]; then

            #         echo "#########"
            #         echo "Installing Hailo Firmware Version ${NEPI_HAILO_SW_VERSION} "
            #             cd $install_dir
            #             bin_dir="${install_dir}/bin"
            #             if [[ ! -d $bin_dir ]]; then
            #                 mkdir $bin_dir
            #             fi
            #             cd ${install_dir}/${bin_dir}

            #             hailo_fw_file="hailo${NEPI_HAILO_HW_VERSION}_fw.${NEPI_HAILO_SW_VERSION}.bin"
            #             hailo_fw_dest_file="hailo${NEPI_HAILO_HW_VERSION}_fw.bin"
            #             hailo_fw_folder="/lib/firmware/hailo"

            #             curl -o "$hailo_fw_file" https://hailo-hailort.s3.eu-west-2.amazonaws.com/Hailo8/${NEPI_HAILO_SW_VERSION}/FW/hailo8_fw.${NEPI_HAILO_SW_VERSION}.bin

            #             if [[ -f $hailo_fw_file ]]; then
            #                 if [[ ! -d $hailo_fw_folder ]]; then
            #                     sudo mkdir -p $hailo_fw_folder
            #                 fi
            #                 sudo cp $hailo_fw_file "${hailo_fw_folder}/" 
            #                 if [[ "$hailo_sw_version" == $"hailo_fw_version" ]]; then
            #                     hailortcli fw-update ${hailo_fw_folder}/${hailo_fw_file}
            #                 fi
            #                 sudo ln -sf ${hailo_fw_folder}/${hailo_fw_file} ${hailo_fw_folder}/${hailo_fw_dest_file}
            #             fi
            #     fi

            
                # if hailortcli fw-control identify; then
                #     if is_valid_halio_sw; then
                #         echo ""
                #         echo "######################################"
                #         echo "Installing HAILO Apps "
                #         echo "######################################"
                #         echo ""
                #         sudo apt install meson ninja-build portaudio19-dev python3-gi python3-gi-cairo libbz2-dev liblzma-dev libelf-dev libunwind-dev libdw-dev -y
                #         cd $INSTALL_DIR
                #         if [[ -d 'hailo-apps' ]]; then
                #             git clone https://github.com/hailo-ai/hailo-apps.git
                #             cd hailo-apps
                #             sudo ./install.sh
                #             source setup_env.sh
                #             hailo-detect-simple
                #         fi    
                #     fi
                # fi