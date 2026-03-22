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
import shutil

# for arg in sys.argv:
#     print_string=("arg=" + str(arg))
#     print_list.append(print_string)

def remove_invalid_yaml_lines(input_file):
    tmp_file=(input_file + '.tmp')
    shutil.copy(input_file, tmp_file)
    """Reads a YAML file and writes only valid lines to a new file."""
    valid_lines = []
    
    with open(tmp_file, 'r') as f:
        lines = f.readlines()

    # Basic approach: Try loading each line, or the document as a whole
    # For robust invalid-line removal, structural analysis is needed.
    for line in lines:
        try:
            # Check if the line can be loaded
            yaml.safe_load(line)
            valid_lines.append(line)
        except yaml.YAMLError:
            print(f"Removing invalid line: {line.strip()}")
            continue

    with open(tmp_file, 'w') as f:
        f.writelines(valid_lines)
    shutil.copy(tmp_file, input_file)
    os.remove(tmp_file)


if len(sys.argv) > 1:
    YAML_FILE = sys.argv[1]
    # print_string=("yfile=" + str(YAML_FILE))
    # print_list.append(print_string)
    if os.path.exists(YAML_FILE):
        remove_invalid_yaml_lines(YAML_FILE)
