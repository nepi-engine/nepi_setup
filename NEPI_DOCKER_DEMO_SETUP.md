# NEPI Docker Demo Setup Instructions
This tutorial will walk you through setting up, configuring, and running a NEPI Docker Demo installation on a suitable edge processor.


**NOTE:** NEPI Docker Demo installation will make minimal changes to your device's operating system configuration with
no NEPI management of operating system services (i.e. HOSTNAME, NETWORK, WIFI, SSH, DOCKER ...) 

After testing with the Demo installation, you can upgrade your system to a Production installation with support for both local and remote
real-time management of operating system services through User Interface and API controls.
see the NEPI DOCKER PRODUCTION SETUP instructions at [here](NEPI_DOCKER_PRODUCTION_SETUP.md)


**NOTE:** NEPI Docker installation will require a minimum of 60 GB of available free hard drive space. 
See the 'Check Available Disk Space' section at the end of these instructions for more information on checking available space.

For a detailed tutorials and videos on this process see the "NEPI Docker Demo Setup" tutorial under the "NEPI Installation" section at:
[NEPI Tutorials](https://www.nepi.com/tutorials)


################################################################
### NEPI Docker Demo Setup

This step will setup NEPI Docker required user accounts, folders, files, software, system configurations.

Log into a user account on the device with 'Adminstrator' privilages, **or 'nepihost' if exists**.

Open Terminal Window - Right click on the desktop and select the "Open in Terminal" option.

Make sure your system has internet access by running the following command:

    ping -c 1 google.com

Update Git application:

    sudo apt update && sudo apt install -y git

Clone the NEPI Setup repo:

    cd /home/${USER}
    git clone https://github.com/nepi-engine/nepi_setup.git


Run the NEPI Docker user setup script (sudo password is #Nsetup4You):

    cd /home/${USER}/nepi_setup/scripts
    sudo su 

then

    ./docker_demo_setup.sh


**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**


################################################################
### NEPI Docker Init Setup
This section will initialize and test your NEPI Docker installation.  

Log back into `nepihost` using password 'nepi' 

Check for internet connection

    pingi


Run the NEPI Docker Storage initialization script (sudo password is now 'nepi'):
**NOTE:** This script will download the Demo AI models, AI training scripts, 
sample data files, and user_configurations to folders in /mnt/nepi_storage.

    source /home/nepihost/nepi_setup/scripts/docker_storage_init.sh

Run the NEPI Docker Image initialization script (sudo password is now 'nepi'):
**NOTE:** This script will download the latest NEPI Docker Image for your system's
architecture NEPI Docker's import folder at /mnt/nepi_storage/nepi_images.


    source /home/nepihost/nepi_setup/scripts/docker_image_init.sh

Initialize NEPI Docker with an the downloaded NEPI Image:

    nepiinit

After the initialization script completes, you can print the current installed NEPI Docker Images by typing:

    dps

**NOTE:** Some additional NEPI Docker command line shortcuts are:

    nepistart = Start the NEPI docker container.
    nepidev = Start the NEPI docker container in a dev mode with no processes running, and an OPTIONAL_RUN_COMMAND.
    nepistop = Stop the running NEPI docker container.
    nepilogin = Log into the running NEPI container as user 'nepi'.
    nepiloginroot = Log into the running NEPI container as user 'root'.
    nepiswitch = Switch to Inactive NEPI container on next boot or reststat.
    nepicommit = Commit the running NEPI container.
    nepiinit = Reset, clear, and import new NEPI Image.
    nepiimport = Import a NEPI image .tar file. Optional: Enter a file name or full file path.
    nepiexport = Export the running NEPI container to a .tar file. Enter a file name or full file path.
    nepiload = Import a NEPI image .archive.tar file. Optional: Enter a file name or full file path.
    nepisave = Save the active NEPI Image with all commits to a .archieve.tar file. Enter a file name or full file path.
    nepipull = Import a NEPI image from a remote repository given the PULL_URL.
    nepitag = Update the Software Description field in the active NEPI container.
    nepiconfig = Configure NEPI System settings.
    nepienable = Enable NEPI Docker service on next boot.
    nepidisable = Disable NEPI Docker service on next boot.
    nepirestart = Restart NEPI docker service.
    nepistatus = Show the systemctl status for nepi_docker service.
    nepilogs = Show live NEPI Docker service journal file.
    nepireset = Reset all NEPI Config Folders.
    nepibld = Build or Update the NEPI Docker File System from source code in $HOME/nepi_setup repo.
    nepiupdate = Run update process on NEPI Docker config file.
    nepicreate = Export and Import a new NEPI Docker Image from running container
    nepiprint = Print current NEPI DOCKER and SYSTEM configuration settings.

    # Type **nepihelp** to see all NEPI Software command line shortcuts


################################################################
### NEPI Docker Image Testing
This section will start and test your NEPI Docker solution. 


Start your NEPI container running:

    nepistart

The start script will let you know if the installed NEPI Image started successfully. 

**NOTE:** If you encounter any issues starting and running the NEPI Software container, 
see the debugging steps in the "NEPI Docker Debugging" section at the end of this document.


**OPEN CHROMIUM WEB BROSWER**
Check that the NEPI Resident User Interface (RUI) is running by opening the Chromium browser and entering the following in the search bar:

    localhost:5003 

This will take you to the NEPI RUI dashboard.  Once the NEPI core software system is running, you should see a blinking Green indicator and messages.
**NOTE:**  RUI Controls related to User, Device, Time, Network, and Software managemnt require the NEPI Docker service running.



################################################################
### NEPI Docker Service Setup

If everthing is working, you can enable the NEPI Docker Service which will automatically start the NEPI Container and Software on boot:

    nepienable # You can disable the NEPI Docker Service with 'nepidisable'

**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**

Log back into `nepihost` using password 'nepi' 

Check that your NEPI Container is running after reboot:

    dps

    #If your container is not running, try to debug NEPI Docker Service issues with the following commands:

        nepirestart
        nepistatus
        nepilogs


################################################################
### NEPI Docker Remote PC Connections
Setup and test a network connected PC connection to your NEPI device following these instructions.

**NOTE:** You will manually need to set your NEPI Device's network adapater IPV4 settings to 'Manual' 
with the following values 
    ADDRESS = 192.168.179.103
    NETMADK = 255.255.255.0
Then reboot your NEPI Device and continue to the tutorials listed below.

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

**NOTE:** While NEPI Docker Demo Installations do not support network access to
the NEPI Storage and NEPI Config Folders, you can access them locally on the NEPI Device at /mnt/nepi_storage and /mnt/nepi_config.
Learn more about the NEPI Folders content, see this torial for remote access.

   Test that you can connect your PC to NEPI Device's 'nepi_storage' folder using your PC's File Manager application. 
   See a tutorial at [Accessing the User Storage Drive](https://nepi.com/nepi-tutorials/nepi-engine-user-storage-drive/)

SSH into either your NEPI Host device or NEPI running container following this tutorial.
See a tutorial at [NEPI SSH SETUP](https://nepi.com/nepi-tutorials/nepi-engine-accessing-the-nepi-file-system/)

################################################################
### NEPI Software Tutorials

Learn more about using and configuring the NEPI software, as well as building and deploying 
custom AI Models at nepi.com.

See the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)


################################################################
### NEPI Docker Customization

While most NEPI device settings are configurable real-time through the RUI (Resident User Interface),
you can configure NEPI Docker's custom run-time settings following these instructions:

See NEPI Docker Customization instructions at [here](NEPI_DOCKER_CUSTOMIZE.md)

################################################################
### NEPI Container Customization

You can update or custimize the NEPI software running in a NEPI Docker Container from source code,
then export it as a new sharable NEPI Docker Container:

See NEPI Container Customization instructions at [here](NEPI_CONTAINER_CUSTOMIZE.md)


################################################################
### NEPI DOCKER INSTALLATION COMPLETE
################################################################


### NEPI Docker Installation Notes
The NEPI Docker system provides a full-featured AI and automation software environment that installs on top of your host device's native operating system.  To achieve this, the NEPI Docker solution interacts with the device's configuration. While the NEPI Docker installation privdes functions for reverting back to your orignal system configurations, it is recommended that you create a backup of your current device's hardrive to a seperate backup SSD card to ensure you are able to recover your original system if issues arise.  This can be done using a low cost SSD cloning device such as [Rosewill SSD Cloner](https://www.amazon.com/Duplicator-Enclosure-Clone-RS-N2-CL-PC-Mac-Android/dp/B0F51MMN7Q/?th=1) as long as you are cloning to the same SSD card type.


### Check Available Disk Space
Before proceeding, make sure you device has the minimum free space (60 GB) required for NEPI Docker installation and run-time processes.  

**NOTE:** If you don't have the minimum required free space to proceed, there are several options available:
1) Delete unneeded files and clean your current file system to open up additional free space.
3) Upgrade to a larger SSD by cloning your current SSD to a larger SSD hard drive using an SSD clone device that support's cloning to larger disks such as [StarTech SSD Cloner](https://www.amazon.com/StarTech-com-Duplicator-90GBpm-Standalone-Dual-Bay/dp/B0D37ZJFND/ref=sr_1_2_sspa).
Then run gparted to increase your file systems available space


### NEPI Docker Debugging

**********************
DEBUGGING NEPI Container Issues
**********************

If you NEPI Image failed to start, you can try to run it in a dev mode without any NEPI services started

    nepidev

    # Then log into to the running NEPI container check NEPI process statuses by typing:

    nepilogin

    # Once Inside the container, start the NEPI services running:

        /nepi_start_all

        # Once Inside the container, start and stop the NEPI software 

            nepistatus

            # Check if any of the NEPI services are not running in the printout. If any are not running, 
            # you can examine the process messages by running one of the following status commants:

            nepistatus_engine

            nepistatus_rui

            nepistatus_license

            nepistatus_ssh

            # To bug issues with the core NEPI Engine software process, you can start and stop NEPI Engine to visually look for run-time errors:

            nepistop
            nepistart

            **NOTE:** Some additional NEPI Software command line shortcuts are:

                nepihome = change to nepi home dir
                nepistart = start the nepi processes
                nepistop = stop the nepi processe
                nepiconfig = Configure NEPI System Settings
                nepibld = Build and deploy all nepi repos and RUI
                codebld = Build and deploy all nepi repos
                ruibld = Build and deploy rui system
                nepistatus = Print running status of all NEPI processes
                nepistatus_engine = Print tail of nepi_engine process
                nepistatus_rui = Print tail of nepi_rui process
                nepistatus_license = Print tail of nepi_license process
                nepistatus_ssh = Print tail of nepi_ssh process

**********************

