# NEPI User PC Setup

This tutorial will walk you through setting up a linux PC for connecting to a NEPI device.

For detailed tutorials on NEPI User PC Setup processes see the "NEPI Getting Started" turoials at:
[NEPI Tutorials](https://www.nepi.com/tutorials)

For additional support, visit the NEPI software community forum at:
[NEPI Community](https://www.community.nepi.com)

### Connect to the Internet
Make sure your PC has internet access

### Install Software Requirments
Install yq:

    sudo add-apt-repository ppa:rmescandon/yq
    wait
    sudo apt update
    wait
    sudo apt install yq -y
    wait

Verify your installation:

    yq --version

### Clone the NEPI Engine Repo
Clone the 'main' branch:

    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout main
    git submodule update --init --recursive

Or, clone the 'development' branch:

    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout develop
    git submodule update --init --recursive


### NEPI PC Bash Setup
Setup NEPI PC bash:

    source /home/${USER}/nepi_engine_ws/nepi_setup/scripts/user_pc_setup.sh
    source ~/.bashrc

See nepi PC functions menu:

    nepihelp

# NEPI Development PC Setup

If you want set up your PC for NEPI software development,
see the instructions "NEPI_DEV_PC_SETUP"


### NEPI Docker Remote PC Connections

Start your NEPI container running:

    nepistart

Check that the Container is running

    dps

If the container is running:

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

Test that you can connect your PC to NEPI Device's 'nepi_storage' folder using your PC's File Manager application. 
See a tutorial at [Accessing the User Storage Drive](https://nepi.com/nepi-tutorials/nepi-engine-user-storage-drive/)






