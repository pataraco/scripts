#!/bin/bash
# 
# Description
#   List AWS resources available in AWS account

# TODO: 
#   - add search for EIPs
#   - add search for ECS/ECR/EKS
#   - add search for EFS

# get the AWS account number
aws_acct=$(aws sts get-caller-identity | jq -r .Account)
# get list of available regions to this AWS account
aws_avail_regions=$(aws ec2 describe-regions --region us-west-2 | jq -r .Regions[].RegionName)
#for-testing#aws_avail_regions="eu-west-1 us-east-1 us-west-1"

function nfir {
   regions=$1
   if [ -n "$regions" ]; then
      echo "none found in:"
      echo -e "\t$regions"
   fi
}

echo "===================================================================="
echo "              AWS Resources for Account ($aws_acct)              "
echo "____________________________________________________________________"
echo

echo "------------- ACM (Certificates) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws acm list-certificates --region $r 2> /dev/null | grep DomainName)
   if [ -n "$output" ]; then
      echo $r
      #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}'
      echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ACM (Certificates) [End]   -------------"
echo

echo "------------- API Gateway (Domains) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws apigateway get-domain-names --region $r 2> /dev/null | grep -w domainName)
   if [ -n "$output" ]; then
      echo $r
      #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}'
      echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- API Gateway (Domains) [End]   -------------"
echo

echo "------------- Auto Scaling (Groups) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   #output=$(aws autoscaling describe-auto-scaling-groups --region $r 2> /dev/null | egrep 'AutoScalingGroupName|LaunchConfigurationName')
   output=$(aws autoscaling describe-auto-scaling-groups --region $r 2> /dev/null | grep 'AutoScalingGroupName')
   if [ -n "$output" ]; then
      echo $r
      #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}'
      echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- Auto Scaling (Groups) [End]   -------------"
echo

echo "------------- CloudFormation (Stacks) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws cloudformation describe-stacks --region $r 2> /dev/null | grep "StackName.:")
   if [ -n "$output" ]; then
      echo $r
      #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}'
      echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- CloudFormation (Stacks) [End]   -------------"
echo

echo "------------- CloudFront (Distributions) [Begin] -------------"
output=$(aws cloudfront list-distributions --region $r 2> /dev/null | grep DomainName)
if [ -n "$output" ]; then
   echo "global"
   #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}'
   echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
else
   echo "none found globally"
fi
echo "------------- CloudFront (Distributions) [End]   -------------"
echo

echo "------------- Cloud HSM (HSMs) [Begin] -------------"
not_avail_regions="eu-west-3 eu-west-2 ap-northeast-2 sa-east-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws cloudhsm list-hsms --region $r 2> /dev/null)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Cloud HSM (HSMs) [End]   -------------"
echo

echo "------------- Cloud Trail (Trails) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   #output=$(aws cloudtrail describe-trails --region $r 2> /dev/null | grep Name | tr -d '\n' | sed 's/,.*S3BucketName/ - "S3BucketName/g' | tr ',' '\n')
   output=$(aws cloudtrail describe-trails --region $r 2> /dev/null | grep Name | sed 's/"Name": //;s/"S3BucketName":/-> S3 Bucket:/' | tr -d '\n' | sed 's/, *-/ -/g' | tr ',' '\n')
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- Cloud Trail (Trails) [End]   -------------"
echo

echo "------------- CloudWatch (Alarms) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws cloudwatch describe-alarms --region $r 2> /dev/null | grep AlarmName)
   if [ -n "$output" ]; then
      echo $r
      #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}'
      echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- CloudWatch (Alarms) [End]   -------------"
echo

echo "------------- CodeBuild (Projects) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 sa-east-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws codebuild list-projects --region $r 2> /dev/null | jq .projects[])
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- CodeBuild (Projects) [End]   -------------"
echo

