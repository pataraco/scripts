#!/usr/bin/env bash

# shellcheck disable=SC2001

echo -e "\npurpose: word boundries and the first occurance"
read -r -d '' input << EOF
From fairest creatures we desire the increase,
That thereby beauty's rose might never die, the
But as the riper should by time the decease,
EOF
echo "--- Input: ---"; echo "$input"

# both with '-E' and without works
echo "--- Output (1) (with gsed \<...\>): ---"
gsed -E 's/\<the\>/this/1' <<< "$input"
echo "--- Output (2) (with gsed \b...\b): ---"
gsed 's/\bthe\b/this/1' <<< "$input"
echo "--- Output (3) (with sed [[:<:]]...[[:>:]]): ---"
sed 's/[[:<:]]the[[:>:]]/this/1' <<< "$input"

#################################################
echo -e "\npurpose: word boundries, all occurances, case incensitive"
read -r -d '' input << EOF
From thy fairest creatures we thydesire the increase,
That thereby thy beauty's rose might never die, the
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1) (with sed [...]): ---"
sed 's/[[:<:]][tT]hy[[:>:]]/your/g' <<< "$input"
echo "--- Output (2) (with gsed /gi): ---"
gsed 's/\<thy\>/your/gi' <<< "$input"

#################################################
echo -e "\npurpose: highlight words with {}'s - word boundries, all occurances, case incensitive"
read -r -d '' input << EOF
From thy fairest creatures we thydesire the increase,
That thereby thy beauty's rose might never die, the
EOF
echo "--- Input: ---"; echo "$input"

# '-E' is needed here for '\1'
echo "--- Output (1) (with sed [...]): ---"
sed -E 's/[[:<:]]([tT]hy)[[:>:]]/{\1}/g' <<< "$input"
echo "--- Output (2) (with gsed /gi): ---"
gsed -E 's/\<(thy)\>/{\1}/gi' <<< "$input"

#################################################
echo -e "\npurpose: reorder groups of numbers in credit card number"
read -r -d '' input << EOF
1234 5678 9012 3456
0987 6543 2109 8765
EOF
echo "--- Input: ---"; echo "$input"

# '-E' is needed here
echo "--- Output (1) (with sed \d {4}): ---"
sed -E 's/(\d{4}) (\d{4}) (\d{4}) (\d{4})/\4 \3 \2 \1/' <<< "$input"
echo "--- Output (2) (with gsed \d +): ---"
gsed -E 's/(\d+) (\d+) (\d+) (\d+)/\4 \3 \2 \1/' <<< "$input"
echo "--- Output (3) (with sed :digit: {4}): ---"
sed -E 's/([[:digit:]]{4}) ([[:digit:]]{4}) ([[:digit:]]{4}) ([[:digit:]]{4})/\4 \3 \2 \1/' <<< "$input"
echo "--- Output (4) (with gsed :digit: +): ---"
gsed -E 's/([[:digit:]]+) ([[:digit:]]+) ([[:digit:]]+) ([[:digit:]]+)/\4 \3 \2 \1/' <<< "$input"


#################################################
echo -e "\npurpose: mask first 12 numbers of credit card numbers"
read -r -d '' input << EOF
1234 5678 9012 3456
0987 6543 2109 8765
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1): ---"
sed 's/.... /**** /g' <<< "$input"

echo "--- Output (2): ---"
sed 's/\([[:digit:]]\{4\} \)\{3\}/**** **** **** /' <<< "$input"
