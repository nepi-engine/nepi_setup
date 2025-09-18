# NEPI Development PC Setup

This tutorial will walk you through setting up a linux PC for doing NEPI code development.

### Connect to the Internet
Make sure your PC has internet access

### Install Software Requirments
Install yq:

    sudo add-apt-repository ppa:rmescandon/yq
    sudo apt update
    sudo apt install yq -y

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


### NEPI PC Environment Setup
Setup NEPI PC environment:

    ./setup/scripts/pc_env_setup.sh

When prompted to add keyring select `yes`

### NEPI PC Config Setup
Setup NEPI PC configuration:

    ./setup/scripts/pc_config_setup.sh

### NEPI PC Getting Started
Read the "Getting Started Tutorials" at:

- [Getting Started Tutorials](https://nepi.com/tutorials/)

### NEPI Developers Formum
Get answers at the NEPI Cummunity site:

- [NEPI Community](https://community.nepi.com)



