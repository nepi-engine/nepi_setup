# NEPI Docker Demo Setup Instructions
This tutorial will walk you through setting up, configuring, and running a NEPI Docker Demo Installation on a supported device.

**SUPPORTED DEVICES:** Ubuntu PC, NVIDIA Jetson

NEPI Docker Demo Installations are recommended for a quick demo of the NEPI Software Container for expienced linux users.
**NOTE:** If you are not an experienced linux user, you may want to try the NEPI Docker Lite installation which includes
a fully automated setup process. See the NEPI DOCKER LITE SETUP instructions at [here](NEPI_DOCKER_LITE_SETUP.md)

**NOTE:** NEPI Docker installation will require a minimum of 20 GB of available free hard drive space on your device. 

################################################################
### NEPI Docker Demo Env Setup

Log into a user account on the device with 'Adminstrator' privilages

Open Terminal Window - Right click on the desktop and select the "Open in Terminal" option.

Check that Docker is installed on your device by typing:

    docker

**NOTE:** If Docker is not installed, install docker along with any additional software required if you also need NVIDIA GPU support.

Check that a Chromium web-browser is installed on your device by typing:

    chromium

**NOTE:** If Chromium is not installed, install chromium.

Create NEPI required system folders on your device, and add your user to required system groups:

    sudo -v 

then 

    CONFIG_USER=$(id -un) && USER_1000=$(id -nu 1000)
    sudo mkdir /mnt/nepi_config 
    sudo chown 1000:1000 /mnt/nepi_config 
    sudo mkdir /mnt/nepi_storage 
    sudo chown 1000:1000 /mnt/nepi_storage
    sudo usermod -aG sudo $CONFIG_USER
    sudo adduser ${CONFIG_USER} dialout
    sudo usermod -aG dialout ${CONFIG_USER}
    sudo usermod -aG tty ${CONFIG_USER}
    sudo usermod -aG i2c ${CONFIG_USER}
    sudo usermod -aG video ${CONFIG_USER}
    sudo usermod -aG docker ${CONFIG_USER}
    sudo usermod -aG ${USER_1000} ${CONFIG_USER}
    exec su -l $CONFIG_USER


Install the latest NEPI Docker Image for your device

**For NONE GPU or RADEON GPU SUPPORT**

    sudo docker pull numurusnepi/nepi:latest

Retag image as nepi:

    sudo docker tag numurusnepi/nepi:latest nepi:latest
    sudo docker rmi numurusnepi/nepi:latest

**For NVIDIA GPU SUPPORT or For NVIDIA JETSON GPU SUPPORT**

    sudo docker pull numurusnepi/nepi:latest-cuda

Retag image as nepi:

    sudo docker tag numurusnepi/nepi:latest-cuda nepi:latest-cuda
    sudo docker rmi numurusnepi/nepi:latest-cuda

**NOTE:** NEPI Docker images are large files and will take several minutes to download and install


Install the latest NEPI Storage Files which include sample Data, AI Model, and Configuration files:

    sudo -v 

then 

    cd /mnt/nepi_storage
    storage_latest_link='https://www.dropbox.com/scl/fi/za3sz2q7e0pbcj6m89d8h/nepi_storage-latest.zip?rlkey=eq6u97w6qpqiqblcudqnwj8ud&st=hj0yewy3&dl=0'
    storage_latest_zip=nepi_storage-latest.zip
    sudo rm ${storage_latest_zip} 2> /dev/null
    sudo wget ${storage_latest_link} -O ${storage_latest_zip}
    sudo -v && sudo unzip -o -q $storage_latest_zip
    sudo rm ${storage_latest_zip} 2> /dev/null
    sudo chown -R 1000:1000 ${NEPI_STORAGE}
    ls ./



################################################################
### NEPI Docker Software Testing
This section will start and test your NEPI Docker solution. 

Start your NEPI container running with the following command:

