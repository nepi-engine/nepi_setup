#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus <https://www.numurus.com>.
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






# Needed for GenICam auto-detect
from harvesters.core import Harvester


PKG_NAME = 'IDX_GENICAM' # Use in display menus
FILE_TYPE = 'DISCOVERY'


DEFAULT_GENTL_PRODUCER_USB =  '/opt/baumer/gentl_producers/libbgapi2_usb.cti.2.15'
DEFAULT_GENTL_PRODUCER_GIGE = '/opt/baumer/gentl_producers/libbgapi2_gige.cti.2.15'

    
if __name__ == '__main__':
    genicam_harvester = Harvester()
    
    genicam_harvester.add_file(DEFAULT_GENTL_PRODUCER_USB)    
    genicam_harvester.add_file(DEFAULT_GENTL_PRODUCER_GIGE)
    # Make sure our genicam harvesters context is up to date.
    genicam_harvester.update()
    print(str(genicam_harvester.device_info_list))          

        
      

 
