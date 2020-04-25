#!/bin/bash
#
# Decription:
#    Finds security groups that contain a specific CIDR and if so, adds a
#    new security groups rule with a new CIDR and the same rules
#
# Purpose:
#    If you need to replace security group access via your
#    ISP (Office IPs) with new IPs
#
# Usage:
#    see below for usage or use '-h | --help' options
#
# Requirements:
#    Must have AWS environment/profile configured/enabled
#
# Output
#    The output displays whether dry-urn or not and actual AWS CLI command performing
#
#    For example:
#       dry-run: aws --region eu-west-1 autoscaling suspend-processes --auto-scaling-group-name web-blue
#       running: aws --region eu-west-1 autoscaling resume-processes --auto-scaling-group-name web-green

# Set some vars
THIS_SCRIPT=$(basename "$0")
DEFAULT_REGION='us-west-2'
CONFIG_REGION=$(aws configure get region)
region=${AWS_DEFAULT_REGION:-${CONFIG_REGION:-$DEFAULT_REGION}}
USAGE="\
usage: $THIS_SCRIPT [OPTIONS]
   -o | --old-cidr OLD_CIDR  - the old CIDR to search for
   -n | --new-cidr NEW_CIDR  - the new CIDR to add
   -r | --region REGION      - specify AWS region to work in (default: $region)
                             - specify 'all' to search all available regions
   --dry-run                 - perform dry-run, just show the command(s)
   -h | --help               - show help (this message)"

AWS_CMD_NAME="aws"
AWS_CMD=$(which $AWS_CMD_NAME 2> /dev/null) \
   || { echo "'$AWS_CMD_NAME' needed to run this script"; exit 3; }
JQ_CMD_NAME="jq"
JQ_CMD=$(which $JQ_CMD_NAME 2> /dev/null) \
   || { echo "'$JQ_CMD_NAME' needed to run this script"; exit 3; }
AWS_EC2_DSG_CMD="$AWS_CMD ec2 describe-security-groups"
AWS_EC2_ASGI_CMD="$AWS_CMD ec2 authorize-security-group-ingress"

dryrun=""

# Parse command-line arguments/options
while [ -n "$1" ]; do
   [ -n "$AWS_DEBUG" ] \
      && echo "debug: parsing argument '$1'"
   case "$1" in
      -o|--old-cidr) old_cidr="$2"       ; shift 2;;
      -n|--new-cidr) new_cidr="$2"       ; shift 2;;
      -r|--region)   region="$2"         ; shift 2;;
      --dry-run)     dryrun="--dry-run"  ; shift  ;;
      -h|--help|*)   echo "$USAGE"       ; exit   ;;
   esac
done

# Verify required options provided
[ -z "$old_cidr" ] && { echo "$USAGE"; exit 2; }
[ -z "$new_cidr" ] && { echo "$USAGE"; exit 2; }

# Get any optional specific ASG name or Reg-Ex to perform on
ip_permission_filter="Name=ip-permission.cidr,Values=*$old_cidr*"
query="SecurityGroups[].[GroupId,GroupName,VpcId]"

