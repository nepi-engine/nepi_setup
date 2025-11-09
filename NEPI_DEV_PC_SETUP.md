# NEPI Code Development PC Setup

This tutorial will walk you through setting up a NEPI code development environment on your PC if desired.

### NEPI User PC Setup

Before continuing, make sure you have gone through all the setup processes in the
"NEPI User PC Setup" instructions

### Connect to the Internet
Make sure your PC has internet access

### NEPI ...



### Clone the NEPI Engine Repo
Clone the 'main' branch:

    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout main
    git submodule update --init --recursive

Or, clone the 'development' branch:

    git clone git@github.com:nepi-engine/nepi_engine_ws.git 
    cd nepi_engine_ws
    git checkout develop
    git submodule update --init --recursive


