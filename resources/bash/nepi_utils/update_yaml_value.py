#!/usr/bin/env python

##
## Copyright (c) 2024 Numurus <https://www.numurus.com>.
##
## This file is part of nepi setup tools (nepi_setup) repo
## (see https://github.com/nepi-engine/nepi_setup)
##
## License: nepi setup tools are licensed under the "Numurus Software License", 
## which can be found at: <https://numurus.com/wp-content/uploads/Numurus-Software-License-Terms.pdf>
##
## Redistributions in source code must retain this top-level comment block.
## Plagiarizing this software to sidestep the license obligations is illegal.
##
## Contact Information:
## ====================
## - mailto:nepi@numurus.com
##


# This script updates a key value in yaml file

success=0

import os
import sys
import shutil
import yaml
import numpy as np

# for arg in sys.argv:
#     print(str(arg))

def read_yaml_2_dict(file_path):
    dict_from_file = dict()
    success=0
    if os.path.exists(file_path):
        try:
            with open(file_path) as f:
                dict_from_file = yaml.load(f, Loader=yaml.FullLoader)
                if dict_from_file is None:
                    dict_from_file = dict()
                success = 1
        except Exception as e:
           pass

    return success, dict_from_file


def write_dict_to_file(dict_2_save,file_path,defaultFlowStyle=False,sortKeys=False):
    success=0
    try:
        with open(file_path, "w") as f:
            yaml.dump(dict_2_save, stream=f, default_flow_style=defaultFlowStyle, sort_keys=sortKeys)
        success = 1
    except Exception as e:
        pass
    return success

def convert_string_to_number(value):
    try:
        # Try converting to float first
        f_val = float(value)
        # If it's a float, check if it's also an integer (e.g., "5.0")
        if f_val == int(f_val):
            return int(f_val)
        else:
            return f_val
    except ValueError:
        # If float conversion fails, try converting to int
        try:
            return int(value)
        except:
            # If neither conversion works, return the original string or raise an error
            return value  # Or raise ValueError(f"Cannot convert '{s



overwrite = False
success = 0
if len(sys.argv) > 3:
    KEY = sys.argv[1]
    VALUE = sys.argv[2]
    VALUE = convert_string_to_number(VALUE)

    SOURCE_YAML_FILE = sys.argv[3]
    if os.path.exists(SOURCE_YAML_FILE):
        if len(KEY) > 0 and VALUE is not None:
            [success, source_dict] = read_yaml_2_dict(SOURCE_YAML_FILE)
            if success == 1:
                success = 0
                source_dict[KEY] = VALUE
                #source_dict['Test'] = 5
                success=write_dict_to_file(source_dict, SOURCE_YAML_FILE)
            else:
                success = -2
    else:
         success = -1



print(str(success))

