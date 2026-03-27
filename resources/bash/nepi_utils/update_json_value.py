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

import json, sys, os

def parse_value(s):
    if s.lower() == 'true':
        return True
    if s.lower() == 'false':
        return False
    try:
        return int(s)
    except ValueError:
        pass
    try:
        return float(s)
    except ValueError:
        pass
    return s

if len(sys.argv) != 4:
    print("Usage: update_json_value.py <path> <key> <value>")
    print("  key supports dot notation for nested keys, e.g. browser.show_home_button")
    sys.exit(1)

path, key, raw_value = sys.argv[1], sys.argv[2], sys.argv[3]
value = parse_value(raw_value)
keys = key.split('.')

data = {}
if os.path.isfile(path):
    with open(path, 'r') as f:
        try:
            data = json.load(f)
        except Exception:
            data = {}

node = data
for k in keys[:-1]:
    node = node.setdefault(k, {})
node[keys[-1]] = value

with open(path, 'w') as f:
    json.dump(data, f, indent=3)