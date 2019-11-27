#!/bin/bash
#
# Description:
#   describe AWS Instances
# Uses/requirements:
#   aws ec2 describe-instances
#

# Global/Constant variables

THIS_SCRIPT=$(basename $0)
DEFAULT_REGION="us-west-2"
# Usage to disply
USAGE="usage: \
$THIS_SCRIPT [OPTIONS]
  -e ENVIRON   # filter results by this Environment (e.g. production, staging)
  -n NAME      # filter results by this Instance Name
  -p PROJECT   # filter results by this Project
  -s STATE     # filter results by this State (e.g. running, terminated, etc.)
  -m MAX       # the maximum number of items to display
  -r REGION    # the Region to query (default: $DEFAULT_REGION, 'all' for all)
  +a           # show AMI (ImageId)
  +az          # show Availability Zone
  +bt          # show Branch Tag
  +c           # show Cluster
  +cc          # show Charge Code
  +e           # show Env (Environment)
  +it          # show Instance Type
  +lt          # show Launch Time
  +mr          # show Machine Role
  +p           # show Project
  +pi          # show Public IP
  +si          # show Security Group Id(s)
  +sn          # show Security Group Name(s)
  +v           # show VPC Name
  -h           # help (show this message)
default display:
  Inst name | Private IP | Instance ID | State"
# AWS command to use
AWS_EC2_DI_CMD="aws ec2 describe-instances"
# All AWS regions to search when '-r all' is used
REGIONS="us-west-1 us-west-2 us-east-1 us-east-2 eu-west-1 eu-west-2 eu-central-1"

# Set some default variables/values
region="$DEFAULT_REGION"
query="Reservations[].Instances[]"
queries="Tags[?Key=='Name'].Value|[0],PrivateIpAddress,InstanceId,State.Name"

# Parse the command line arguements
while [ $# -gt 0 ]; do
   case $1 in
       -p) filters="Name=tag:Project,Values=*$2* $filters"           ; shift 2;;
       -n) filters="Name=tag:Name,Values=*$2* $filters"              ; shift 2;;
       -s) filters="Name=instance-state-name,Values=*$2* $filters"   ; shift 2;;
       -e) filters="Name=tag:Env,Values=*$2* $filters"               ; shift 2;;
       -m) max_items="--max-items $2"                                ; shift 2;;
       -r) region=$2                                                 ; shift 2;;
       +a) more_qs="ImageId,$more_qs"                                ; shift  ;;
      +az) more_qs="Placement.AvailabilityZone,$more_qs"             ; shift  ;;
      +bt) more_qs="Tags[?Key=='BranchTag'].Value|[0],$more_qs"      ; shift  ;;
       +c) more_qs="Tags[?Key=='Cluster'].Value|[0],$more_qs"        ; shift  ;;
      +cc) more_qs="Tags[?Key=='ChargeCode'].Value|[0],$more_qs"     ; shift  ;;
       +e) more_qs="Tags[?Key=='Env'].Value|[0],$more_qs"            ; shift  ;;
      +it) more_qs="InstanceType,$more_qs"                           ; shift  ;;
      +lt) more_qs="LaunchTime,$more_qs"                             ; shift  ;;
      +mr) more_qs="Tags[?Key=='MachineRole'].Value|[0],$more_qs"    ; shift  ;;
       +p) more_qs="Tags[?Key=='Project'].Value|[0],$more_qs"        ; shift  ;;
      +pi) more_qs="PublicIpAddress,$more_qs"                        ; shift  ;;
      +si) more_qs="SecurityGroups[].GroupId|join(', ',@),$more_qs"  ; shift  ;;
      +sn) more_qs="SecurityGroups[].GroupName|join(', ',@),$more_qs"; shift  ;;
       +v) more_qs="Tags[?Key=='VPCName'].Value|[0],$more_qs"        ; shift  ;;
     -h|*) echo "$USAGE"                                             ; exit   ;;
   esac
done

# Set up the "filters" command line option
[ -n "$filters" ] && filters="--filters ${filters% }"
# Set up the "query" command line option
[ -n "$more_qs" ] && query="$query.[$queries,${more_qs%,}]" || query="$query.[$queries]"

# Check if all regions specified
if [ "$region" == "all" ]; then
   # yes: loop through and display instances for 'all' regions
   for region in $REGIONS; do
      # Run the AWS CLI, output in table format, get rid of header, sort and then format with '|' deliminators
      $AWS_EC2_DI_CMD --region=$region $max_items $filters --query "$query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$/|'"$region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   done
else
   # no: just display instances for 1 region
   # Run the AWS CLI, output in table format, get rid of header, sort and then format with '|' deliminators
   $AWS_EC2_DI_CMD --region=$region $max_items $filters --query "$query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
fi
