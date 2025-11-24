# NEPI Docker Build Setup Instructions
This tutorial will walk you through rebuilding NEPI Software in a running NEPI Docker Container on a suitable edge processor.

For additional support, see the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)


################################################################
### NEPI Software Repository Setup

**NEPI DEV PC**

Clone the NEPI Engine repo on your development system (NEPI Device or NEPI Dev PC):

    cd /home/${USER}
    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout main
    git submodule update --init --recursive

Check network connection to the NEPI HOST Device

    pingn # Ctrl-C to stop

Deploy the NEPI Source Code to the Device 

    nepidpl

**RUN THESE STEPS IN THE NEPI HOST**
Open a terminal on your NEPI Device (or SSH into your NEPI Device from your NEPI Dev PC using the terminal command 'sshnh')

Run the NEPI Docker Build processes to update your NEPI Docker files (password is 'nepi'):

    nepibld
    dps # Show running NEPI container


Initialize a Docker with a NEPI Base Image
**NOTE** Unless your NEPI Host Device is configured with NEPI's AB File System enabled,
the current NEPI Docker Image and all of it's commits will be replaced with the imported image.
If you have an installed NEPI Docker Image that you want to preserve, run 'nepiexport' first.

    nsetup # Switch to nepi setup repo folder
    source ./nepi_docker_init
    dimg # Show installed base image

Start a NEPI container running in dev mode (password is 'nepi'):

    nepistart # OR 'nepidev' if the container fails to run
    dps # Show running NEPI container


Log into the running NEPI container (password is 'nepi'):

    nepilogin # OR 'nepidev' if the container fails to run

**RUN THESE STEPS IN THE NEPI CONTAINER**
Run the NEPI Build:


Run the NEPI Software Build processes to update your NEPI Software Container files (password is 'nepi'):

    nepibld
    dps # Show running NEPI container

If you don't see any FATAL errors, then start NEPI engine software:

    nepistart

Look for any NEPI software error messages. 

***NOTE:*** If you find errors in the code, you can resolve one of two ways.
Make changes to the source code on your PC, then
1) Repeat deploy and build steps above.
2) Deploy and Test quick fixes by opening a terminal in the folder containing the updated source code,
   then use one of the NEPI SFTP command line shortcuts to log into the appropriate folder on the NEPI Device,
  (i.e. 'sdk' for SDK source code folder changes), then use the 'put *' command to deploy the folder files directly.

Then run nepistart in your NEPI device to test your changes.



################################################################
### NEPI Container Create

**RUN THESE STEPS IN THE NEPI HOST**
Restart the NEPI container running in production mode now using the latest commit (password is 'nepi'):

    nepistart
    dps # Show running NEPI container

Export and Import the new NEPI Docker Image from the running NEPI Container (password is 'nepi'):

**NOTE** Unless your NEPI Host Device is configured with NEPI's AB File System enabled,
the current NEPI Docker Image and all of it's commits will be replaced with the imported image.

    nepicreate # OR 'nepiexport clean' to just export the new image without importing



