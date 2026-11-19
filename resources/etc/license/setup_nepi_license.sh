#!/bin/sh
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

# Update a nepi rootfs image to be a licensed pre-built image

# This script must be run from the rootdir of nepi_production_tools that has been deployed to the
# target system. 

# Set up nepi_check_license (license management, etc.)
chmod +x /opt/nepi/etc/license/nepi_check_license.py
cp /opt/nepi/etc/license/nepi_check_license.service /etc/systemd/system/
gpg --import /opt/nepi/etc/license/nepi_license_management_public_key.gpg
sudo systemctl enable nepi_check_license
#gpg --import /opt/nepi/etc/nepi/nepi_license_management_public_key.gpg

echo "***** nepi_check_license license manager is installed... you must still provide a valid license file in /mnt/nepi_storage/license *****"

# TODO: Update license files and source code comments per the nepi_commercial.tmpl license template
# Will use python "licenseheaders" package, probably via 
# /mnt/nepi_storage/src/nepi_engine_base/generate_license_headers.sh ./resources/license_templates/nepi_commercial.tmpl
# but then must rebuild the software to get new files installed to /opt/nepi.
