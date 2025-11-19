#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
#
# This file is part of nepi-engine
# (see https://github.com/nepi-engine).
#
# License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
#


# This script loads and exports key values from file


import os
import sys
import yaml


config_folder=os.path.dirname(sys.argv[0])
config_file=config_folder + "/nepi_system_config.yaml"


print_list=[]


def read_yaml_2_dict(file_path):
    dict_from_file = dict()
    if os.path.exists(file_path):
        try:
            with open(file_path) as f:
                dict_from_file = yaml.load(f, Loader=yaml.FullLoader)
        except Exception as e:
           print_list.append("success=-1")
    else:
       print_list.append("success=-2")
    return dict_from_file

if os.path.exists(config_file) == True:
    # print_string=("yfile=" + str(YAML_FILE))
    # print_list.append(print_string)
    config_dict = read_yaml_2_dict(config_file)
    if len(config_dict.keys()) > 0:
        for key in config_dict.keys():
            print_string=(str(key) + "=" + str(config_dict[key]))
            print_list.append(print_string)
        print_list.append("success=1")
    else:
        print_list.append("success=-3")
    
else:
    print_list.append("success=0")

print_string="\'"
for entry in print_list:
    print_string += entry + " "
print_string += "\'"
print(print_string)
