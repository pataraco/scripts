#!/bin/bash
#
# description:
#   quick/dirty script to edit AWS tags (that aren't accessible by the 
#   AWS Resource Groups > Tag Editor (console)
#   but can be set with the resourcegroupstaggingapi API
#   unfortunattely, with this API you cannot find resources that are not
#   tagged, so have to use other API's to get/form the ARN's, fun!!!
#
# usage:
#   1. if a function matching the resource that you want to tag does not
#      exist, copy an existing function and modify accordingly
#   2. in the main section, comment out the fuctions that you do not want
#      to run and add/un-comment those that you do

# set -x   # debug

USAGE="usage: $0 GREP_PATTERN TAG_KEY TAG_VAL [CONFIRM]"

# get command line arg
GREP_PATTERN=$1       # the pattern to search (grep) for
TAG_KEY=$2        # the tag key to set
TAG_VAL=$3        # the tag val to set
CONFIRM=${4:-n}  # whether or not to set the tag (y = yes)

if [ -z "$GREP_PATTERN" -o -z "$TAG_KEY" -o -z "$TAG_VAL" ]; then
   echo "$USAGE"
   exit
fi

function cloudwatch-alarm-names() {
   echo "editing CloudWatch Alarms Name tags"
   local _arn _id _name_tag_val
   local _arns=$(aws resourcegroupstaggingapi get-resources --resource-type-filters cloudwatch:alarm --query "ResourceTagMappingList[*].[ResourceARN,Tags[?Key=='Name'].Value|[0]]" --output table | grep "None" | sed 's/ *| */|/g' | cut -d'|' -f2 | sed 's/ /#/g')
	for _arn in $_arns; do
      echo "debug (_arn): $_arn"
      _id=$(echo $_arn | cut -d':' -f7)
      echo "debug (_id): $_id"
      _name_tag_val=$(echo $_id | tr [A-Z] [a-z] | tr '#' '-' | tr -d "'")
      echo "debug (_name_tag_val): $_name_tag_val"
      _arn=$(echo $_arn | sed 's/#/ /g')
      echo "debug (_arn): $_arn"
		cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list \"$_arn\" --tags Name=$_name_tag_val"
		echo -n "'$cmd' ... "
		if [ "$CONFIRM" == "yes" ]; then
			$cmd > /dev/null
			echo done
		else
			echo dry-run
		fi
	done
}


function ec2-snapshots() {
   echo "editing EC2 Snapshot tags"
   for arn in $(aws resourcegroupstaggingapi get-resources --resource-type-filters ec2:snapshot --query "ResourceTagMappingList[*].[ResourceARN,Tags[?Key=='Name'].Value|[0]]" --output table | grep -w $GREP_PATTERN | awk '{print $2}'); do
      # echo "debug (arn): $arn"
		cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list $arn --tags $TAG_KEY=$TAG_VAL"
		echo -n "'$cmd' ... "
		if [ "$CONFIRM" == "yes" ]; then
			$cmd > /dev/null
			echo done
		else
			echo dry-run
		fi
	done
}


function ec2-subnets() {
   echo "editing EC2 Subnet tags"
	aws ec2 describe-subnets --query "Subnets[*].[SubnetArn,Tags[?Key=='Name'].Value|[0],VpcId]" --output table | grep -i $GREP_PATTERN
	for arn in $(aws ec2 describe-subnets --query "Subnets[*].[SubnetArn,Tags[?Key=='Name'].Value|[0],VpcId]" --output table | grep -i $GREP_PATTERN | awk '{print $2}'); do
		# echo $arn
		cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list $arn --tags $TAG_KEY='"$TAG_VAL"'"
		echo -n "'$cmd' ... "
		if [ "$CONFIRM" == "yes" ]; then
			eval $cmd > /dev/null
			echo done
		else
			echo dry-run
		fi
	done
}


function db-cluster-snapshots() {
   echo "editing DB Cluster Snapshot tags"
	for arn in $(aws rds describe-db-cluster-snapshots --query "DBClusterSnapshots[].[DBClusterSnapshotIdentifier,DBClusterSnapshotArn]" --output table | grep -i $GREP_PATTERN | awk '{print $4}'); do
		# echo $arn
		cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list $arn --tags $TAG_KEY=$TAG_VAL"
		echo -n "'$cmd' ... "
		if [ "$CONFIRM" == "yes" ]; then
			$cmd > /dev/null
			echo done
		else
			echo dry-run
		fi
	done
}


