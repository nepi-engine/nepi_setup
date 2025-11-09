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

### Clone the NEPI SETUP Repo
This step will clone the NEPI Setup github repo to the nepihost user home folder.


Update Git application (sudo password is #Nsetup4You):

    sudo apt update && sudo apt install -y git

Clone the NEPI setup repo:

    cd /home/${USER}
    git clone https://github.com/nepi-engine/nepi_setup.git



### NEPI PC Setup
This step configures a network connected PC to communicate with a NEPI Device:

    source /home/${USER}/nepi_setup/scripts/user_pc_setup.sh
    source ~/.bashrc

See the NEPI PC command line shortcuts menu:

    nepihelp

### NEPI Development PC Setup

If you want set up your PC for NEPI software development,
see the instructions "NEPI_DEV_PC_SETUP"


### NEPI Remote PC Connections

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

Test that you can connect your PC to NEPI Device's 'nepi_storage' folder using your PC's File Manager application. 
See a tutorial at [Accessing the User Storage Drive](https://nepi.com/nepi-tutorials/nepi-engine-user-storage-drive/)






