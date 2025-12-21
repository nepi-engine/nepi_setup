# NEPI Dev PC Setup

This tutorial will walk you through setting up a NEPI software development environment. 
The last section provides instructions for deploying and building NEPI from source for developers
wanting the latest development version or deploying customized solutions.

**NOTE:** NEPI Dev PC Setup supports can be performed on the following:
1) Ubuntu Linux PC connected to a NEPI Device over a wired or WiFi connection
2) NEPI device itself
3) Windows or MAC PC running a Ubuntu Linux Virtual Environment (See the NOTE below)


**NOTE:** for Windows and MAC PC's, you will first need to install and start a Ubuntu Virtual Environment with 
network access from within the virtual environment.  There are many good 
online tutorials on this process such as https://automaticaddison.com/how-to-install-ubuntu-22-04-virtual-machine-on-a-windows-pc/

For detailed tutorials on NEPI User PC Setup processes see the "NEPI Getting Started" turoials at:
[NEPI Tutorials](https://www.nepi.com/tutorials)

For additional support, visit the NEPI software community forum at:
[NEPI Community](https://www.community.nepi.com)

################################################################
### NEPI Dev PC Setup

Update Git application (sudo password is #Nsetup4You):

    sudo apt update && sudo apt install -y git

Clone the NEPI setup repo:

    cd /home/${USER}
    git clone https://github.com/nepi-engine/nepi_setup.git


Run the NEPI Dev PC Setup script:

    bash /home/${USER}/nepi_setup/scripts/dev_pc_setup.sh
    source ~/.bashrc

See the NEPI PC command line shortcuts menu:

    nepihelp

################################################################
### NEPI Remote PC Connections Tutorials

**NOTE:** The following section only applies to PC connected Dev Systems.  
If you are running your NEPI Dev environment on a NEPI Device, you can skip this section.

Setup and test your network or WiFi connected PC connection to your NEPI device following these instructions.

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

Test that you can connect your PC to NEPI Device's 'nepi_storage' folder using your PC's File Manager application. 
See a tutorial at [Accessing the User Storage Drive](https://nepi.com/nepi-tutorials/nepi-engine-user-storage-drive/)

SSH into either your NEPI Host device or NEPI running container following this tutorial.
See a tutorial at [NEPI SSH SETUP](https://nepi.com/nepi-tutorials/nepi-engine-accessing-the-nepi-file-system/)


################################################################
### NEPI GitHub PC Setup

##OPTIONAL## If you need to clone the NEPI source-code GitHub repo for your development efforts,
  this section will walk you through the github account and ssh key setup process.


Create a user account at www.github.com if you don't allready have one.


Run the NEPI GitHub PC Setup script:

    bash /home/${USER}/nepi_setup/scripts/dev_github_setup.sh

##NOTE:## If the script failes to authenticate a GitHub SSH connection, 
    follow the printed instructions to configure your GitHub account with
    the provided SSH Key information.

Clone (or Update) the NEPI source-code repo to your machine with one the following options:

Clone the 'main' branch:

    cd ~/
    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout main
    git submodule update --init --recursive

Or, clone the 'development' branch:

    cd ~/
    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout develop
    git submodule update --init --recursive

If you just need to pull the latest updates to an existing cloned NEPI repo:

    cd ~/nepi_engine_ws
    git pull --recurse-submodules



################################################################
### NEPI Remote PC Software Developent Tutorials

See the NEPI Software Build instructions at [here](NEPI_SOFTWARE_BUILD.md)


