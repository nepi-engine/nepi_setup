#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
#
# This file is part of nepi-engine
# (see https://github.com/nepi-engine).
#
# License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
#


# This script updates a key value in yaml file

success=0

import os
import sys
import shutil
import yaml

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

overwrite = False
success = 0
if len(sys.argv) > 3:
    KEY = sys.argv[1]
    VALUE = sys.argv[2]
    SOURCE_YAML_FILE = sys.argv[3]
    if os.path.exists(SOURCE_YAML_FILE):
        if len(KEY) > 0 and VALUE != "":
            [success, source_dict] = read_yaml_2_dict(SOURCE_YAML_FILE)
            if success == 1:
                success = 0
                source_dict[KEY] = VALUE
                success=write_dict_to_file(source_dict, SOURCE_YAML_FILE)
            else:
            success = -2
    else:
         success = -1



print(str(success))

