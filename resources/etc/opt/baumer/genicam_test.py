#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus <https://www.numurus.com>.
#
# License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
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

        
      

 
