#!/bin/bash
#
# description:
#   convert yaml to json

if [ -n $1 ]; then
    cat $1 | python -c 'import json, sys, yaml; [json.dump(f, sys.stdout, indent=4) for f in yaml.load_all(sys.stdin, Loader=yaml.FullLoader)]' | jq .;
else
    python -c 'import json, sys, yaml; [json.dump(f, sys.stdout, indent=4) for f in yaml.load_all(sys.stdin, Loader=yaml.FullLoader)]' | jq .;
fi
