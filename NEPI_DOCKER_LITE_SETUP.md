# NEPI Docker Lite Setup Instructions
This tutorial will walk you through setting up, configuring, and running a NEPI Docker Lite Installation on a  supported device.

**SUPPORTED DEVICES:** Ubuntu PC, NVIDIA Jetson

NEPI Docker Lite Installations are recommended for PC base installations, trial Edge-Compute processor installations, and NEPI Software development.
With fully-automated NEPI Docker setup processes, it is also recommended for non-experienced linux users.

After testing with the Lite installation, you can upgrade your system to a Full installation for production deployments
with support for both local and remote real-time management of operating system services through User Interface and API controls.
see the NEPI DOCKER FULL SETUP instructions at [here](NEPI_DOCKER_FULL_SETUP.md)

**NOTE:** NEPI Docker installation will require a minimum of 30 GB of available free hard drive space on your device. 
See the 'Check Available Disk Space' section at the end of these instructions for more information on checking available space.


################################################################
## NEPI Docker Lite Setup

This step will setup NEPI Docker required user accounts on your device

Log into a user account on the device with 'Adminstrator' privilages.

Open Terminal Window - Right click on the desktop and select the "Open in Terminal" option.

Make sure your system has internet access by running the following command:

    ping -c 1 google.com

Update Git application:

    sudo apt update && sudo apt install -y git

Clone the NEPI Setup repo:

    cd /home/${USER}
    git clone https://github.com/nepi-engine/nepi_setup.git


Run the NEPI Docker lite setup script:

    cd /home/${USER}/nepi_setup/scripts 

then if prompted enter: `y` or 'yes' :

    source ./docker_lite_setup.sh


This step will configure the NEPI Docker installation using the defualt settings. 
You can change settings later in the 'NEPI Docker Customization' section.

This process will create (if not allready created) and setup the following NEPI Folders:
- **NEPI Storage** folder created at '/mnt/nepi_storage', along with several user subfolders.  
    This is where NEPI processes store user files such as:
        data - **Saved Data**
        ai_models - **AI models**
        nepi_images - **Import/Export Docker Images**
        user_cfg - **User Saved Configurations**
- **NEPI Config** folder created at '/mnt/nepi_config, along with several config subfolders.


**NOTE:**  After this process, the following changes will be made:
1) NEPI bash alias and util functions added to the user bash profile.
2) NEPI folder shortcuts added to File Manager folder bookmarks.
3) Chromium browser updated with useful NEPI browser bookmarks.


**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**

################################################################
### NEPI Docker Init Setup
This section will initialize and test your NEPI Docker installation.  

Log back into the user account on the device with 'Adminstrator' privilages.

Check for internet connection

    ping -c 1 google.com

Run the NEPI Docker Storage Initialization script (sudo password is now 'nepi'):

    source ~/nepi_setup/scripts/docker_storage_init.sh

Run the NEPI Docker Image Initialization script (sudo password is now 'nepi'):

**NOTE:** This step can take a long time as it involves dowloading several large files from the internet.

    source ~/nepi_setup/scripts/docker_image_init.sh

After the import completes, you can print the current installed NEPI Docker Image by typing:


    dimg



################################################################
### NEPI Docker Image Testing
This section will start and test your NEPI Docker solution. 

refresh your .bashrc file:

    sbrc

Start your NEPI container running:

    nepistart

The start script will let you know if the installed NEPI Image started successfully.



