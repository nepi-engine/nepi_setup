#!/bin/bash

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


# This script loads the nepi_system_config.yaml values

CONFIG_FOLDER=$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

LOAD_SCRIPT=${CONFIG_FOLDER}/load_system_config.py

echo "Load Script = ${LOAD_SCRIPT}"


if [[ -f "$LOAD_SCRIPT" ]]; then


      success=0
      eval_cmd="load_vals=$(python3 $LOAD_SCRIPT )"  #2>/dev/null"
      eval "$eval_cmd"
      #echo "${load_vals}"
      
      for entry in $load_vals; do
         export ${entry}
      done

      if [[ "$success" -ne 1 ]]; then
        #echo "Success = ${success}"
        echo "System Config File failed to load"
      fi


else
    echo "Load script not found ${LOAD_SCRIPT}"
    exit 1
fi
