#!/bin/bash

# list resource tags

AWS_ACCT=$(aws sts get-caller-identity | jq -r .Account)

function instances() {
   echo "AWS EC2 Instances"
   echo "ID|Name|AECOM Client|Application|BackupDaily|BackupWeekly|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-instances --query "Reservations[].Instances[].\
     [\
       InstanceId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='BackupDaily'].Value|[0],\
       Tags[?Key=='BackupWeekly'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function amis() {
   echo
   echo "AWS EC2 AMIs"
   echo "ID|Image Name|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-images --owners $AWS_ACCT --query "Images[].\
     [\
       ImageId,
       Name,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function custergws() {
   echo
   echo "AWS EC2 Customer Gateways"
   echo "ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-customer-gateways --query "CustomerGateways[].\
     [\
       CustomerGatewayId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function dhcpopts() {
   echo
   echo "AWS EC2 DHCP Options"
   echo "ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-dhcp-options --query "DhcpOptions[].\
     [\
       DhcpOptionsId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function volumes() {
   echo
   echo "AWS EC2 Volumes"
   echo "ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-volumes --query "Volumes[].\
     [\
       VolumeId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function igws() {
   echo
   echo "AWS EC2 Internet Gateways"
   echo "ID|VPC ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-internet-gateways --query "InternetGateways[].\
     [\
       InternetGatewayId,
       Attachments[].VpcId|[0],
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function netacls() {
   echo
   echo "AWS EC2 Network ACLs"
   echo "ID|VPC ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-network-acls --query "NetworkAcls[].\
     [\
       NetworkAclId,
       VpcId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function netints() {
   echo
   echo "AWS EC2 Network Interfaces"
   echo "ID|VPC ID|Instance ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-network-interfaces --query "NetworkInterfaces[].\
     [\
       NetworkInterfaceId,
       VpcId,
       Attachment.InstanceId,
       TagSet[?Key=='Name'].Value|[0],\
       TagSet[?Key=='AECOM Client'].Value|[0],\
       TagSet[?Key=='Application'].Value|[0],\
       TagSet[?Key=='Billing Contact'].Value|[0],\
       TagSet[?Key=='Cost Center'].Value|[0],\
       TagSet[?Key=='Department'].Value|[0],\
       TagSet[?Key=='Environment'].Value|[0],\
       TagSet[?Key=='PM Contact'].Value|[0],\
       TagSet[?Key=='Project Name'].Value|[0],\
       TagSet[?Key=='Project Number'].Value|[0],\
       TagSet[?Key=='Project Task'].Value|[0],\
       TagSet[?Key=='Technical Contact'].Value|[0],\
       TagSet[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function routetables() {
   echo
   echo "AWS EC2 Route Tables"
   echo "ID|VPC ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-route-tables --query "RouteTables[].\
     [\
       RouteTableId,
       VpcId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function securitygroups() {
   echo
   echo "AWS EC2 Security Groups"
   echo "ID|Group Name|VPC ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-security-groups --query "SecurityGroups[].\
     [\
       GroupId,
       GroupName,
       VpcId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}
  
function snapshots() {
   echo
   echo "AWS EC2 SnapShots"
   echo "ID|Instance ID|Volume ID|Encrypted|Delete On|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-snapshots --owner-ids $AWS_ACCT --query "Snapshots[].\
     [\
       SnapshotId,
       Tags[?Key=='InstanceID'].Value|[0],\
       VolumeId,
       Encrypted,
       Tags[?Key=='DeleteOn'].Value|[0],\
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function subnets() {
   echo
   echo "AWS EC2 Subnets"
   echo "ID|VPC ID|CidrBlock|AZ|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-subnets --query "Subnets[].\
     [\
       SubnetId,
       VpcId,
       CidrBlock,
       AvailabilityZone,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function vpngws() {
   echo
   echo "AWS EC2 VPN Gateways"
   echo "ID|VPC ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-vpn-gateways --query "VpnGateways[].\
     [\
       VpnGatewayId,
       VpcAttachments[].VpcId|[0],
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function vpcs() {
   echo
   echo "AWS EC2 VPCs"
   echo "ID|CIDR Block|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-vpcs --query "Vpcs[].\
     [\
       VpcId,
       CidrBlock,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function vpcpeercxs() {
   echo
   echo "AWS EC2 VPC Peering Connections"
   echo "ID|Requester Owner|Requester VPC|Requester CIDR|Accepter Owner|Accepter VPC|Accepter CIDR|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-vpc-peering-connections --query "VpcPeeringConnections[].\
     [\
       VpcPeeringConnectionId,
       RequesterVpcInfo.[OwnerId,VpcId,CidrBlock]|join('|',@),
       AccepterVpcInfo.[OwnerId,VpcId,CidrBlock]|join('|',@),
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function vpncxs() {
   echo
   echo "AWS EC2 VPN Connections"
   echo "ID|VPN GW ID|Customer GW ID|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   aws ec2 describe-vpn-connections --query "VpnConnections[].\
     [\
       VpnConnectionId,
       VpnGatewayId,
       CustomerGatewayId,
       Tags[?Key=='Name'].Value|[0],\
       Tags[?Key=='AECOM Client'].Value|[0],\
       Tags[?Key=='Application'].Value|[0],\
       Tags[?Key=='Billing Contact'].Value|[0],\
       Tags[?Key=='Cost Center'].Value|[0],\
       Tags[?Key=='Department'].Value|[0],\
       Tags[?Key=='Environment'].Value|[0],\
       Tags[?Key=='PM Contact'].Value|[0],\
       Tags[?Key=='Project Name'].Value|[0],\
       Tags[?Key=='Project Number'].Value|[0],\
       Tags[?Key=='Project Task'].Value|[0],\
       Tags[?Key=='Technical Contact'].Value|[0],\
       Tags[?Key=='Technical Team'].Value|[0]\
     ]" --output table | \
     egrep -v -- '----|Describe' | \
     sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
}

function elbs() {
   local _elbs=$(aws elb describe-load-balancers | jq -r .LoadBalancerDescriptions[].LoadBalancerName)
   echo
   echo "AWS Classic Load Balancers"
   echo "LB Name|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   if [ -n "$_elbs" ]; then
		aws elb describe-tags --load-balancer-names $_elbs --query "TagDescriptions[].\
		  [\
			 LoadBalancerName,
			 Tags[?Key=='Name'].Value|[0],\
			 Tags[?Key=='AECOM Client'].Value|[0],\
			 Tags[?Key=='Application'].Value|[0],\
			 Tags[?Key=='Billing Contact'].Value|[0],\
			 Tags[?Key=='Cost Center'].Value|[0],\
			 Tags[?Key=='Department'].Value|[0],\
			 Tags[?Key=='Environment'].Value|[0],\
			 Tags[?Key=='PM Contact'].Value|[0],\
			 Tags[?Key=='Project Name'].Value|[0],\
			 Tags[?Key=='Project Number'].Value|[0],\
			 Tags[?Key=='Project Task'].Value|[0],\
			 Tags[?Key=='Technical Contact'].Value|[0],\
			 Tags[?Key=='Technical Team'].Value|[0]\
		  ]" --output table | \
		  egrep -v -- '----|Describe' | \
		  sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
   else
      echo "NONE"
   fi
}

function elbv2s() {
   local _lb
   echo
   echo "AWS ALB/NLB Load Balancers"
   echo "LB Name|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   for _lb in $(aws elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | .LoadBalancerName + "=" + .LoadBalancerArn'); do
      echo -ne "${_lb%=*}|"
      aws elbv2 describe-tags --resource-arns ${_lb#*=} --query "TagDescriptions[].\
        [\
          Tags[?Key=='Name'].Value|[0],\
          Tags[?Key=='AECOM Client'].Value|[0],\
          Tags[?Key=='Application'].Value|[0],\
          Tags[?Key=='Billing Contact'].Value|[0],\
          Tags[?Key=='Cost Center'].Value|[0],\
          Tags[?Key=='Department'].Value|[0],\
          Tags[?Key=='Environment'].Value|[0],\
          Tags[?Key=='PM Contact'].Value|[0],\
          Tags[?Key=='Project Name'].Value|[0],\
          Tags[?Key=='Project Number'].Value|[0],\
          Tags[?Key=='Project Task'].Value|[0],\
          Tags[?Key=='Technical Contact'].Value|[0],\
          Tags[?Key=='Technical Team'].Value|[0]\
        ]" --output table | \
        egrep -v -- '----|Describe' | \
        sed -E 's/^\| +//g;s/ +\|$//g;s/  +//g;s/ \|/\|/g'
   done
}

function s3buckets() {
   local _bucket
   echo
   echo "AWS S3 Buckets"
   echo "Bucket Name|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   for _bucket in $(aws s3api list-buckets | jq -r '.Buckets[].Name'); do
      echo -ne "$_bucket|"
      aws s3api get-bucket-tagging --bucket $_bucket > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         aws s3api get-bucket-tagging --bucket $_bucket --query "\
           [\
             TagSet[?Key=='Name'].Value|[0],\
             TagSet[?Key=='AECOM Client'].Value|[0],\
             TagSet[?Key=='Application'].Value|[0],\
             TagSet[?Key=='Billing Contact'].Value|[0],\
             TagSet[?Key=='Cost Center'].Value|[0],\
             TagSet[?Key=='Department'].Value|[0],\
             TagSet[?Key=='Environment'].Value|[0],\
             TagSet[?Key=='PM Contact'].Value|[0],\
             TagSet[?Key=='Project Name'].Value|[0],\
             TagSet[?Key=='Project Number'].Value|[0],\
             TagSet[?Key=='Project Task'].Value|[0],\
             TagSet[?Key=='Technical Contact'].Value|[0],\
             TagSet[?Key=='Technical Team'].Value|[0]\
           ]" --output text | \
           tr '\t' '|'
      else
         echo "None|None|None|None|None|None|None|None|None|None|None|None|None"
      fi
   done
}

function rdsinstances() {
   local _rdsinst
   echo
   echo "AWS RDS Instances"
   echo "DB Instance Name|Name|AECOM Client|Application|Billing Contact|Cost Center|Department|Environment|PM Contact|Project Name|Project Number|Project Task|Technical Contact|Technical Team"
   for _rdsinst in $(aws rds describe-db-instances | jq -r '.DBInstances[] | .DBInstanceIdentifier + "=" + .DBInstanceArn'); do
      echo -ne "${_rdsinst%=*}|"
      aws rds list-tags-for-resource --resource-name ${_rdsinst#*=} --query "\
        [\
          TagList[?Key=='Name'].Value|[0],\
          TagList[?Key=='AECOM Client'].Value|[0],\
          TagList[?Key=='Application'].Value|[0],\
          TagList[?Key=='Billing Contact'].Value|[0],\
          TagList[?Key=='Cost Center'].Value|[0],\
          TagList[?Key=='Department'].Value|[0],\
          TagList[?Key=='Environment'].Value|[0],\
          TagList[?Key=='PM Contact'].Value|[0],\
          TagList[?Key=='Project Name'].Value|[0],\
          TagList[?Key=='Project Number'].Value|[0],\
          TagList[?Key=='Project Task'].Value|[0],\
          TagList[?Key=='Technical Contact'].Value|[0],\
          TagList[?Key=='Technical Team'].Value|[0]\
        ]" --output text | \
        tr '\t' '|'
   done
}

instances
amis
custergws
dhcpopts
volumes
igws
netacls
netints
routetables
securitygroups
subnets
vpngws
vpcs
vpcpeercxs
vpncxs
elbs
elbv2s
s3buckets
rdsinstances
snapshots
