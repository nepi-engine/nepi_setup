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


# This script loads and exports key values from file


import os
import sys
import yaml


config_folder=os.path.dirname(sys.argv[0])
config_file=config_folder + "/nepi_system_config.yaml"
backup_file=config_folder + "/nepi_system_config.yaml.bak"


print_list=[]
def read_yaml_2_dict(file_path):
    dict_from_file = dict()
    if os.path.exists(file_path):
        try:
            with open(file_path) as f:
                dict_from_file = yaml.load(f, Loader=yaml.FullLoader)
        except Exception as e:
            pass
        if dict_from_file is None:
           print_list.append("success=-1")
    else:
       print_list.append("success=-2")
    return dict_from_file

if os.path.exists(config_file) == True:
        config_dict = read_yaml_2_dict(config_file)
        if config_dict is not None:
            if os.path.exists(backup_file) == True:
                backup_dict = read_yaml_2_dict(backup_file)
                if backup_dict is not None:
                    for key in backup_dict.keys():
                        if key not in config_dict.keys():
                            config_dict[key] = backup_dict[key]
            for key in config_dict.keys():
                print_string=(str(key) + "=" + str(config_dict[key]))
                print_list.append(print_string)
            print_list.append("success=1")
        else:
            print_list.append("success=0")
    
else:
    print_list.append("success=0")

print_string="\'"
for entry in print_list:
    print_string += entry + " "
print_string += "\'"
print(print_string)
