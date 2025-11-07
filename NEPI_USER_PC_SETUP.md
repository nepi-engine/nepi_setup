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

    ./setup/scripts/pc_bash_setup.sh
    source ~/.bashrc

See nepi PC functions menu:

    nepihelp

### NEPI PC Environment Setup
Setup NEPI PC environment:

    ./setup/scripts/pc_env_setup.sh



### NEPI PC Config Setup
Setup NEPI PC configuration:

    ./setup/scripts/pc_config_setup.sh


NEPI USER PC SETUP COMPLETE


# NEPI Development PC Setup

If you want set up your PC for NEPI software development,
see the instructions "NEPI_DEV_PC_SETUP"