function ec2-enis() {
   # ARN has to be calculated to match the format:
   #    arn:aws:ec2:REGION:AWS_ACCOUNT:network-interface/ENI_ID
   local _DEFAULT_REGION="us-west-2"
   local _AWS_ACCT=$(aws sts get-caller-identity | jq -r .Account)
   local _CONFIG_REGION=$(aws configure get region)
   local _REGION=${AWS_DEFAULT_REGION:-${_CONFIG_REGION:-$_DEFAULT_REGION}}

   echo "editing EC2 network-interface tags"
   for eni_id in $(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$GREP_PATTERN --query "NetworkInterfaces[*].NetworkInterfaceId" --output text); do
      eniarn="arn:aws:ec2:$_REGION:$_AWS_ACCT:network-interface/$eni_id"
      cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list $eniarn --tags $TAG_KEY=$TAG_VAL"
      echo -n "'$cmd' ... "
      if [ "$CONFIRM" == "yes" ]; then
         $cmd > /dev/null
         echo done
      else
         echo dry-run
      fi
	done
}


function ec2-volumes() {
   # ARN has to be calculated to match the format:
   #    arn:aws:ec2:REGION:AWS_ACCOUNT:volume/VOL_ID
   local _DEFAULT_REGION="us-west-2"
   local _AWS_ACCT=$(aws sts get-caller-identity | jq -r .Account)
   local _CONFIG_REGION=$(aws configure get region)
   local _REGION=${AWS_DEFAULT_REGION:-${_CONFIG_REGION:-$_DEFAULT_REGION}}

   echo "editing EC2 Volume tags"
   for volid_instid_dev in $(aws ec2 describe-volumes --query "Volumes[*].[VolumeId,Attachments[0].InstanceId,Attachments[0].Device]" --output table | egrep -v -- '-----|DescribeVolumes' | sed 's/ *| */|/g;s/ /#/g'); do
      instid=$(echo $volid_instid_dev | cut -d'|' -f3)
      if [ $instid != "None" ]; then
         # vpcid=$(aws ec2 describe-instances --instance-id $instid | jq -r .Reservations[0].Instances[0].VpcId)
         vpcid_instname=$(aws ec2 describe-instances --instance-id $instid --query "Reservations[0].[Instances[].[VpcId,Tags[?Key=='Name'].Value]]" --output text | tr '\n' '|')
         vpcid=$(echo $vpcid_instname | cut -d'|' -f1)
         instname=$(echo $vpcid_instname | cut -d'|' -f2)
         if [ $vpcid == "$GREP_PATTERN" ]; then
            volid=$(echo $volid_instid_dev | cut -d'|' -f2)
            device=$(basename $(echo $volid_instid_dev | cut -d'|' -f4))
            voltags=$(aws ec2 describe-volumes --volume-ids $volid  | jq -r '.Volumes[0].Tags' | sed 's/null//')
            if [ ${#voltags} -ne 0 ]; then
               # volname=$(aws ec2 describe-volumes --volume-ids $volid  | jq -r '.Volumes[0].Tags[] | select(.Key == "Name") | .Value')
               volname=$(echo $voltags | jq -r '.[] | select(.Key == "Name") | .Value')
            else
               volname=""
            fi
            if [ -z "$volname" ]; then
               volname="$instname-$device"
            fi
            volarn="arn:aws:ec2:$_REGION:$_AWS_ACCT:volume/$volid"
            cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list $volarn --tags $TAG_KEY=$TAG_VAL,Name=$volname"
            echo -n "'$cmd' ... "
            if [ "$CONFIRM" == "yes" ]; then
               $cmd > /dev/null
               echo done
            else
               echo dry-run
            fi
         fi
      fi
	done
}


function rest-api-gateways() {
   # ARN has to be calculated to match the format:
   #    arn:aws:apigateway:REGION::/restapis/ID
   local _DEFAULT_REGION="us-west-2"
   local _CONFIG_REGION=$(aws configure get region)
   local _REGION=${AWS_DEFAULT_REGION:-${_CONFIG_REGION:-$_DEFAULT_REGION}}

   echo "editing REST API Gateway tags"
   for apigw in $(aws apigateway get-rest-apis --query "items[*].[id,name,description]" --output table | egrep -v -- '-----|GetRestApis' | sed 's/ *| */|/g;s/ /#/g'); do
      apiid=$(echo $apigw | cut -d'|' -f2)
      apiname=$(echo $apigw | cut -d'|' -f3)
      apidesc=$(echo $apigw | cut -d'|' -f4)
      apiarn="arn:aws:apigateway:$_REGION::/restapis/$apiid"
      echo "$apiarn ($apiname: $apidesc)" | sed 's/#/ /g' | grep $GREP_PATTERN
      if [ $? -eq 0 ]; then
		   cmd="aws resourcegroupstaggingapi tag-resources --resource-arn-list $apiarn --tags $TAG_KEY=$TAG_VAL"
			echo -n "'$cmd' ... "
			if [ "$CONFIRM" == "yes" ]; then
				$cmd > /dev/null
				echo done
			else
				echo dry-run
			fi
      fi
	done
}


# main 
# comment/un-comment what you want to run

# db-cluster-snapshots
# rest-api-gateways
# cloudwatch-alarm-names
# ec2-snapshots
# ec2-subnets
# ec2-volumes
 ec2-enis
