#!/bin/bash
#
# description:
#   convert json to yaml

if [ -n $1 ]; then
    cat $1 | python -c 'import json, sys, yaml; yaml.safe_dump(json.load(sys.stdin), sys.stdout)';
else
    python -c 'import json, sys, yaml; yaml.safe_dump(json.load(sys.stdin), sys.stdout)';
fi
