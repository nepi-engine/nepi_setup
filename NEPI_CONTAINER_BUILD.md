# NEPI Docker Build Setup Instructions
This tutorial will walk you through setting up, configuring, and building a NEPI Docker production container on a suitable edge processor.

For additional support, see the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)

################################################################
### NEPI Docker Host Setup

If you device is not allready setup as a NEPI Docker Host,
you will first need to configure an edge processor
with a NEPI Docker production installation folowing these instructions:

See NEPI Docker Host Setup instructions at [here](NEPI_DOCKER_HOST_SETUP.md)


################################################################
### NEPI Docker Container Build Instructions

**NOTE:**  You can run the following NEPI Container Build steps either 
directly on a NEPI Host device, or on a network connected Linux Ubuntu PC for NEPI development.
For the PC build option, you will first need to configure your PC for NEPI development. 
See the NEPI Development PC Setup instructions at [here](NEPI_DEV_PC_SETUP.md).

**NOTE:**  At the end of each of the following sections, the NEPI container at that state will be
committed. If you run into any issues during one of the sections, can restart it from the beginning
which will use the last steps committed container image. 


################################################################
### NEPI Base Container Setup

**RUN THESE STEPS ON A NEPI HOST DEVICE or NEPI DEV PC**

Check for internet connection

    pingi  # "Run 'ninet' on a NEPI Host Device to try and connect if not connected:

Clone the NEPI Engine repo on your development system (NEPI Device or NEPI Dev PC):

    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout main
    git submodule update --init --recursive

Check network connection to the NEPI HOST Device

    pingn # Ctrl-C to stop

Deploy the NEPI Source Code to the Device 

    export DEPLOY_3RD_PARTY=1 # Set flag to deploy 3rd Party Software for first build
    nepidpl

**RUN THESE STEPS IN THE NEPI HOST**
Open a terminal on your NEPI Device (or SSH into your NEPI Device from your NEPI Dev PC using the terminal command 'sshnh')

Enable internet connection and sync clocks (password is 'nepi'):

    ninet

Check for internet connection

    pingi

Stop the NEPI Docker Service and any running NEPI Containers

    nepistop

Initialize a Docker with a NEPI Base Image
**NOTE** Unless your NEPI Host Device is configured with NEPI's AB File System enabled,
the current NEPI Docker Image and all of it's commits will be replaced with the imported image.
If you have an installed NEPI Docker Image that you want to preserve, run 'nepiexport' first.

    nsetup # Switch to nepi setup repo folder
    source ./nepi_docker_init
    dimg # Show installed base image

Start a NEPI container running in dev mode (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Export your NEPI Base container (password is 'nepi'):

    nepiexport

**NOTE**  If you run into issues and need to try the remaining setup steps,
you can reimport the exported NEPI Base Image using 'nepiimport' command,
and selecting this exported image file.


################################################################
### NEPI Container User Setup

**RUN THESE STEPS IN THE NEPI HOST**
Enable internet connection and sync clocks (password is 'nepi'):

    ninet

Check for internet connection

    pingi

Start the NEPI container running in dev mode (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as root (password is 'nepi'):

    nepiloginroot

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**
Run the NEPI User Setup script:

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
    source ./nepi_user_setup.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**

Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "user_setup"





################################################################
### NEPI Container Environment Setup 1

**RUN THESE STEPS IN THE NEPI HOST**
Check for internet connection:

    pingi 

**NOTE** If you are not connected, run 'ninet', then try to ping again.

Restart the NEPI container running in dev mode now using the latest commit (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi (password is 'nepi'):

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER


**RUN THESE STEPS IN THE NEPI CONTAINER**

Run the NEPI Environmant Setup scripts (password is 'nepi'):

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
    source ./nepi_env_setup1.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "env_setup1"




################################################################
### NEPI Container Environment Setup 2

**RUN THESE STEPS IN THE NEPI HOST**
Check for internet connection:

    pingi 

**NOTE** If you are not connected, run 'ninet', then try to ping again.

Restart the NEPI container running in dev mode now using the latest commit (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi (password is 'nepi'):

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER


**RUN THESE STEPS IN THE NEPI CONTAINER**

Run the NEPI Environmant Setup scripts (password is 'nepi'):

**NOTE:** "Building wheel for lxml (pyproject.toml)" step took a long time but worked.

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
    source ./nepi_env_setup2.sh


Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "env_setup2"


################################################################
### NEPI Container ROS Setup

**RUN THESE STEPS IN THE NEPI HOST**
Check for internet connection:

    pingi 

**NOTE** If you are not connected, run 'ninet', then try to ping again.

Restart the NEPI container running in dev mode now using the latest commit (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi (password is 'nepi'):

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**

Run the ROS Environmant Setup script (password is 'nepi'):

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
    source ./ros_setup.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "ros_setup"

    

################################################################
### NEPI Container Config Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi (password is 'nepi'):

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**

Run the NEPI Config Setup script (password is 'nepi'):

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
    source ./nepi_config_setup.sh

Test the NEPI Container's SSH Service (port 2222)
**NOTE** You will see a message that port 22 is in use

    scripts
    source ./nepi_ssh_start

**Ctrl-C** to stop the process

Test Run an AI Detectror

    scripts
    sudo su
    source ./nepi_ai_test

**Ctrl-C** to stop the process

    exit # exit sudo uer

Log out of the container:

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "config_setup"




################################################################
### NEPI Container NEPI Engine Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi (password is 'nepi'):

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**
Start the NEPI Build from Source process (password is 'nepi'):

    codebld

Test Run the NEPI

    scripts
    sudo su
    source ./nepi_engine_start

**Ctrl-C** to stop the process

    exit # exit sudo uer

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "engine_setup"



################################################################
### NEPI Container NEPI RUI (Resident User Interface) Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit (password is 'nepi'):

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi (password is 'nepi'):

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**

Run the NEPI RUI Config Setup script (password is 'nepi'):
**NOTE** The following process witll show a lot of 'npm WARN' meassages you can ignore.

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts
    source ./nepi_rui_setup.sh


Test Run the RUI:**
**NOTE:** You can ignore a red 'WARNING: This is a development server' warning

    scripts
    source ./nepi_rui_start

**Ctrl-C** to stop the process

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST

**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description (password is 'nepi'):

    nepicommit "rui_setup"



################################################################
### NEPI Container Create

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in production mode now using the latest commit (password is 'nepi'):

    nepistart
    dps # Show running NEPI container

Export and Import the new NEPI Docker Image from the running NEPI Container (password is 'nepi'):

**NOTE** Unless your NEPI Host Device is configured with NEPI's AB File System enabled,
the current NEPI Docker Image and all of it's commits will be replaced with the imported image.

    nepicreate # OR 'nepiexport clean' to just export the new image without importing

