#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
#
# This file is part of nepi-engine
# (see https://github.com/nepi-engine).
#
# License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
#


# This script loads echos yaml keys and values from file

success=0

import os
import sys
import shutil
import yaml

# for arg in sys.argv:
#     print(str(arg))

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


def write_dict_to_file(dict_2_save,file_path,defaultFlowStyle=False,sortKeys=False):
    success = 0
    try:
        with open(file_path, "w") as f:
            yaml.dump(dict_2_save, stream=f, default_flow_style=defaultFlowStyle, sort_keys=sortKeys)
        success = 1
    except Exception as e:
        print("Failed to write dict: "  + " to file: " + file_path + " " + str(e))
    return success

overwrite = False
if len(sys.argv) > 1:
    SOURCE_YAML_FILE = sys.argv[1]
    TARGET_YAML_FILE = sys.argv[2]
    if os.path.exists(SOURCE_YAML_FILE):
        if os.path.exists(TARGET_YAML_FILE) == False:
            print("Target file not found " + str(TARGET_YAML_FILE) + " will create")
            shutil.copyfile(SOURCE_YAML_FILE, TARGET_YAML_FILE)
            if os.path.exists(TARGET_YAML_FILE) == True:
                success=1
        else:
            if len(sys.argv) > 2:
                if sys.argv[2] == 1:
                    overwrite = True

            source_dict = read_yaml_2_dict(SOURCE_YAML_FILE)
            target_dict = read_yaml_2_dict(TARGET_YAML_FILE)
            for key in source_dict.keys():
                if key not in target_dict.keys() or overwrite == True:
                    target_dict[key] = source_dict[key]
            success=write_dict_to_file(target_dict, TARGET_YAML_FILE)

    else:
         print("Source file not found " + str(SOURCE_YAML_FILE))

else:
    print("Missing required arguments, got:")
    for arg in sys.argv:
        print(str(arg))

print(success)