##############################
#           "IpPermissions": [
#               {
#                   "IpProtocol": "-1",
#                   "IpRanges": [
#                       {
#                           "CidrIp": "98.174.154.130/32"
#                       },
#                       {
#                           "CidrIp": "38.107.187.50/32"
#                       },
#                       {
#                           "CidrIp": "10.100.10.0/23"
#                       },
#                       {
#                           "CidrIp": "10.100.20.0/23"
#                       },
#                       {
#                           "CidrIp": "10.100.30.0/23"
#                       },
#                       {
#                           "CidrIp": "10.100.100.0/23"
#                       }
#                   ],
#                   "Ipv6Ranges": [],
#                   "PrefixListIds": [],
#                   "UserIdGroupPairs": []
#               },
##############################
#           "IpPermissions": [
#               {
#                   "FromPort": 5439,
#                   "IpProtocol": "tcp",
#                   "IpRanges": [
#                       {
#                           "CidrIp": "52.25.130.38/32",
#                           "Description": "Segment.io Access"
#                       },
#                       {
#                           "CidrIp": "98.174.154.130/32",
#                           "Description": "AG Office Access"
#                       },
#                       {
#                           "CidrIp": "38.107.187.50/32",
#                           "Description": "AG Office Access"
#                       }
#                   ],
#                   "Ipv6Ranges": [],
#                   "PrefixListIds": [],
#                   "ToPort": 5439,
#                   "UserIdGroupPairs": [
#                       {
#                           "Description": "Open 5439 to sg-137ecd62",
#                           "GroupId": "sg-137ecd62",
#                           "UserId": "111109246567"
#                       },
#                       {
#                           "Description": "Tools Default Security Group",
#                           "GroupId": "sg-d7b55faf",
#                           "UserId": "111109246567"
#                       }
#                   ]
#               }
#           ],
#
##############################

new_ip_range='"IpRanges":[{"CidrIp":"'"$new_cidr"'","Description":"AG Cox Internal Access"}],'

# Get the AWS security group names that contain the old CIDR to update
if [ "$region" == "all" ]; then
   ALL_REGIONS=$(
      aws ec2 describe-regions --region us-east-1 |
         $JQ_CMD -r .Regions[].RegionName)
   for region in $ALL_REGIONS; do
      $AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | .GroupId + "|" + .GroupName + "|" + .VpcId' | column -s'|' -t | sed 's/  \([[:alnum:]]\)/ | \1/g;s/$/ | '"$region"'/'
   done
else
   echo -e "Found and updating these security groups:\n"
   sgs_found=$($AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | .GroupId + "|" + .GroupName + "|" + .VpcId')
   { column -s'|' -t | sed 's/  \([[:alnum:]]\)/ | \1/g;s/$/ | '"$region"'/'; } <<< "$sgs_found"
   echo "raw findings:"
   echo "$sgs_found"
   count=1
   while read -r line; do
      echo "count: $count  --------------"
      sgid=${line%%|*}
      echo "sgid: $sgid"
      echo $AWS_EC2_ASGI_CMD --region "$region" --group-id "$sgid" --ip-permisions "$new_ip_range" --dry-run
      ((count++))
   done <<< "$sgs_found"

   # $AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | .GroupId + "|" + .GroupName + "|" + .VpcId' | column -s'|' -t | sed 's/  \([[:alnum:]]\)/ | \1/g;s/$/ | '"$region"'/'
   # $AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp=="'"$old_cidr"'").IpPermissions'
   # $AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp | contains("'"$old_cidr"'")).IpPermissions'
   # $AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp | contains("'"$old_cidr"'")).IpPermissions | map(del(.IpRanges))'
   # $AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp | contains("'"$old_cidr"'")).IpPermissions | map(del(.IpRanges))' | sed '/IpProtocol/ a\
#           '"$new_ip_range"'' | jq .); do
   ####################
#  count=1
#  for i in $($AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp | contains("'"$old_cidr"'")).IpPermissions | map(del(.IpRanges))' | sed '/IpProtocol/ a\
#           '"$new_ip_range"'' | jq .); do
#     echo "count: $count"
#     echo "i: $i"
#     ((count++))
#  done
   ####################
#  count=1
#  while read -r line; do
#     echo "-----------------------------------------------"
#     echo "count: $count"
#     echo "line: $line"
#     ((count++))
#  done <<< $($AWS_EC2_DSG_CMD --region "$region" --filters "$ip_permission_filter" --output json | $JQ_CMD -r '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp | contains("'"$old_cidr"'")).IpPermissions | map(del(.IpRanges))' | sed '/IpProtocol/ a\
#           '"$new_ip_range"'' | jq . | tr -d '\n')
#  
   ####################
fi

if [ -z "$dryrun" ]; then
   true
else
   false
fi
