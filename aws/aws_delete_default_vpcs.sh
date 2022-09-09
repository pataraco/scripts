#!/bin/bash
#
# simple script to delete all the default VPCs and related networking 
# resources in all the regions of an AWS account

# https://docs.aws.amazon.com/cli/latest/reference/ec2/delete-vpc.html
# You can't delete the main route table, default network ACL or default security group
 

ALL_AVAILABLE_REGIONS=$(aws ec2 describe-regions --region us-east-1 --query Regions[].RegionName --output text)

for region in $(aws ec2 describe-regions --region eu-west-1 | jq -r .Regions[].RegionName); do
  echo "processing region: $region"
  # search for a default VPC
  vpc=$(aws ec2 describe-vpcs --region "$region" --filter "Name=isDefault,Values=true" --query Vpcs[0].VpcId --output text)
  if [ "$vpc" = "None" ]; then
    echo "  No default VPC found"
    continue
  fi
  echo "  Found default VPC: $vpc"
  # get the internet gateway
  igw=$(aws ec2 describe-internet-gateways --region "$region" --filter "Name=attachment.vpc-id,Values=$vpc" --query InternetGateways[0].InternetGatewayId --output text)
  if [ "$igw" != "None" ]; then
    echo "  Found internet gateway: $igw"
  else
    echo "  Did not attached internet gateway"
  fi
  # get the subnets
  subnets=$(aws ec2 describe-subnets --region "$region" --filters "Name=vpc-id,Values=$vpc" --query Subnets[].SubnetId --output text)
  if [ "${subnets}" != "None" ]; then
    echo "  Found subnets: $subnets"
  else
    echo "  Did not find any related subnets"
  fi
  echo
  read -p "Are you sure? (type 'delete' to confirm deletion of all resources): " -r
  if [[ $REPLY == "delete" ]]; then
    echo "  Detaching and deleting internet gateway: $igw"
    aws ec2 detach-internet-gateway --region "$region" --internet-gateway-id "$igw" --vpc-id "$vpc"
    aws ec2 delete-internet-gateway --region "$region" --internet-gateway-id "$igw"
    for subnet in $subnets; do
      echo "  Deleting subnet: $subnet"
      aws ec2 delete-subnet --region "$region" --subnet-id "$subnet"
    done
    echo "  Deleting VPC: $vpc"
    aws ec2 delete-vpc --region "$region" --vpc-id "$vpc"
    echo
  else
    echo "  Ok - NOT deleting default VPC and related networking resources"
    echo
  fi
done

exit

##################################


#/usr/bin/env bash

export REGIONS=$(aws ec2 describe-regions | jq -r ".Regions[].RegionName")

for region in $REGIONS; do
    # list vpcs
    echo $region
    aws --region=$region ec2 describe-vpcs | jq ".Vpcs[]|{is_default: .IsDefault, cidr: .CidrBlock, id: .VpcId} | select(.is_default)"
done

read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    for region in $REGIONS ; do
        echo "Killing $region"
        # list vpcs
        export IDs=$(aws --region=$region ec2 describe-vpcs | jq -r ".Vpcs[]|{is_default: .IsDefault, id: .VpcId} | select(.is_default) | .id")
        for id in "$IDs" ; do
            if [ -z "$id" ] ; then
                continue
            fi

            # kill igws
            for igw in `aws --region=$region ec2 describe-internet-gateways | jq -r ".InternetGateways[] | {id: .InternetGatewayId, vpc: .Attachments[0].VpcId} | select(.vpc == \"$id\") | .id"` ; do
                echo "Killing igw $region $id $igw"
                aws --region=$region ec2 detach-internet-gateway --internet-gateway-id=$igw --vpc-id=$id
                aws --region=$region ec2 delete-internet-gateway --internet-gateway-id=$igw
            done

            # kill subnets
            for sub in `aws --region=$region ec2 describe-subnets | jq -r ".Subnets[] | {id: .SubnetId, vpc: .VpcId} | select(.vpc == \"$id\") | .id"` ; do
                echo "Killing subnet $region $id $sub"
                aws --region=$region ec2 delete-subnet --subnet-id=$sub
            done

            echo "Killing vpc $region $id"
            aws --region=$region ec2 delete-vpc --vpc-id=$id
        done
    done

fi

