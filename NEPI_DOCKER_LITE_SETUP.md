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

Log into a user account on the device with 'Adminstrator' privilages, **or 'nepihost' if exists**.

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

**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**

The docker lite setup script will run through the following steps NEPI Docker Lite Environment Setup, NEPI Docker Lite Config Setup, and NEPI Docker Init Setup.

### NEPI Docker Lite Environment Setup

This step will configure the NEPI Docker installation using the defualt settings. 
You can change settings later in the 'NEPI Docker Customization' section.

### NEPI Docker Lite Config Setup

This step will configure the NEPI Docker installation using the defualt settings. 
You can change settings later in the 'NEPI Docker Customization' section.

This process will create (if not allready created) and setup the following NEPI Folders:
- **NEPI Storage** folder created at '/mnt/nepi_storage', along with several user subfolders.  
    This is where NEPI processes store user files such as:
        data - **Saved Data**
        ai_models - **AI models**
        nepi_images - **Import/Export Docker Images**
        user_cfg - **User Saved Configurations**
- **NEPI Docker** folder created at '/mnt/nepi_docker'. This is where NEPI Docker Images are stored.
- **NEPI Config** folder created at '/mnt/nepi_config, along with several config subfolders.


**NOTE:**  After this process, the following changes will be made:
1) NEPI bash alias and util functions added to 'nepihost user bash profile.
2) NEPI folder shortcuts added to File Manager folder bookmarks.
3) Chromium browser updated with useful NEPI browser bookmarks.


################################################################
### NEPI Docker Init Setup
This section will initialize and test your NEPI Docker installation.  

Log back into `nepihost` using password 'nepi' 

Check for internet connection

    ping -c 1 google.com

Run the NEPI Docker Storage Initialization script (sudo password is now 'nepi'):

    source /home/nepihost/nepi_setup/scripts/docker_storage_init.sh

Run the NEPI Docker Image Initialization script (sudo password is now 'nepi'):

**NOTE:** This step can take a long time as it involves dowloading several large files from the internet.

    source /home/nepihost/nepi_setup/scripts/docker_image_init.sh

Run the NEPI Docker Import command (sudo password is now 'nepi'):

**NOTE:** This step imports a large NEPI image file into the system which takes several minutes to complete.

    nepiimport

After the import completes, you can print the current installed NEPI Docker Image by typing:


    dimg


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



################################################################
### NEPI Docker Image Testing
This section will start and test your NEPI Docker solution. 

refresh your .bashrc file:

    source ~/.bashrc

Start your NEPI container running:

    nepistart

The start script will let you know if the installed NEPI Image started successfully.

**NOTE** Newly installed NEPI Docker Images may take several attempts to start successfully
the first time after installation.  Try running several times if it fails

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
### NEPI Docker Host Config Setup

While most NEPI device settings like static, alias, and ntp IP addresses are configurable real-time through the RUI (Resident User Interface),
some settings such as User Password, Folders, and SSH Keys must be configured prior to run-time.  You may also want to Factory Reset a NEPI Docker
configuration.

Run the NEPI Docker Host configuration script by typing:

    nepisetup

Make any changes you want using the menu options presented, then choose the 'APPLY SETTINGS' to apply changes, or 'FACTORY RESET' to factory reset your installation.

**NOTE:** The NEPI System Configuration file is located at '/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml'.
For production environments, you can just replace this file with a production ready file, or create a custom production script that make any required changes.

**NOTE:** If you want to setup your Device to support both NEPI Docker Host mode and NEPI Remote Dev System modes, you can switch between these modes
by typing nepisetup_remote and nepisetup_host respectfully.

################################################################
### NEPI GitHub Setup

**OPTIONAL** If you want to get, update, and build NEPI Software from source-code
this section will walk you through the process.

Check or Setup an SSH Key for your GitHub Account by typing the following

    nepigithub

**NOTE:**  If successful, the nepi_engine_ws repo will be cloned to your home folder at ~/nepi_engine_ws.

Aditional command line NEPI Github commands are available

nepiclone = Clone the latest NEPI source-code repo
nepiclonedev = Clone the latest NEPI Development branch source-code repo
nepipull = Update to the latest NEPI source-code repo
nepimain = Switch to the NEPI source-code main repo branch
nepidev = Switch to the NEPI source-code develop repo branch
nepidpl = Deploy nepi source-code to nepi device
nepipush = Push current repo (or submodule repo) if you have push permisions

Other useful NEPI development command line shortcuts.

sshn = SSH into the running NEPI Software Container
sshnh = SSH into the NEPI Software Host System

**NOTE** For instructions on deploying and building NEPI Software from source-code,
see the NEPI Software Build instructions at [here](NEPI_SOFTWARE_BUILD.md)


################################################################
### (OPTIONAL) NEPI Docker Remote PC Connections
If you want to connect to your NEPI device from a remote network connected PC, setup and test a remote connection following these instructions.

**NOTE:** You will manually need to set your NEPI Device's network adapater IPV4 settings to 'Manual' 
with the following values 
    ADDRESS = 192.168.179.103
    NETMADK = 255.255.255.0
Then reboot your NEPI Device and continue to the tutorials listed below.

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

**NOTE:** NEPI Docker Lite Installations do not configure NEPI's Network Shared Drive support, but
the NEPI Storage and NEPI Config Folders, you can access them locally on the NEPI Device at /mnt/nepi_storage and /mnt/nepi_config.

**NOTE:** NEPI Docker Lite Installations do not configure NEPI Host SSH, but do support NEPI Container SSH connections. Learn more about the NEPI Folders content, see this tutorial for remote SSH access.

    SSH into either your NEPI Host device or NEPI running container following this tutorial.
    See a tutorial at [NEPI SSH SETUP](https://nepi.com/nepi-tutorials/nepi-engine-accessing-the-nepi-file-system/)


################################################################
### NEPI Software Tutorials

Learn more about using and configuring the NEPI software, as well as building and deploying 
custom AI Models at nepi.com.

See the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)


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

