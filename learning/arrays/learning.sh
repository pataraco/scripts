#!/usr/bin/env bash

# shellcheck disable=SC2116,SC2207

echo -e "\npurpose: split an array"
read -r -d '' input << EOF
Namibia  
Nauru  
Nepal
Netherlands
NewZealand
Nicaragua
Niger
Norway
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1): ---"
array=($(echo "$input"))
echo "${array[*]:3:5}"
# echo "--- Output (2): with [0-9] ---"
# grep -E --color=auto '([0-9]) ?\1+' <<< "$input"
# echo "--- Output (3): with :digit: and :space: ---"
# grep -E --color=auto '([[:digit:]])[[:space:]]?\1+' <<< "$input"

echo -e "\npurpose: don't print values with an [aA]"
echo "--- Output (1): ---"
echo "${array[*]/*[aA]*/}"
