# NEPI_SETUP
This repository contains scripts and resources for setting up a NEPI software environment.

## NEPI Docker Setup Instructions

This tutorial will walk you through setting up docker.

### Create a "nepihost" User Account
Go into your settings and select users. In the top rigt corner select unlock and enter your password when prompted. The in the top right select add user. 
Create a new user with the following inputs:

  TYPE: Administrator
  NAME: nepihost
  PASSWORD: #Nepi4You (Temporary - the actual password will be updated later in the Docker User Setup section to nepi).

When created, log out of the current account, then log back in to the "nepihost" account with the temporary password you previously set.

### Connect to the Internet
Make sure your system has internet access

### Install Software Requirments
Install yq:

    sudo add-apt-repository ppa:rmescandon/yq
    sudo apt update
    sudo apt install yq -y

Verify your installation:

    yq --version

### Clone the NEPI SETUP Repo
Clone the 'main' branch:

    git clone https://github.com/nepi-engine/nepi_setup.git
    cd nepi_setup
    git checkout main


### Docker User Setup
Open a terminal by left clicking on the desktop and selecting "Open in Terminal".
First run:

    sudo su
    echo "nepihost ALL=(ALL:ALL) ALL" >> /etc/sudoers
    exit

Then run:

    ./setup/scripts/docker_user_setup.sh

When prompted to enter/reenter password enter `nepi`. You will then be prompted to enter user imformation press `enter` for each to set all to default.

### Docker Bash Setup
Setup docker bash:

    ./setup/scripts/docker_bash_setup.sh
    source ~/.bashrc

### Docker Storage Setup
Run:

    ./setup/scripts/docker_storage_setup.sh

When prompted to enter/reenter password enter `nepi`. You will then be prompted to enter user imformation press `enter` for each to set all to default.## Docker User Setup

### Docker Environment Setup
Setup docker environment:

    ./setup/scripts/docker_env_setup.sh

When prompted to add keyring select `yes`

### Docker Config Setup
Setup docker configuration:

    ./setup/scripts/docker_config_setup.sh
