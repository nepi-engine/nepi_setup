# NEPI User PC Setup

This tutorial will walk you through setting up a Linux or MAC PC for connecting to a NEPI device. 

**NOTE:** For Window's PC's you can still connect and interact with the NEPI Device following the setup tutorials in the last section,
but if you want to do actual NEPI Software development on your Windows PC, 
you will first need to install and start a Ubuntu Virtual Environment on your PC with 
both internet and either Wired or WiFi access from within the virtual environment.  There are many good 
online tutorials on this process such as https://automaticaddison.com/how-to-install-ubuntu-22-04-virtual-machine-on-a-windows-pc/

For detailed tutorials on NEPI User PC Setup processes see the "NEPI Getting Started" turoials at:
[NEPI Tutorials](https://www.nepi.com/tutorials)

For additional support, visit the NEPI software community forum at:
[NEPI Community](https://www.community.nepi.com)


################################################################
### Create a NEPI Dev User Account

On your PC, create a new user account nameed 'nepidev' with 'administrator' privileges


################################################################
### NEPI Dev User Account Setup

Log into your 'nepidev' user account


Update Git application (sudo password is #Nsetup4You):

    sudo apt update && sudo apt install -y git

Clone the NEPI setup repo:

    cd /home/${USER}
    git clone https://github.com/nepi-engine/nepi_setup.git


Run the NEPI User PC Setup script:

    source /home/${USER}/nepi_setup/scripts/user_pc_setup.sh
    source ~/.bashrc

See the NEPI PC command line shortcuts menu:

    nepihelp


################################################################
### NEPI Remote PC Connections Tutorials

Setup and test your network or WiFi connected PC connection to your NEPI device following these instructions.

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

Test that you can connect your PC to NEPI Device's 'nepi_storage' folder using your PC's File Manager application. 
See a tutorial at [Accessing the User Storage Drive](https://nepi.com/nepi-tutorials/nepi-engine-user-storage-drive/)

SSH into either your NEPI Host device or NEPI running container following this tutorial.
See a tutorial at [NEPI SSH SETUP](https://nepi.com/nepi-tutorials/nepi-engine-accessing-the-nepi-file-system/)


################################################################
### NEPI Remote PC Software Developent Tutorials

See the NEPI Software Build instructions at [here](NEPI_SOFTWARE_BUILD.md)


