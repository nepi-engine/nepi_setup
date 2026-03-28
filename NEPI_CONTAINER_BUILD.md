# NEPI Docker Build Setup Instructions
This tutorial will walk you through setting up, configuring, and building a NEPI Docker production container on a suitable edge processor.

For additional support, see the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)

################################################################
### NEPI Docker Host Setup

If you device is not allready setup as a NEPI Docker Host,
you will first need to configure an edge processor
with a NEPI Docker production installation folowing these instructions:

See NEPI Docker Lite and Docker Full Setup instructions at [here](NEPI_DOCKER_LITE_SETUP.md) and [here](NEPI_DOCKER_FULL_SETUP.md).  While either setup supports NEPI Docker Container Building, but the Full setup
is recommended.


################################################################
### NEPI Docker Container Build Instructions

**NOTE:**  You can run the following NEPI Container Build steps either 
directly on a NEPI Host device, or on a network connected Linux Ubuntu system for NEPI development.
For the remote system build option, you will first need to configure your remote system for NEPI remote development. 
See the NEPI Remote System Development Setup instructions at [here](NEPI_REMOTE_DEV_SETUP.md).

**NOTE:**  At the end of each of the following sections, the NEPI container at that state will be
committed. If you run into any issues during one of the sections, can restart it from the beginning
which will use the last steps committed container image. 


################################################################
### NEPI Base Container Setup

**RUN THESE STEPS ON A NEPI HOST DEVICE or NEPI REMOTE DEV SYSTEM**

Check for internet connection

    pingi  # "Run 'ninet' on a NEPI Host Device to try and connect if not connected:

Clone the NEPI Engine repo on your development system (NEPI Host Device or NEPI Remote Dev System):

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
Open a terminal on your NEPI Device (or SSH into your NEPI Device from your NEPI Remote Dev System using the terminal command 'sshnh')

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
    source ./nepi_docker_init.sh
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

    export DEPLOY_3RD_PARTY=1
    nepibld
    sudo chown -R nepi:nepi /opt/nepi/


Test Run NEPI. Look for error messages

    nepistart

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

    nepiexport
    nepiimport


