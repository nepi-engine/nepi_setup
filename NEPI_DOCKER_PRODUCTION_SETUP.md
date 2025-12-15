# NEPI Docker Production Setup Instructions
This tutorial will walk you through setting up, configuring, and running a NEPI Docker Production installation on a suitable edge processor.

**NOTE:** NEPI Docker Production installation will make significant changes to your device's operating system configuration and 
setup NEPI management of operating system services (i.e. HOSTNAME, NETWORK, WIFI, SSH, DOCKER ...) that support both local and remote
real-time management of these services through User Interface and API controls.

If you want to first try a **DEMO installation** with no NEPI managed operating system services, but all of the other functionality,
see the NEPI DOCKER DEMO SETUP instructions at [here](NEPI_DOCKER_DEMO_SETUP.md)

**If you choose to proceed, make sure you have a way to reflash the device, or backup and restore your device's existing file system if needed.**

**NOTE:** NEPI Docker installation will require a minimum of 40 GB of available free hard drive space. 
See the 'Check Available Disk Space' section at the end of these instructions for more information on checking available space.


For a detailed tutorials and videos on this process see the "NEPI Docker Production Setup" tutorial under the "NEPI Installation" section at:
[NEPI Tutorials](https://www.nepi.com/tutorials)



################################################################
### NEPI Docker User Setup

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


Run the NEPI Docker user setup script (sudo password is #Nsetup4You):

    cd /home/${USER}/nepi_setup/scripts
    sudo su 

then

    ./docker_user_setup.sh


**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**

################################################################
### NEPI Docker Environment Setup

This step will setup NEPI Docker required software environment.

Log into the `nepihost` user using password  'nepi'

Make sure your system has internet access by running the following command:

    ping -c 1 google.com

Clone the NEPI Setup repo:

    cd /home/${USER}
    git clone https://github.com/nepi-engine/nepi_setup.git


Run the NEPI Docker environment setup script (sudo password is now 'nepi')

If prompted enter: `y` or 'yes' :

    /home/nepihost/nepi_setup/scripts/docker_env_setup.sh

**NOTE:** If you get a popup window 'System program problem detected', just hit 'Cancel'

Scroll up through the process messages looking for any errors and correct.  Rerun again if needed.

**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**

################################################################
### NEPI Docker Config Setup

This step will configure the NEPI Docker installation using the defualt settings. 
You can change settings later in the 'NEPI Docker Customization' section.

Log into the `nepihost` user using password  'nepi'
(sudo password is 'nepi')


**OPTIONAL:** IF YOU WANT TO HAVE REMOTE NETWORK ACCESS TO NEPI's STORAGE AND CONFIG FOLDERS
          USING NEPI's BUILT IN SAMBA NETWORK DRIVE SHARING SYSTEM, 
          CREATE THE FOLLOWING MOUNTED PARTIONS BEFORE CONTINUING:

            **NOTE:** If you skip this step, the following folders will be created in your 
            main File System's partition.  Make sure you have at least 60 GB of free space
            on that partition using 'df -h' and checking the 'Avail' column for your
            main File System's patition (i.e. /dev/nvme0n1p1 or something like that)

            **NOTE:** There are many tutorials on line for creating new partitions

            **NOTE:** If you need to reduce the size of your main File System partition to
            free space for the following new partitions, don't reduce it below 40 GB.

            **NOTE:** If these folders allready exist as folders and not mounted partitions,
            you should delete them before creating and mounting the following partitions.
            
             FILE_SYSTEM   LABEL_NAME      MOUNT_POINT       MIN_SIZE     RECOMMENDED_SIZE 
            1)  ext4      nepi_docker     /mnt/nepi_docker    30 GB           100 GB
            2)  ext4      nepi_config     /mnt/nepi_config    200 MB          200 MB
            3)  ext4      nepi_config     /mnt/nepi_storage   30 GB           150+ GB


Run the NEPI Docker configuration setup script (sudo password is now 'nepi'):

    source /home/nepihost/nepi_setup/scripts/docker_config_setup.sh