echo "------------- CodeBuild (Builds) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 sa-east-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws codebuild list-builds --region $r 2> /dev/null | jq .ids[])
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- CodeBuild (Builds) [End]   -------------"
echo

echo "------------- CodeCommit (Repos) [Begin] -------------"
not_avail_regions="eu-west-3"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      #[ $r != "eu-west-3" ] && output=$(aws codecommit list-repositories --region $r 2> /dev/null | jq .repositories[])
      output=$(aws codecommit list-repositories --region $r 2> /dev/null | grep repositoryName)
      if [ -n "$output" ]; then
         echo $r
         #echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}'
         echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- CodeCommit (Repos) [End]   -------------"
echo

echo "------------- AWS Config (Rules) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws configservice describe-config-rules --region $r 2> /dev/null | jq .ConfigRules[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- AWS Config (Rules) [End]   -------------"
echo

echo "------------- Directory Service (IDs) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ds describe-directories --region $r 2> /dev/null | jq .DirectoryDescriptions[].DirectoryId)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- Directory Service (IDs) [End]   -------------"
echo

echo "------------- DynamoDB (Global Tables) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws dynamodb list-global-tables --region $r 2> /dev/null | jq .GlobalTables[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- DynamoDB (Global Tables) [End]   -------------"
echo

echo "------------- DynamoDB (Tables) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws dynamodb list-tables --region $r 2> /dev/null | jq .TableNames[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- DynamoDB (Tables) [End]   -------------"
echo

echo "------------- EC2 (VPCs) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   #output=$(aws ec2 describe-vpcs --region $r 2> /dev/null | grep VpcId)
   output=$(aws ec2 describe-vpcs --region $r | egrep "VpcId|IsDefault" | sed 's/e$/e,/;s/e,/e),/g' | tr -d '\n' | sed 's/"VpcId": //g;s/, *"IsDefault":/ (Default:/g' | tr ',' '\n')
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (VPCs) [End]   -------------"
echo

echo "------------- EC2 (Customer Gateways) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ec2 describe-customer-gateways --region $r 2> /dev/null | grep CustomerGatewayId)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (Customer Gateways) [End]   -------------"
echo

echo "------------- EC2 (NAT Gateways) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ec2 describe-nat-gateways --region $r 2> /dev/null | grep NatGatewayId)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (NAT Gateways) [End]   -------------"
echo

echo "------------- EC2 (VPN Gateways) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ec2 describe-vpn-gateways --region $r 2> /dev/null | grep VpnGatewayId)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (VPN Gateways) [End]   -------------"
echo

echo "------------- EC2 (VPC Peering Connections) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ec2 describe-vpc-peering-connections --region $r 2> /dev/null | jq .VpcPeeringConnections[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (VPC Peering Connections) [End]   -------------"
echo

echo "------------- Security Groups (Security Report) [Begin] -------------"
echo "Use AWS Trusted Advisor"
echo "------------- Security Groups (Security Report) [End]   -------------"
echo

echo "------------- NACLs (Security Report) [Begin] -------------"
echo "Use AWS Trusted Advisor"
echo "------------- NACLs (Security Report) [End]   -------------"
echo

echo "------------- EC2 (Instances) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   #output=$(aws ec2 describe-instances --region $r 2> /dev/null | egrep 'InstanceId|instance-profile')
   output=$(aws ec2 describe-instances --region $r 2> /dev/null | egrep 'InstanceId|instance-profile' | awk '{print $2}' | tr -d '\n' | sed 's^,"arn:aws:iam::'"$aws_acct"':instance-profile/^ profile: "^g' | tr ',' '\n')
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (Instances) [End]   -------------"
echo

echo "------------- EC2 (Reserved Instances) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ec2 describe-reserved-instances --region $r 2> /dev/null | jq .ReservedInstances[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EC2 (Reserved Instances) [End]   -------------"
echo

echo "------------- ECS (Clusters) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws ecs list-clusters --region $r 2> /dev/null | grep arn)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ECS (Clusters) [End]   -------------"
echo

