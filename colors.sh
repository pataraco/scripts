#!/bin/bash
#
# description: displays all possible colors via escape sequences
#
# red: 1
# green: 2
# yellow: 3
# blue: 4
# mag: 5
# cyan: 6
# cool blue: 27
# blue green: 45
# neat green: 46
# cool purple: 57
# orange: 167
# fire red: 196

[ "$(uname)" == "Darwin" ] && ESC="\033" || ESC="\e"

count=1
for i in `seq 1 255`; do
   echo -ne "$i: ${ESC}[38;5;${i}m#####\t${ESC}[m"
   (( count++ ))
   if [ $count -gt 5 ]; then
      echo
      count=1
   fi
done
echo -e "${ESC}[0"
