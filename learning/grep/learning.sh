#!/usr/bin/env bash

echo -e "\npurpose: search for 2 or more consecutive repeated numbers"
read -r -d '' input << EOF
1234 5678 9012 3456
1234 5578 9012 3456
0987 6543 2109 9765
1222 2678 9012 3456
EOF
echo "--- Input: ---"; echo "$input"

# '-E' is needed here (for \1)
echo "--- Output (1): with \d ---"
grep -E --color=auto '(\d)\s*\1+' <<< "$input"
echo "--- Output (2): with [0-9] ---"
grep -E --color=auto '([0-9]) ?\1+' <<< "$input"
echo "--- Output (3): with :digit: and :space: ---"
grep -E --color=auto '([[:digit:]])[[:space:]]?\1+' <<< "$input"