echo "------------- EFS (File Systems) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 eu-west-2 ap-northeast-2 ap-northeast-1 sa-east-1 ca-central-1 ap-southeast-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws efs describe-file-systems --region $r 2> /dev/null | grep FileSystemId)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- EFS (File Systems) [End]   -------------"
echo

echo "------------- ElasticBeanstalk (Applications) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws elasticbeanstalk describe-applications --region $r 2> /dev/null | grep ApplicationName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | cut -d':' -f2 |  awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ElasticBeanstalk (Applications) [End]   -------------"
echo

echo "------------- ElastiCache (Clusters) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws elasticache describe-cache-clusters --region $r 2> /dev/null | jq .CacheClusters[] )
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ElastiCache (Clusters) [End]   -------------"
echo

echo "------------- Elastic Transcoder (Pipelines) [Begin] -------------"
not_avail_regions="us-east-2 ap-northeast-2 ca-central-1 eu-central-1 eu-west-3 eu-west-2 sa-east-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws elastictranscoder list-pipelines --region $r 2> /dev/null | grep Arn)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Elastic Transcoder (Pipelines) [Enbd] -------------"
echo

echo "------------- ElastiSearch (Domains) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws es list-domain-names --region $r 2> /dev/null | grep -w DomainName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ElastiSearch (Domains) [End]   -------------"
echo

echo "------------- EMR (Clusters) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws emr list-clusters --region $r 2> /dev/null | jq .Clusters[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- EMR (Clusters) [End]   -------------"
echo

echo "------------- GameLift (Builds) [Begin] -------------"
not_avail_regions="eu-west-3"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws gamelift list-builds --region $r 2> /dev/null | jq .Builds[])
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- GameLift (Builds) [End]   -------------"
echo

echo "------------- Glacier (Vaults) [Begin] -------------"
not_avail_regions="sa-east-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws glacier list-vaults --account-id $aws_acct --region $r 2> /dev/null | jq .VaultList[])
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Glacier (Vaults) [End]   -------------"
echo

echo "------------- Kinesis (Streams) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws kinesis list-streams --region $r 2> /dev/null | jq .StreamNames[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- Kinesis (Streams) [End]   -------------"
echo

echo "------------- Kinesis (Firehose Delivery Streams) [Begin] -------------"
not_avail_regions="ap-south-1 ap-northeast-2 ca-central-1 eu-west-2 eu-west-3 sa-east-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws firehose list-delivery-streams --region $r 2> /dev/null | jq .DeliveryStreamNames[])
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Kinesis (Firehose Delivery Streams) [End]   -------------"
echo

echo "------------- Kinesis Analytics (Applications) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 eu-west-2 ap-northeast-2 ap-northeast-1 sa-east-1 ca-central-1 ap-southeast-1 ap-southeast-2 eu-central-1 us-east-2 us-west-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws kinesisanalytics list-applications --region $r 2> /dev/null | grep ARN)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Kinesis Analytics (Applications) [End]   -------------"
echo

echo "------------- KMS (Aliases) [Begin] -------------"
output=$(aws kms list-aliases --region $r 2> /dev/null | grep Arn)
if [ -n "$output" ]; then
   echo "global"
   echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
else
   echo "none found globally"
fi
echo "------------- KMS (Aliases) [End]   -------------"
echo

echo "------------- Lambda (Functions) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws lambda list-functions --region $r 2> /dev/null | grep FunctionName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- Lambda (Functions) [End]   -------------"
echo

echo "------------- ELB (Names) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws elb describe-load-balancers --region $r 2> /dev/null | grep LoadBalancerName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ELB (Names) [End]   -------------"
echo

echo "------------- ALB (Names) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws elbv2 describe-load-balancers --region $r 2> /dev/null | grep LoadBalancerName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- ALB (Names) [End]   -------------"
echo

