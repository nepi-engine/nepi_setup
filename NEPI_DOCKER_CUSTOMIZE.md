# NEPI Docker Customization Instructions
This tutorial will walk you through customizing settings a NEPI Docker installation.

For additional support, see the documentation, tuturials, videos, and community forum available at NEPI.com:
[NEPI Website](https://www.nepi.com)

################################################################
### NEPI Docker Config Setup

While most NEPI device settings like static, alias, and ntp IP addresses are configurable real-time through the RUI (Resident User Interface),
some settings such as User Password, Folders, and SSH Keys must be configured prior to run-time.  You may also want to Factory Reset a NEPI Docker
configuration.

Run the NEPI Docker configuration script by typing:

    nepiconfig

Make any changes you want using the menu options presented, then choose the 'APPLY SETTINGS' to apply changes, or 'FACTORY RESET' to factory reset your installation.

**NOTE:** The NEPI System Configuration file is located at '/mnt/nepi_config/system_cfg/etc/nepi_system_config.yaml'.
For production environments, you can just replace this file with a production ready file, or create a custom production script that make any required changes.


**POWER CYCLE YOUR SYSTEM WHEN COMPLETE**


################################################################
### NEPI DOCKER CONFIGURATION COMPLETE
################################################################

