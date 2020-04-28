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
   -d | --new-desc NEW_DESC  - the description for the new CIDR
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
      -d|--new-desc) new_desc="$2"       ; shift 2;;
      -r|--region)   region="$2"         ; shift 2;;
      --dry-run)     dryrun="--dry-run"  ; shift  ;;
      -h|--help|*)   echo "$USAGE"       ; exit   ;;
   esac
done

# Verify required options provided
[ -z "$old_cidr" ] && { echo "$USAGE"; exit 2; }
[ -z "$new_cidr" ] && { echo "$USAGE"; exit 2; }
[ -z "$new_desc" ] && { echo "$USAGE"; exit 2; }

# Get any optional specific ASG name or Reg-Ex to perform on
# query="SecurityGroups[].[GroupId,GroupName,VpcId]"
new_ip_range='"IpRanges":[{"CidrIp":"'"$new_cidr"'","Description":"'"$new_desc"'"}],'


get_list_of_sgs () {
   local _ip_permission_filter="Name=ip-permission.cidr,Values=*$old_cidr*"
   local _region="$1"
   local _sgs_found
   _sgs_found=$(
      $AWS_EC2_DSG_CMD --region "$_region" --filters "$_ip_permission_filter" --output json |
         $JQ_CMD -r '.SecurityGroups[] | .GroupId + "|" + .GroupName + "|" + .VpcId')
   echo "$_sgs_found"
}


# shellcheck disable=SC1004
get_new_ip_perms () {
   local _sgid="$1"
   local _region="$2"
   local _new_ip_perms
   _new_ip_perms=$(
      $AWS_EC2_DSG_CMD --region "$_region" --group-ids "$_sgid" |
         $JQ_CMD -r '.SecurityGroups[].IpPermissions[] | select(.IpRanges[].CidrIp | contains("'"$old_cidr"'")) | [.] | map(del(.IpRanges,.UserIdGroupPairs))' |
         sed '/IpProtocol/ a\
'"$new_ip_range"'' |
         $JQ_CMD . | tr -d '\n' | sed 's/}\]\[  {/},{/g')
   $JQ_CMD . <<< "$_new_ip_perms"
}


process_the_sgs () {
   local _region="$1"
   local _count=1
   local _sgid
   local _line
   local _new_ip_permissions
   while read -r _line; do
      _sgid=${_line%%|*}
      echo -e "\n------- Security Group [#$_count]: $_sgid -------"
      _new_ip_permissions=$(get_new_ip_perms "$_sgid" "$_region")
      echo "$AWS_EC2_ASGI_CMD" "$dryrun" --region "$_region" --group-id "$_sgid" --ip-permissions "$_new_ip_permissions"
      $AWS_EC2_ASGI_CMD "$dryrun" --region "$_region" --group-id "$_sgid" --ip-permissions "$_new_ip_permissions"
      ((_count++))
   done <<< "$sgs_found"
}


# Get the AWS security group names that contain the old CIDR to update
if [ "$region" == "all" ]; then
   all_regions=$(
      aws ec2 describe-regions --region us-east-1 |
         $JQ_CMD -r .Regions[].RegionName)
   for region in $all_regions; do
      echo -e "\nChecking for security groups in '$region'\nwith ingress rules allowing traffic from '$old_cidr'\n"
      sgs_found=$(get_list_of_sgs "$region")
      if [ -n "$sgs_found" ]; then
         echo -e "\nFound and updating these security groups ($region):\n"
         { column -s'|' -t | sed 's/  \([[:alnum:]]\)/ | \1/g;s/$/ | '"$region"'/'; } <<< "$sgs_found"
         process_the_sgs "$region"
      else
         echo -e "\nDid NOT find any security groups in ($region)\n"
      fi
   done
else
   echo -e "\nChecking for security groups in '$region'\nwith ingress rules allowing traffic from '$old_cidr'\n"
   sgs_found=$(get_list_of_sgs "$region")
   if [ -n "$sgs_found" ]; then
      echo -e "\nFound and updating these security groups ($region):\n"
      { column -s'|' -t | sed 's/  \([[:alnum:]]\)/ | \1/g;s/$/ | '"$region"'/'; } <<< "$sgs_found"
      process_the_sgs "$region"
   else
      echo -e "\nDid NOT find any security groups in ($region)\n"
   fi
fi