echo "------------- IAM (Security Report) [Begin] -------------"
echo "Use AWS Trusted Advisor"
echo "------------- IAM (Security Report) [End]   -------------"
echo

echo "------------- Logs (Groups) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws logs describe-log-groups --region $r 2> /dev/null | grep logGroupName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- Logs (Groups) [End]   -------------"
echo

echo "------------- Machine Learning (Evaluations) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 eu-west-2 ap-northeast-2 ap-northeast-1 sa-east-1 ca-central-1 ap-southeast-1 ap-southeast-2 eu-central-1 us-east-2 us-west-1 us-west-2"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      #output=$(aws machinelearning describe-evaluations --region $r 2> /dev/null | jq .Results[])
      output=$(aws machinelearning describe-evaluations --region $r 2> /dev/null | grep EvaluationId)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Machine Learning (Evaluations) [End]   -------------"
echo

echo "------------- RDS (Instances) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws rds describe-db-instances --region $r 2> /dev/null | grep DBInstanceArn)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- RDS (Instances) [End]   -------------"
echo

echo "------------- RedShift (Cluster/DB Name) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws redshift describe-clusters --region $r 2> /dev/null | grep DBName)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- RedShift (Cluster/DB Name) [End]   -------------"
echo

echo "------------- Route 53 (Hosted Zones) [Begin] -------------"
output=$(aws route53 list-hosted-zones 2> /dev/null | grep Name)
if [ -n "$output" ]; then
   echo "global"
   echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
else
   echo "none found globally"
fi
echo "------------- Route 53 (Hosted Zones) [End]   -------------"
echo

echo "------------- SES (Identities) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 eu-west-2 ap-northeast-2 ap-northeast-1 sa-east-1 ca-central-1 ap-southeast-1 ap-southeast-2 eu-central-1 us-east-2 us-west-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws ses list-identities --region $r 2> /dev/null | grep @)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- SES (Identities) [End]   -------------"
echo

echo "------------- SNS (Topics) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws sns list-topics --region $r 2> /dev/null | grep Arn)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- SNS (Topics) [End]   -------------"
echo

echo "------------- SQS (Queues) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws sqs list-queues --region $r 2> /dev/null | grep queue)
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- SQS (Queues) [End]   -------------"
echo

echo "------------- S3 (buckets) [Begin] -------------"
output=$(aws s3 ls 2> /dev/null)
if [ -n "$output" ]; then
   echo "global"
   echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
else
   echo "none found globally"
fi
echo "------------- S3 (buckets) [End]   -------------"
echo

echo "------------- StorageGateway (Gateways) [Begin] -------------"
not_found_in_regions=""
for r in $aws_avail_regions; do
   output=$(aws storagegateway list-gateways --region $r 2> /dev/null | jq .Gateways[])
   if [ -n "$output" ]; then
      echo $r
      echo "$output" | sed 's/^ *//g' | awk '{print "\t"$0}' | sed 's/,$//'
   else
      not_found_in_regions="$r $not_found_in_regions"
   fi
done
nfir "$not_found_in_regions"
echo "------------- StorageGateway (Gateways) [End]   -------------"
echo

echo "------------- Workspaces (Ids) [Begin] -------------"
not_avail_regions="ap-south-1 eu-west-3 ap-northeast-2 ca-central-1 us-east-2 us-west-1"
not_found_in_regions=""
for r in $aws_avail_regions; do
   if [[ ! $not_avail_regions =~ $r ]]; then
      output=$(aws workspaces describe-workspaces --region $r 2> /dev/null | grep WorkspaceId)
      if [ -n "$output" ]; then
         echo $r
         echo "$output" | sed 's/^ *//g' | awk '{print "\t"$2}' | sed 's/,$//'
      else
         not_found_in_regions="$r $not_found_in_regions"
      fi
   fi
done
nfir "$not_found_in_regions"
echo -e "not available in:\n\t$not_avail_regions"
echo "------------- Workspaces (Ids) [End]   -------------"
echo
