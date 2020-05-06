#!/usr/bin/env bash

echo -e "\npurpose: make sure all scores exist"
read -r -d '' input << EOF
EMR 25 27 50
ATR 99 88
PAR 35 37 75
PGO 40
GAR 75 78 80
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1): ---"
awk '{
    if ( NF < 4 )
       print "Not all scores are available for:", $1;
}' <<< "$input"

############################################

echo -e "\npurpose: get averages and display grade"
read -r -d '' input << EOF
EMR 25 27 50
ATR 99 88 76
PAR 35 37 75
PGO 40 37 75
GAR 75 78 80
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1): ---"
awk '{
    total = $2 + $3 + $4;
    avg = total / 3;
    if      ( avg >= 80 ) grade = "A";
    else if ( avg >= 60 ) grade = "B";
    else if ( avg >= 50 ) grade = "C";
    else                  grade = "FAIL";
    printf "%s - [avg: %.2f] : %s\n", $0, avg, grade;
}' <<< "$input"

############################################

echo -e "\npurpose: make sure all are above certain amount"
read -r -d '' input << EOF
EMR 25 27 50
ATR 99 88 76
PAR 35 37 75
PGO 40 37 75
GAR 75 78 80
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1): ---"
awk '{
    if ( $2 >= 50 && $3 >= 50 && $4 >= 50 )
       grade = "Pass";
    else
       grade = "Fail";
    printf "%s : %s\n", $1, grade;
}' <<< "$input"

############################################

echo -e "\npurpose: concatenate every 2 lines with a ;"
read -r -d '' input << EOF
EMR 25 27 50
ATR 99 88 76
PAR 35 37 75
PGO 40 37 75
GAR 75 78 80
EOF
echo "--- Input: ---"; echo "$input"

echo "--- Output (1): ---"
awk '{
   if ( NR % 2 == 0 )
      printf "%s [NR=%d]\n", $0, NR;
   else
      printf "%s [NR=%d]; ", $0, NR;
   };
   END { if (NR % 2 == 1) print "" }
' <<< "$input"

echo "--- Output (2): ---"
awk 'ORS = (NR % 2) ? ";" : "\n"' <<< "$input"
