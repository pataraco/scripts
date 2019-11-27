#!/bin/bash
# Decription:
#    Change the HealthCheckType of ALL AWS AutoScalingGroups
# Optional:
#    Only change a specified AutoScaling group name
#    or those matching a reg-ex
# Note:
#    Can use "--dry-run" to verify correctness

# Set some vars
USAGE="usage: $(basename $0) -t|--type EC2|ELB [--region REGION] [--dry-run] [ASGName|RegEx]"
AWS_CMD=$(/usr/bin/which aws 2> /dev/null) || { echo "'aws' needed to run this script"; exit 3; }
JQ_CMD=$(/usr/bin/which jq 2> /dev/null) || { echo "'jq' needed to run this script"; exit 3; }

dryrun=running

# Parse command-line arguments/options
while true; do
   case "$1" in
         --region) region="--region $2" ; shift 2 ;;
        -t|--type) type="$2"            ; shift 2 ;;
        --dry-run) dryrun=dry-run       ; shift   ;;
                *) break                          ;;
   esac
done

# Verify mandatory option (type) specified
[ -z "$type" ] && { echo "$USAGE"; exit 2; }

# Get any optional specific ASG name or Reg-Ex to perform on
asgn_pattern=$*

# Get the AWS ASG names to perform on
#asg_names=$($AWS_CMD $region autoscaling describe-auto-scaling-groups | grep AutoScalingGroupName | cut -d'"' -f4 | grep "$asgn_pattern")
asg_names=$($AWS_CMD $region autoscaling describe-auto-scaling-groups | $JQ_CMD .AutoScalingGroups[].AutoScalingGroupName | tr -d '"' | grep "$asgn_pattern")

# Perform the AWS autoscaling command to change the HealthCheckType
if [ -n "$asg_names" ]; then	# ASG names found
   for asg_name in $asg_names; do
      if [ $type = "ELB" ]; then
         health_check_grace_period=$($AWS_CMD autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asg_name --output json | $JQ_CMD .AutoScalingGroups[].HealthCheckGracePeriod)
         hcgp_opt="--health-check-grace-period $health_check_grace_period"
      fi
      echo "$dryrun: $(basename $AWS_CMD) $region autoscaling update-auto-scaling-group --auto-scaling-group-name $asg_name --health-check-type $type $hcgp_opt"
      if [ $dryrun == "running" ]; then	# non-dry-run: execute the command
         $AWS_CMD $region autoscaling update-auto-scaling-group --auto-scaling-group-name $asg_name --health-check-type $type $hcgp_opt
      fi
   done
else	# no ASG names found
   echo "no matching AWS Auto Scaling Group names found"
fi
