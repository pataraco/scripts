#!/bin/bash
#
# Description:
#    start or stop an AWS instance
# Requirements:
#   Must have AWS credentials and policies configured

# define usage
THIS_SCRIPT=$(/bin/basename $0)
USAGE="usage: $THIS_SCRIPT start|stop INSTANCE_NAME [REGION]"

# get commandline arguments
CONTROL_CMD=$1
INSTANCE_NAME=$2
REGION=$3

# verify proper usage
[ -z "$CONTROL_CMD" ] && { echo "error: did not specify 'start' or 'stop'"; echo "$USAGE"; exit; }
[ -z "$INSTANCE_NAME" ] && { echo "error: did not specify an instance name"; echo "$USAGE"; exit; }

# set default region if none given
[ -z "$REGION" ] && REGION=us-west-2

# get the instance ID
INSTANCE_ID=$(/usr/bin/aws ec2 describe-instances --region $REGION --filters "Name=tag:Name,Values=$INSTANCE_NAME" --output json | jq -r .Reservations[].Instances[].InstanceId)
# verify instance exists
[ -z "$INSTANCE_ID" ] && { echo "not found: did not find instance named: $INSTANCE_NAME"; exit; }
# get the instance state
INSTANCE_STATE=$(/usr/bin/aws ec2 describe-instances --region $REGION --filters "Name=tag:Name,Values=$INSTANCE_NAME" --output json | jq -r .Reservations[].Instances[].State.Name)

# verify correct control command and check if instance is already in that state,
# if so, inform the user and exit, otherwise set matching AWS EC2 CLI option
case $CONTROL_CMD in
   start)
      [ "$INSTANCE_STATE" == "running" ] && { echo "$INSTANCE_NAME ($INSTANCE_ID) is already running"; exit; }
      aws_ec2_cmd=start-instances ;;
   stop)
      [ "$INSTANCE_STATE" == "stopped" ] && { echo "$INSTANCE_NAME ($INSTANCE_ID) is already stopped"; exit; }
      aws_ec2_cmd=stop-instances  ;;
   *)
      echo "unknown option: exiting..."; echo "$USAGE" ; exit ;;
esac

# make sure user wants to change the state and if so, do it
echo "Instance: $INSTANCE_NAME ($INSTANCE_ID) is $INSTANCE_STATE"
read -p "Are you sure that you want to ${CONTROL_CMD^^} it [yes/no]? " ans
if [ "$ans" == "yes" -o "$ans" == "YES" ]; then
   /usr/bin/aws ec2 $aws_ec2_cmd --region $REGION --instance-ids $INSTANCE_ID --output text
else
   echo "Did not enter 'yes'; NOT going to ${CONTROL_CMD} the instance"
fi
