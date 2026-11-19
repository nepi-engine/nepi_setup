#!/bin/bash
#
# Copyright (c) 2025 Numurus <https://www.numurus.com>.
#
# This file is part of nepi setup tools (nepi_setup) repo
# (see https://github.com/nepi-engine/nepi_setup)
#
# License: NEPI Setup Tools and NEPI Docker Images created or installed with NEPI Setup Tools
# are licensed under the "Numurus Software License",
# which can be found at: <https://numurus.com/wp-content/uploads/Numurus-Software-License-Terms.pdf>
#
# Redistributions in source code must retain this top-level comment block.
# Plagiarizing this software to sidestep the license obligations is illegal.
#
# Contact Information:
# ====================
# - mailto:nepi@numurus.com
#

# Leverage licenseheaders Python module to update license headers
# Requires licenseheaders is on python3 path (e.g., pip3 install licenseheaders) 
# and the NEPI source header license text template file is passed in as first argument
# to this script

TEMPLATE_FILE=$1
TARGET_DIR='.'
EXCLUSIONS='*generate_license_headers.sh* 
    *catkin_tools*
	*package.xml*
	*zed-ros-wrapper*
	*nepi_darknet_ros*
	*nepi_gpsd*
	*num_factory*
	*yaml
	*__init__.py
	*setup.py
	*timestamp.proto*
	*wondershaper*
	*impl_c/frozen*
	*drivers/iqr_ros_pan_tilt*'
    
OWNER='Numurus, LLC <https://www.numurus.com>'
PROJECT='nepi-engine'
PROJECT_URL='https://github.com/nepi-engine'

# Create a dummy Python file to generate the LICENSE file
touch ${TARGET_DIR}/license_dummy.py

# Generate headers
python3 -m licenseheaders -t ${TEMPLATE_FILE} -d ${TARGET_DIR} -x ${EXCLUSIONS} -o "${OWNER}" -n ${PROJECT} -u ${PROJECT_URL} -cy

# Remove leading '#' to generate the LICENSE file
sed -i -e 's/^#//g' ${TARGET_DIR}/license_dummy.py
mv ${TARGET_DIR}/license_dummy.py LICENSE

# Add the license to all the NEPI-owned submodules
NEPI_SUBMODULES='nepi_automation_mgr    
	nepi_edge_sdk_link
	nepi_edge_sdk_v4l2
	nepi-bot
	nepi-bot/nepi-protobuf
	nepi-bot/src/nepi_edge_sw_mgr
	nepi_edge_sdk_lsx
	nepi_link_ros_bridge
	nepi_edge_sdk_ai
	nepi_edge_sdk_nav_pose
	nepi_ros_interfaces
	nepi_edge_sdk_base
	nepi_edge_sdk_onvif
	nepi_rui
	nepi_edge_sdk_genicam
	nepi_edge_sdk_ptx'

for submod in $NEPI_SUBMODULES; do
	cp LICENSE ./src/$submod
done
