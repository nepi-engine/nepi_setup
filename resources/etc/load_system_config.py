#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
#
# This file is part of nepi-engine
# (see https://github.com/nepi-engine).
#
# License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
#


# NEPI misc python utility functions

# This script loads the nepi_system_config.yaml values

print("success=0")

import os
import sys
import yaml

# Get the path of the current script file
SCRIPT_FOLDER = os.path.dirname(__file__)
CONFIG_FILE=os.path.join(SCRIPT_FOLDER, 'nepi_system_config.yaml')
 
def read_yaml_2_dict(file_path):
    dict_from_file = dict()
    if os.path.exists(file_path):
        try:
            with open(file_path) as f:
                dict_from_file = yaml.load(f, Loader=yaml.FullLoader)
        except Exception as e:
           print("Failed to get dict from file: " + file_path + " " + str(e))
    else:
       print("Failed to find dict file: " + file_path)
    return dict_from_file


CONFIG_DICT = read_yaml_2_dict(CONFIG_FILE)

for key in CONFIG_DICT.keys():
    print(key + "=" + str(CONFIG_DICT[key]))

print("success=1")