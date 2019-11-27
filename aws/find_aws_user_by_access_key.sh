#!/bin/bash
#
# description:
#   find the AWS user who owns a specific AWS access key

USAGE="usage: $0 [-h] [-p AWS_PROFILE] AWS_ACCESS_KEY"
[ "$(uname)" == "Darwin" ] && ESC="\033" || ESC="\e"
D2E="${ESC}[0K"    # to delete the rest of the chars on a line
HDC="${ESC}[?25l"  # hide cursor
SHC="${ESC}[?25h"  # show cursor

while [ $# -gt 0 ]; do
   case $1 in
      -p) profile="--profile=$2" ; shift 2 ;;
      -h) echo "$USAGE"          ; exit 2  ;;
       *) aws_access_key=$1      ; shift   ;;
   esac
done

[ -z "$aws_access_key" ] && { echo -e "error: no key given\n$USAGE"; exit 1; }

for u in $(aws iam list-users $profile | jq -r .Users[].UserName); do
   for u_k in $(aws iam list-access-keys $profile \
                --user-name $u \
                --query "AccessKeyMetadata[].[UserName,AccessKeyId]" \
                --output text | awk '{print $1"|"$2}'); do
      echo -ne "${HDC}$u_k${D2E}\r"
      [ $(grep "$aws_access_key" <<< "$u_k") ] && { echo -e "found: $u ($aws_access_key)${SHC}"; exit 0; }
   done
done

echo -e "not found: $aws_access_key${SHC}"
