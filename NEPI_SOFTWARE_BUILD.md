# NEPI Software Build Setup Instructions
This tutorial will walk you through updating, modifying. and building NEPI Software running in a NEPI Docker Container.

For additional support, see the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)


################################################################
### NEPI Source-Code Repository Setup

**RUN THESE STEPS ON A NEPI HOST DEVICE or NEPI DEV PC**

**NOTE:**  You can run the following NEPI Software Build steps either 
directly on a NEPI Host device, or on a network connected Linux Ubuntu Remote PC for NEPI development.
For the Remote PC  build option, you will first need to configure your PC for NEPI development. 
See the NEPI Development PC Setup instructions at [here](NEPI_DEV_PC_SETUP.md).


Check or Setup an SSH Key for your GitHub Account by typing the following

    nepigithub

Clone the nepi_engine_ws repo to your system.

    nepiclone

**NOTE:**  If successful, the nepi_engine_ws repo will be cloned to your home folder at ~/nepi_engine_ws.

Aditional command line NEPI Github commands are available

nepiclone = Clone the latest NEPI source-code repo
nepiclonedev = Clone the latest NEPI Development branch source-code repo
nepipull = Update to the latest NEPI source-code repo
nepimain = Switch to the NEPI source-code main repo branch
nepidev = Switch to the NEPI source-code develop repo branch
nepidpl = Deploy nepi source-code to nepi device

Other useful NEPI development command line shortcuts.

sshn = SSH into the running NEPI Software Container
sshnh = SSH into the NEPI Software Host System


################################################################
### NEPI Software Deploy, Build, and Test Process

**RUN THESE STEPS YOUR NEPI DEV PC**
Check network connection to the NEPI HOST Device

    pingn # Ctrl-C to stop

Deploy the NEPI Source Code to the Device 

    nepidpl

**RUN THESE STEPS IN THE NEPI HOST**
Open a terminal on your NEPI Device (or SSH into your NEPI Device from your NEPI Dev PC using the terminal command 'sshnh')

Run the NEPI Docker Build processes to update your NEPI Docker files (password is 'nepi'):

    nepibld
    dps # Show running NEPI container

Start a NEPI container running in dev mode (password is 'nepi'):

    nepistart # OR 'nepidev' if the container fails to run
    dps # Show running NEPI container


Log into the running NEPI container (password is 'nepi'):

    nepilogin # OR 'nepidev' if the container fails to run

**NOTE:** You can also ssh directly into a running NEPI Container from you PC using the command line shortcut 'sshn'.

**RUN THESE STEPS IN THE NEPI CONTAINER**
Run the NEPI Software Build processes to update your NEPI Container software files (password is 'nepi'):

    nepibld
    dps # Show running NEPI container

If you don't see any FATAL errors, then test the NEPI software by running:

    nepistart

Look for any NEPI software error messages. 

**NOTE:**  You can store your modified NEPI Container software changes any time during development and pick up at a later time
by commiting the current running NEPI Container with your changes.  Just type:

    nepicommit # This will commit with an HoursMinutes tag. You can also pass a short custom tag like "dev1" 

    **NOTE:** Once committed, 'nepistart' and 'nepidev' commands will use the commited container.  You can revert back
    to the original of an earlier commited container image by deleting one or more commits using:


        # Then run 'nepistart' or 'nepidev' to run the most recent NEPI container still installed.
        

################################################################
### NEPI Software Modification Process

This section covers modifying NEPI Software source code
**NOTE:** If you just want to update your NEPI Docker Container's software, you can skip this section

**RUN THESE STEPS ON A NEPI HOST DEVICE or NEPI DEV PC**


**NOTE:** There are several good tutorials related to NEPI Software customization available in the 'NEPI Customization' turoials page at:
https://nepi.com/tutorials/




**NOTE:** If you find errors in the code, you can resolve one of two ways.
Make changes to the source code on your PC, then
1) Repeat Software Deploy and Software Build steps below.
2) Deploy and Test quick fixes by opening a terminal in the folder containing the updated source code,
   then use one of the NEPI SFTP command line shortcuts to log into the appropriate folder on the NEPI Device,
  (i.e. 'sdk' for SDK source code folder changes), then use the 'put *' command to deploy the folder files directly.
Then rerun the "nepistart" command to retest in the container to test your fixes.



################################################################
### NEPI Container Create Process

**RUN THESE STEPS IN THE NEPI HOST**
Once you are happy with the NEPI Software changes, you can create, deploy, and import your new NEPI Docker Image (password is 'nepi'):

    nepistart
    dps # Show running NEPI container

Export and Import the new NEPI Docker Image from the running NEPI Container (password is 'nepi'):

**NOTE** Unless your NEPI Host Device is configured with NEPI's AB File System enabled,
the current NEPI Docker Image and all of it's commits will be replaced with the imported image.

    nepicreate # OR 'nepiexport' to just export the new image without importing back in



