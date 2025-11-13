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

You can run the following NEPI container build steps either 
directly on a NEPI Host device, or on a netork connected Linux Ubuntu PC for NEPI development.

**NOTE:**  For the PC build option, you will first need to configure your PC for NEPI development. 
See the NEPI Development PC Setup instructions at [here](NEPI_DEV_PC_SETUP.md)


################################################################
### NEPI Base Container Setup

**RUN THESE STEPS IN THE NEPI HOST**
Open a terminal on your NEPI Device (or SSH into your NEPI Device from your PC):

Enable internet connection and sync clocks:

    ninet

Check for internet connection

    pingi

Clone the NEPI Engine repo on your development system (NEPI Device or PC):

    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout main
    git submodule update --init --recursive

Deploy the NEPI Source Code to the Device 

    nepidpl

Initialize a Docker with a NEPI Base Image

    nsetup # Switch to nepi setup repo folder
    source ./nepi_docker_init
    dimg # Show installed base image

Start a NEPI container running in dev mode

    nepidev
    dps # Show running NEPI container

Export your NEPI Base container.

    nepiexport

**NOTE**  If you run into issues and need to try the remaining setup steps,
you can reimport the exported NEPI Base Image using 'nepiimport' command,
and selecting this exported image file.

Log Into the NEPI container as root

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

Commit your NEPI container with a description

    nepicommit "user_setup"



################################################################
### NEPI Container User Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**
Check for internet connection:

    pingi

Change to the NEPI Source Code folder:

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts

Run the NEPI Bash Setup script:

    source ./nepi_bash_setup.sh

Run the NEPI Folders Setup script:

    source ./nepi_folders_setup.sh

Run the NEPI Environmant Setup script:

    source ./nepi_env_setup.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description

    nepicommit "env_setup"



################################################################
### NEPI Container Environment Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**
Check for internet connection:

    pingi

Change to the NEPI Source Code folder:

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts

Run the ROS Environmant Setup script:

    source ./ros_setup.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description

    nepicommit "ros_setup"


################################################################
### NEPI Container ROS Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**
Check for internet connection:

    pingi 

Change to the NEPI Source Code folder:

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts

Run the NEPI Config Setup script:

    source ./nepi_config_setup.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description

    nepicommit "config_setup"


################################################################
### NEPI Container Software Setup

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**
Start the NEPI Build from Source process:

    nepibld

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST


**RUN THESE STEPS IN THE NEPI HOST**
Commit your NEPI container with a description

    nepicommit "software_setup"


################################################################
### NEPI Container Software Testing

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in dev mode now using the latest commit

    nepidev
    dps # Show running NEPI container

Log Into the NEPI container as nepi

    nepilogin

YOU ARE NOW IN THE NEPI CONTAINER

**RUN THESE STEPS IN THE NEPI CONTAINER**

Change to the NEPI Source Code folder:

    cd /mnt/nepi_storage/nepi_src/nepi_engine_ws/nepi_setup/scripts

Run the NEPI Config Setup script:

    source ./nepi_tests.sh

Log out of the container

    exit

YOU ARE NOW IN THE NEPI HOST



################################################################
### NEPI Container Deploy

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in production mode now using the latest commit

    nepistart
    dps # Show running NEPI container

Export the new NEPI Docker Image

    nepiexport clean

Import the new NEPI Docker Image*
**NOTE** Unless your NEPI Host Device is configured with NEPI's AB File System enabled,
the current NEPI Docker Image and all of it's commits will be replaced with the imported image.

    nepiimport


