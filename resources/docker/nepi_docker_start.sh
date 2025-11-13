#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script launches NEPI Container
sudo -v

CONFIG_USER=nepihost
source /home/${CONFIG_USER}/.nepi_bash_utils
wait

SCRIPT_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)


########################
# Update Docker Config
#echo ""
#echo "Updating Docker Config File"
bash ${SCRIPT_FOLDER}/nepi_docker_update.sh
wait

########################
# Load NEPI DOCKER
CONFIG_SOURCE=${SCRIPT_FOLDER}/nepi_docker_config.yaml
source ${SCRIPT_FOLDER}/load_docker_config.sh
if [[ "$?" -eq 1 ]]; then
    echo "Failed to load ${CONFIG_SOURCE}"

else

    ########################
    # Start Processes

    # Reset. Updated by NEPI Software
    SYSTEM_CONFIG_FILE=/mnt/nepi_config/system_cfg/nepi_system_config.yaml
    update_yaml_value "NEPI_VERSION" 'XpXpX' "$SYSTEM_CONFIG_FILE"
    update_yaml_value "NEPI_SW_DESC" 'unknown' "$SYSTEM_CONFIG_FILE"
    update_yaml_value "NEPI_FS_AB" $NEPI_AB_FS "$SYSTEM_CONFIG_FILE"


    if [[ "$NEPI_ACTIVE_FS" == "nepi_fs_a" ]]; then
        nepi_fs=${NEPI_FSA}
        nepi_fs_tag=${NEPI_FSA_TAG}
    else
        nepi_fs=${NEPI_FSB}
        nepi_fs_tag=${NEPI_FSB_TAG}
    fi
   
    ########################NEPI_ACTIVE_FS

    NEEDS_RESTART=1


    # #Check for allready running
    # run_names=($(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${nepi_fs}" | awk '{print $2}'))
    # #echo $run_names
    # if [[ -n "$run_names" ]]; then
    #     for run_name in "${run_names[@]}"; do
    #         if [[ -n "$run_name" ]]; then
    #             run_id=$(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${run_name}" | awk '{print $1}')
    #             if [[ -n "$run_id" ]]; then
    #                 if [[ "${nepi_fs}:${nepi_fs_tag}" == "$run_name" ]]; then
    #                     echo "Image ${nepi_fs}:${nepi_fs_tag} allready running with ID: ${run_id}"
    #                     NEEDS_RESTART=0
    #                 fi
    #             fi
    #         fi
    #     done
    # fi
    

    #Check for allready running
    if [[ "$NEEDS_RESTART" -eq 1 ]]; then
        stop_names=($(sudo docker ps -a --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${nepi_fs}" | awk '{print $2}'))
        #echo $stop_names
        if [[ -n "$stop_names" ]]; then
            for stop_name in "${stop_names[@]}"; do
                if [[ -n "$stop_name" ]]; then
                    stop_id=$(sudo docker ps --format "{{.ID}}\t{{.Image}}\t{{.Names}}" | grep "${stop_name}" | awk '{print $1}')
                    if [[ -n "$stop_id" ]]; then
                        if [[ "${nepi_fs}:${nepi_fs_tag}" == "$stop_name" ]]; then
                            echo "Restarting Image ${nepi_fs}:${nepi_fs_tag} with ID: ${stop_id}"
                            sudo docker start $stop_id

                            sleep 2

                            CONTAINER_ID=($(sudo docker ps -qf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
                            CONTAINER_ID=${CONTAINER_ID[0]}
                            if [[ -z "$CONTAINER_ID" ]]; then
                                echo "NEPI Failed to Run"
                                CONTAINER_ID=($(sudo docker ps -aqf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
                                if [[ -z "$CONTAINER_ID" ]]; then
                                    echo "Removing stopped container ${nepi_fs}:${nepi_fs_tag} with id ${CONTAINER_ID}"
                                    sudo docker rm $CONTAINER_ID
                                fi
                            else
                                NEEDS_RESTART=0

                                echo ""
                                echo "NEPI Container Running with ID: ${CONTAINER_ID}"
                                echo ""
                                dps

                                update_yaml_value "NEPI_RUNNING" 1 "$CONFIG_SOURCE"
                                update_yaml_value "NEPI_RUNNING_FS" "$nepi_fs" "$CONFIG_SOURCE"
                                update_yaml_value "NEPI_RUNNING_TAG" "$nepi_fs_tag" "${CONFIG_SOURCE}"
                                update_yaml_value "NEPI_RUNNING_ID" $CONTAINER_ID "${CONFIG_SOURCE}"
                                update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "$(date +%Y-%m-%d)" "${CONFIG_SOURCE}"
                                update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
                                update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"
                            fi
                        fi
                    fi
                fi
            done
        fi
    fi    




    if [[ "$NEEDS_RESTART" -eq 1 ]]; then

        # Stop Any Running NEPI Containers
        echo "Calling NEPI Docker Stop Process"
        bash ${SCRIPT_FOLDER}/nepi_docker_stop.sh
        wait

        ### This is done by nepi_docker service before calling nepi_docker_start
        #######################
        # Update ETC Config Files
        #######################
        # source ${SCRIPT_FOLDER}/update_etc_files.sh
        # wait

        ########################
        # Build Run Command
        ########################
        echo "Building NEPI Docker Run Command"

        # NEPI_STORAGE=/mnt/nepi_storage
        # NEPI_CONFIG=/mnt/nepi_coinfig
        

        if [[ "$NEPI_RM_PS" -eq 0 ]]; then
            echo "Starting with rm process disabled"
            rm_cmd=''
        else
            echo "Starting with rm process enabled"
            rm_cmd="--rm"
        fi
        


        ########
        # Initialize Run Command
        DOCKER_RUN_COMMAND="sudo docker run -d --privileged ${rm_cmd} -e UDEV=1 --ipc=host --user 0:0 \
        --mount type=bind,source=/mnt/nepi_storage,target=/mnt/nepi_storage \
        --mount type=bind,source=/mnt/nepi_config,target=/mnt/nepi_config \
        --mount type=bind,source=/dev,target=/dev \
        --cap-add=SYS_TIME --volume=/var/empty:/var/empty -v /etc/ntpd.conf:/etc/ntpd.conf \
        -e DISPLAY=$DISPLAY \
        --net=host \
        -p 2222:22 \
        -p 9091:9091 \
        -p 9092:9092 \
        -p 11311:11311 \
        --name samba-server \
        -p 137:137/udp \
        -p 138:138/udp \
        -p 139:139/tcp \
        -p 445:445/tcp "

        # Set cuda support if needed

        if is_valid_cuda; then
            echo "Enabling CUDA GPU Support TRUE"
        DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
        --gpus all \
        --runtime nvidia \
        -v /tmp/.X11-unix/:/tmp/.X11-unix "

        fi 

        # Finish Run Command

        echo "Using name:tag ${nepi_fs}:${nepi_fs_tag} with Command"

        DOCKER_RUN_COMMAND="${DOCKER_RUN_COMMAND} \
        ${nepi_fs}:${nepi_fs_tag} /bin/bash \
        -c '/nepi_start_all'"

        #-c 'service supervisor start'"

        ########################
        # Run NEPI Docker
        ########################

        function dcheck() {
            dname=$1
            #dtag=$(sudo docker ps --format '{{.Image}}' | grep ${dname} | awk -F ':' '{print $1}' )
            echo $(sudo docker ps -a)
            did=$(sudo docker container ls  | grep $dname | awk '{print $1}')
            if [[ -z "$did" ]]; then
                return 1      
            fi
            return 0
        }

        echo "Restarting Network"
        sudo systemctl restart networking
        echo ""
        echo "Launching NEPI Docker Container ${nepi_fs}:${nepi_fs_tag} with Command"
        echo "${DOCKER_RUN_COMMAND}"
        eval "$DOCKER_RUN_COMMAND"

        # sleep 2
        # dcheck $nepi_fs
        # if [[ "$?" -eq 1 ]]; then
        #     echo "NEPI Container ${dname} FAILED to run"
        #     exit 1
        # fi

        # sleep 2
        # dcheck $nepi_fs
        # if [[ "$?" -eq 1 ]]; then
        #     echo "Retrying NEPI Docker Container ${nepi_fs}:${nepi_fs_tag}"
        #     eval "$DOCKER_RUN_COMMAND"
        #     sleep 2
        #     dcheck $nepi_fs
        #     if [[ "$?" -eq 1 ]]; then
        #         echo "NEPI Container ${dname} FAILED to run"
        #         exit 1
        #     fi
        # fi


        sleep 2


        CONTAINER_ID=($(sudo docker ps -qf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
        CONTAINER_ID=${CONTAINER_ID[0]}
        if [[ -z "$CONTAINER_ID" ]]; then
            echo "NEPI Failed to Run"
            CONTAINER_ID=($(sudo docker ps -aqf "ancestor=${nepi_fs}:${nepi_fs_tag}"))
            if [[ -n "$CONTAINER_ID" ]]; then
                echo "Removing stopped container ${nepi_fs}:${nepi_fs_tag} with id ${CONTAINER_ID}"
                sudo docker rm $CONTAINER_ID
            fi

        else

            echo ""
            dps
            echo ""
            echo "--------------------------"
            echo "NEPI Container Running with ID: ${CONTAINER_ID}"
            echo "--------------------------"   
            echo ""


            update_yaml_value "NEPI_RUNNING" 1 "$CONFIG_SOURCE"
            update_yaml_value "NEPI_RUNNING_FS" "$nepi_fs" "$CONFIG_SOURCE"
            update_yaml_value "NEPI_RUNNING_TAG" "$nepi_fs_tag" "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RUNNING_ID" $CONTAINER_ID "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RUNNING_LAUNCH_TIME" "$(date +%Y-%m-%d)" "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_FS_RESTART" 0 "${CONFIG_SOURCE}"
            update_yaml_value "NEPI_RESTARTING" 0 "${CONFIG_SOURCE}"
        fi

    fi

fi
