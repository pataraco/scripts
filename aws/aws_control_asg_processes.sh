#!/bin/bash
# Decription:
#    Control (suspend/resume) ALL AWS AutoScaling processes
# Optional:
#    Only control processes for a specified AutoScaling group name
#    or those matching a reg-ex
# Note:
#    Defaults to "dry-run" - to ensure correctness and prevent catastrophes
#    Must use "--no-dry-run" option to perform

# Set some vars
USAGE="usage: $(basename $0) -r|--resume or -s|--suspend [--region REGION] [--no-dry-run] [ASGName|RegEx]"
AWS_CMD=$(/usr/bin/which aws 2> /dev/null) || { echo "'aws' needed to run this script"; exit 3; }
JQ_CMD=$(/usr/bin/which jq 2> /dev/null) || { echo "'jq' needed to run this script"; exit 3; }

dryrun=dry-run

# Parse command-line arguments/options
while true; do
   case "$1" in
       -r|--resume) pc_cmd=resume-processes  ; shift   ;;
      -s|--suspend) pc_cmd=suspend-processes ; shift   ;;
          --region) region="--region $2"     ; shift 2 ;;
      --no-dry-run) dryrun=running           ; shift   ;;
                 *) break                              ;;
   esac
done

# Verify mandatory option (resume|suspend) specified
[ -z "$pc_cmd" ] && { echo "$USAGE"; exit 2; }

# Get any optional specific ASG name or Reg-Ex to perform on
asgn_pattern=$*

# Get the AWS ASG names to perform on
#asg_names=$($AWS_CMD $region autoscaling describe-auto-scaling-groups | grep AutoScalingGroupName | cut -d'"' -f4 | grep "$asgn_pattern")
asg_names=$($AWS_CMD $region autoscaling describe-auto-scaling-groups | $JQ_CMD .AutoScalingGroups[].AutoScalingGroupName | tr -d '"' | grep "$asgn_pattern")

# Perform the AWS autoscaling command to control the processes
if [ -n "$asg_names" ]; then	# ASG names found
   for asg_name in $asg_names; do
      echo "$dryrun: $(basename $AWS_CMD) $region autoscaling $pc_cmd --auto-scaling-group-name $asg_name"
      if [ $dryrun == "running" ]; then	# non-dry-run: execute the command
         $AWS_CMD $region autoscaling $pc_cmd --auto-scaling-group-name $asg_name
      fi
   done
else	# no ASG names found
   echo "no matching AWS Auto Scaling Group names found"
fi