**For NONE GPU or RADEON GPU SUPPORT**

    sudo docker run -d --privileged --rm -e UDEV=1 --ipc=host --user 0:0 \
    --mount type=bind,source=/mnt/nepi_storage,target=/mnt/nepi_storage \
    --mount type=bind,source=/mnt/nepi_config,target=/mnt/nepi_config \
    --mount type=bind,source=/dev,target=/dev \
    --mount type=bind,source=/etc/udev,target=/etc/udev \
    --cap-add=SYS_TIME --volume=/var/empty:/var/empty \
    -v /etc/ntpd.conf:/etc/ntpd.conf -e DISPLAY=:0 \
    --net=host -p 9091:9091 -p 9092:9092 -p 11311:11311 \
    -p 137:137/udp -p 138:138/udp -p 139:139/tcp -p 445:445/tcp \
    nepi:latest /bin/bash -c '/nepi_start_all'

**For NVIDIA GPU SUPPORT**

    sudo docker run -d --privileged --rm -e UDEV=1 --ipc=host --user 0:0 \
    --mount type=bind,source=/mnt/nepi_storage,target=/mnt/nepi_storage \
    --mount type=bind,source=/mnt/nepi_config,target=/mnt/nepi_config \
    --mount type=bind,source=/dev,target=/dev \
    --mount type=bind,source=/etc/udev,target=/etc/udev \
    --cap-add=SYS_TIME --volume=/var/empty:/var/empty \
    -v /etc/ntpd.conf:/etc/ntpd.conf -e DISPLAY=:0 \
    --net=host -p 9091:9091 -p 9092:9092 -p 11311:11311 \
    -p 137:137/udp -p 138:138/udp -p 139:139/tcp -p 445:445/tcp \
    --gpus all --runtime nvidia -v /tmp/.X11-unix/:/tmp/.X11-unix 
    nepi:latest /bin/bash -c '/nepi_start_all'


**For NVIDIA JETSON GPU SUPPORT**

    sudo docker run -d --privileged --rm -e UDEV=1 --ipc=host --user 0:0 \
    --mount type=bind,source=/mnt/nepi_storage,target=/mnt/nepi_storage \
    --mount type=bind,source=/mnt/nepi_config,target=/mnt/nepi_config \
    --mount type=bind,source=/dev,target=/dev \
    --mount type=bind,source=/etc/udev,target=/etc/udev \
    --cap-add=SYS_TIME --volume=/var/empty:/var/empty \
    -v /etc/ntpd.conf:/etc/ntpd.conf -e DISPLAY=:0 \
    --net=host -p 9091:9091 -p 9092:9092 -p 11311:11311 \
    -p 137:137/udp -p 138:138/udp -p 139:139/tcp -p 445:445/tcp \
    --gpus all --runtime nvidia -v /tmp/.X11-unix/:/tmp/.X11-unix 
    -v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp 
    -v /usr/bin/nvargus-daemon:/usr/bin/nvargus-daemon
    nepi:latest /bin/bash -c '/nepi_start_all'    


**NOTE:** If you encounter any issues starting and running the NEPI Software container, 
you may consider running the NEPI Docker Lite Installation which includes debugging tools.
See the NEPI DOCKER LITE SETUP instructions at [here](NEPI_DOCKER_LITE_SETUP.md)


**OPEN CHROMIUM WEB BROSWER**
Check that the NEPI Resident User Interface (RUI) is running by opening the Chromium browser and entering the following in the search bar:

    localhost:5003 

This will take you to the NEPI RUI dashboard.  Once the NEPI core software system is running, you should see a blinking Green indicator and messages.
**NOTE:**  RUI Controls related to User, Device, Time, Network, and Software managemnt are not enabled for NEPI Demo installations.

You can also access the NEPI admin page for managing nepi software configurations by entering the following in the search bar:

    localhost:5003/admin

the default admin password is: **nepiadmin**

To get an AI model running more about using, configuring, and building NEPI software, 
see the documentation, tuturials, videos, and community forum available at:
[NEPI Website](https://www.nepi.com/tutorials/quick-start/)

**NOTE:** If you save any camera or AI detection data, you can access it:

    cd /mnt/nepi_storage/data


################################################################
### NEPI Software Support

To learn more about using, configuring, and building NEPI software, 
see the documentation, tuturials, videos, and community forum available at:
[NEPI Website](https://www.nepi.com)


################################################################
### NEPI DEMO DOCKER INSTALLATION COMPLETE
################################################################


