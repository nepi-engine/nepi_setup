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
### NEPI GitHub SSH Key Setup

**OPTIONAL** If you need to clone the NEPI source-code GitHub repo for your development efforts,
  this section will walk you through the github account and ssh key setup process.


**NOTE** If you don't allready have a github user account, create a user account at www.github.com.

**NOTE** If you don't allready have a github ssh private key setup on your dev PC, log into your account. 
You will be adding an passkey to the account later in this process.


Run the NEPI GitHub PC Setup script which will check for a valid github ssh key and create one if none available:

    bash /home/${USER}/nepi_setup/scripts/dev_github_setup.sh

**NOTE:** If the script fails to authenticate a GitHub SSH connection, 
    follow the printed instructions to configure your GitHub account with
    the provided SSH Key information.

################################################################
### NEPI AI Training Software Setup

**OPTIONAL** If you need to label image data and traing custom AI models, 
this section will walk you through installing the labelImg software.


Run the NEPI Annotation PC Setup script:

    bash /home/${USER}/nepi_setup/scripts/dev_ai_train_setup.sh

**NOTE:** After this process both label-studio and labelImg software packages will be installed.

Test that labelImg opens:

    labelImg

Test that label-studio opens:

    label-studio


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
### NEPI Dev PC Software Developent Tools

The NEPI Dev PC setup process includes a number of command line
shortcuts to accelerate NEPI software development.

sshn = SSH into NEPI Software System
sshnh = SSH into NEPI Software Host System
nepidpl = Deploy nepi source-code to nepi device

See complete NEPI PC command line shortcuts menu:

    nepihelp

################################################################
### NEPI Dev PC Software Developent Tools

See the NEPI Software Build instructions at [here](NEPI_SOFTWARE_BUILD.md)