**NOTE:** Some additional NEPI Docker command line shortcuts are:

    nepistart = Start the NEPI docker container.
    nepidev = Start the NEPI docker container in a dev mode with no processes running, and an OPTIONAL_RUN_COMMAND.
    nepistop = Stop the running NEPI docker container.
    nepilogin = Log into the running NEPI container as user 'nepi'.
    nepiloginroot = Log into the running NEPI container as user 'root'.
    nepiswitch = Switch to Inactive NEPI container on next boot or reststat.
    nepicommit = Commit the running NEPI container wit provided COMMIT_DESCRIPTION, restarts nepi using new commit unless RESTART=0 is passed .
    nepiinit = Reset, clear, and import new NEPI Image.
    nepiimport = Import a NEPI image .tar file. Optional: Enter a file name or full file path.
    nepiexport = Export the running NEPI container to a .tar file. Enter a file name or full file path.
    nepiload = Import a NEPI image .archive.tar file. Optional: Enter a file name or full file path.
    nepisave = Save the active NEPI Image with all commits to a .archieve.tar file. Enter a file name or full file path.
    nepitag = Update the Software Description field in the active NEPI container.
    nepienable = Enable NEPI Docker service on next boot.
    nepidisable = Disable NEPI Docker service on next boot.
    nepirestart = Restart NEPI docker service.
    nepistatus = Show the systemctl status for nepi_docker service.
    nepilogs = Show live NEPI Docker service journal file.
    nepibld = Build or Update the NEPI Docker File System from source code in ${NEPI_BUILD_REPO_FOLDER}.
    nepiupdate = Run NEPI Docker bash, folders, files, and config update processes.
    nepicreate = Export and Import a new NEPI Docker Image from running container
    nepiprint = Print current NEPI DOCKER and SYSTEM configuration settings."

    # Type **nepihelp** to see all NEPI Software command line shortcuts

**OPEN CHROMIUM WEB BROSWER**
Check that the NEPI Resident User Interface (RUI) is running by opening the Chromium browser and entering the following in the search bar:

    localhost:5003 

This will take you to the NEPI RUI dashboard.  Once the NEPI core software system is running, you should see a blinking Green indicator and messages.
**NOTE:**  RUI Controls related to User, Device, Time, Network, and Software managemnt are not enabled for NEPI Demo installations.

You can also access the NEPI admin page for managing nepi software configurations by entering the following in the search bar:

    localhost:5003/admin

the default admin password is: **nepiadmin**


**NOTE:** If you encounter any issues starting and running the NEPI Software container, 
see the debugging steps in the "NEPI Docker Debugging" section at the end of this document.

################################################################
### NEPI Remote PC Connection

The NEPI Lite Installation does not support a shared network drive or SSH connection to the container. However, you can still connect to the RUI remotely over Ethernet by configuring your PC's network adapter with a static IP on the same subnet as the NEPI device.

NEPI devices ship with a factory-set base Ethernet address of 192.168.179.103. To connect:

1) Connect an Ethernet cable directly from your NEPI device to your PC's Ethernet port (or through a LAN switch).

2) Set your PC's Ethernet adapter to the following static IPv4 address on the same subnet:

    - IP Address: 192.168.179.5
    - Netmask: 255.255.255.0

3) Confirm the connection by pinging the device:

        pingn

4) Once the ping succeeds, open Chromium and enter the device's IP in the address bar to reach the RUI:

        http://192.168.179.103:5003/

**NOTE:** If you can't connect, double check your PC's Ethernet adapter is on the 192.168.179.0/24 subnet and try the ping test again before troubleshooting further (see "NEPI Docker Debugging" below).

If you are running on an embedded device and want to use shared network drives and an SSH connection, follow the NEPI Full Setup instructions instead. Those enable the additional remote management features (SSH access, shared drives, and remote OS-level control). Do not follow the NEPI Full Setup on your personal or general-purpose computer, as it takes over system-level services such as networking, SSH, and storage.

################################################################
### NEPI DOCKER INSTALLATION COMPLETE
################################################################

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

                nepihome = change to NEPI home dir
                nepistart = start the NEPI processes
                nepistop = stop the NEPI processe
                nepibld = Build NEPI bash, config, code repos, and RUI
                codebld = Build NEPI code repos only
                ruibld = Build the RUI only
                nepistatus = Print running status of all NEPI processes
                nepistatus_engine = Print tail of nepi_engine process
                nepistatus_rui = Print tail of nepi_rui process
                nepistatus_license = Print tail of nepi_license process
                nepistatus_ssh = Print tail of nepi_ssh process"

**********************