This process will create (if not allready created) and setup the following NEPI Folders:
- **NEPI Storage** folder created at '/mnt/nepi_storage', along with several user subfolders.  
    This is where NEPI processes store user files such as:
        **Saved Data**, **AI models**, **Import/Export Docker Images**, and **User Saved Configurations**.
- **NEPI Docker** folder created at '/mnt/nepi_docker'. This is where NEPI Docker Images are stored.
- **NEPI Config** folder created at '/mnt/nepi_config, along with several config subfolders.


**NOTE:**  After this process, the following changes will be made:
1) Desktop background and sidebar applications menu updates.
2) NEPI bash alias and util functions added to 'nepihost user bash profile.
3) NEPI folder shortcuts added to File Manager folder bookmarks.
4) Chromium browser updated with useful NEPI browser bookmarks.



**NOTE:** After this process, network IP addresses, internet connections, and clock sycn processes are managed by NEPI processes. 
    If you need to connect to the internet you can run the command line shortcut **ninet**

Test that you can reconnect to the internet and sync clocks:

    ninet

Check for internet connection

    pingi

**NOTE:** Some additional NEPI utility command line shortcuts are:

    pingi = ping internet test
    nipa= Echo NEPI set IP address
    naipa= Echo NEPI set IP alias addresses
    nnipa= Echo NEPI set NTP IP addresses
    nnet = Restart the network
    ndhcp = Enable DHCP Internet Client
    nclock = Sync clock
    ninet = Restart network, connect to internet, and sync clock
    cuda_version = Echos Cuda version number if cuda availble or 0
    fix_chromium = Fix any Chromium config issues
    sbrc = Source the current user's bashrc files

    # Type **nepihelp** to see all NEPI Docker command line shortcuts

**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**


################################################################
### NEPI Docker Init Setup
This section will initialize and test your NEPI Docker solution.  

Log back into `nepihost` using password 'nepi' 

Enable internet connection and sync clocks:

    ninet

Check for internet connection

    pingi


Run the NEPI Docker Storage initialization script (sudo password is now 'nepi'):
**NOTE:** This script will download the latest NEPI Docker Image for your system's
architecture NEPI Docker's import folder at /mnt/nepi_storage/nepi_images.

    source /home/nepihost/nepi_setup/scripts/docker_storage_init.sh

Run the NEPI Docker Image initialization script (sudo password is now 'nepi'):
**NOTE:** This script will download the Demo AI models, AI training scripts, 
sample data files, and user_configurations to folders in /mnt/nepi_storage.

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
    nepiupdate = Run NEPI Docker bash, folders, files, and config update processes.
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

    nepienable

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

**NOTE:** For Linux and Mac PC's, run through the NEPI Dev PC Setup first following the
instructions at [here](NEPI_DEV_PC_SETUP.md). 

**NOTE:** For Windows PC's just follow the instructions provided in the turial links below.

Test that you can connect to your running conatiner from a network connected PC.
See a tutorial at [Connecting and Setup](https://nepi.com/nepi-tutorials/nepi-engine-connecting-and-setup/)

**NOTE:** If you skipped setting up seperate mounted partitions for the NEPI Folders in the NEPI Docker Config Setup section, 
then the NEPI Storage and NEPI Config drives will only be available locally on the NEPI Device at /mnt/nepi_storage and /mnt/nepi_config.
Learn more about the NEPI Folders content, see this torial for remote access.

   Test that you can connect your PC to NEPI Device's 'nepi_storage' folder using your PC's File Manager application. 
   See a tutorial at [Accessing the User Storage Drive](https://nepi.com/nepi-tutorials/nepi-engine-user-storage-drive/)

SSH into either your NEPI Host device or NEPI running container following this tutorial.
See a tutorial at [NEPI SSH SETUP](https://nepi.com/nepi-tutorials/nepi-engine-accessing-the-nepi-file-system/)

################################################################
### NEPI Software Tutorials

Learn more about using and configuring the NEPI software, as well as building and deploying custom AI Models
at nepi.com.

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
### NEPI Container Build

If you need to build a NEPI Docker Container from scratch for a particular installation environment,
you can do so starting with a sutable Ubuntu container for the device's environment:

See NEPI Container Build instructions at [here](NEPI_BUILD_CUSTOMIZE.md)


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

