#!/bin/bash
#
# description:
#   parses a list of public IPs and gets [AWS] info on them
#
# output:
#   Public IP | ENI ID | ENI description | EC2 info (Instance ID/LB ID)
#
# requirements:
#   aws CLI installed
#   AWS credentials configured/enabled
#
# todo:
#   - TBD

USAGE="\
$0 PUB_IP_LIST
  PUB_IP_LIST   File containing list of public IPs to process"
# temp files
ENI_INFO=$(mktemp /tmp/aws_eni_info.XXXX)
EC2_INFO=$(mktemp /tmp/aws_ec2_info.XXXX)
R53_INFO=$(mktemp /tmp/aws_r53_info.XXXX)

function print_usage {
   # show usage and exit
   echo "Usage: $USAGE"
   exit 1
}

function get_eni_info {
   # get/return ENI info of the IP
   local _ip=$1
   # local _eni_pub_ip=$(grep $_ip $ENI_INFO | awk 'BEGIN{FS="|"; OFS="|"} {print $4}')
   # local _eni_pub_ip_line=$(grep $_ip $ENI_INFO)
   # echo "debug: ENI Public IP LINE='$_eni_pub_ip_line'"
   # echo "debug: IP='$_ip', ENI Public IP='$_eni_pub_ip'"
   local _eni_info=$(awk 'BEGIN{FS="|"; OFS="|"} $4~/'"$_ip"'/ {print $2,$3,$5,$6,$10,$12,$13}' $ENI_INFO | sed 's/ *| */|/g')
   #  1: NetworkInterfaceId
   #  2: Association.IpOwnerId
   #  3: Attachment.AttachmentId
   #  4: Attachment.InstanceId
   #  5: InterfaceType
   #  6: PrivateIpAddress
   #  7: Status
   #  8: Description
   if [ -z "$_eni_info" ]; then
      echo "not found"
   else
      echo $_eni_info
   fi
}

############ MAIN #############

# get the file containing the public IPs
PUB_IPS=$1

# sanity checks
[ -z "$PUB_IPS" ] && print_usage

# pre-processing
# get all ENI info
echo -n "getting eni info... "
aws ec2 describe-network-interfaces --query "NetworkInterfaces[].[NetworkInterfaceId,Association.IpOwnerId,Association.PublicIp,Attachment.AttachmentId,Attachment.InstanceId,Attachment.InstanceOwnerId,InterfaceType,OwnerId,PrivateIpAddress,RequesterId,Status,Description]" --output table > $ENI_INFO
echo "done"
#  1: NetworkInterfaceId
#  2: Association.IpOwnerId
#  3: Association.PublicIp
#  4: Attachment.AttachmentId
#  5: Attachment.InstanceId
#  6: Attachment.InstanceOwnerId
#  7: InterfaceType
#  8: OwnerId
#  9: PrivateIpAddress
# 10: RequesterId
# 11: Status
# 12: Description

# get all EC2 info
echo -n "getting ec2 info... "
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,Tags[?Key=='Name'].Value|[0],PrivateIpAddress,PublicIpAddress]" --output table | sed 's/ *| */|/g' > $EC2_INFO
echo "done"
#  1: InstanceId
#  2: Tag[Name]
#  3: PrivateIpAddress
#  4: PublicIpAddress

# get all R53 info
echo -n "getting route 53 info... "
hosted_zone_id=$(aws route53 list-hosted-zones-by-name --dns-name autogravity.com --max-items 1 | jq -r .HostedZones[].Id)
aws route53 list-resource-record-sets --hosted-zone-id $hosted_zone_id --query "ResourceRecordSets[?Type=='A'].[Name,ResourceRecords[].Value|[0]]" --output table|sed 's/ *| */|/g' > $R53_INFO
echo "done"

echo
# process the files
for ip in $(egrep -iv '^$|^#|\|New$|Private$' $PUB_IPS | cut -d'|' -f1); do
   eni_info=$(get_eni_info $ip)
   # see if a network interface exists with that IP
   if [ "$eni_info" != "not found" ]; then
      inst_id=$(echo "$eni_info" | cut -d'|' -f4)
      ip_owner=$(echo "$eni_info" | cut -d'|' -f2)
      # echo "debug: ip_owner='$ip_owner'"
      # echo "debug: inst_id='$inst_id'"
      # check if the eni is attached to an EC2 instance
      if [ "$inst_id" != "None" ]; then
         resource_name=$(grep $inst_id $EC2_INFO | cut -d'|' -f3)
         ip_associated_with="EC2"
      else
         # echo "debug: $eni_info"
         # check if the eni is attached to an ELB
         if [ "$ip_owner" == "amazon-elb" ]; then
            resource_name=$(echo "$eni_info" | cut -d'|' -f7 | cut -d' ' -f2 | cut -d'/' -f2)
            ip_associated_with="ELB"
         else
            resource_name="Unknown"
            ip_associated_with="UNK"
         fi
      fi
   else
      # check if the IP is defined in Route 53
      resource_name=$(fgrep "|$ip|" $R53_INFO | cut -d '|' -f2 | sed 's/\.$//')
      if [ -n "$resource_name" ]; then
         ip_associated_with="R53"
      else
         # check if there's a resource name defined for the IP in the IP list file
         resource_name=$(fgrep "$ip|" $PUB_IPS | cut -d '|' -f3)
         if [ -n "$resource_name" ]; then
            ip_associated_with=$(fgrep "$ip|" $PUB_IPS | cut -d '|' -f2)
         else
            resource_name="Not Found"
            ip_associated_with="N/A"
         fi
      fi
   fi
   # get any additionale info about the IP (if given)
   ip_additional_info=$(fgrep "$ip|" $PUB_IPS | cut -d '|' -f2-)
   echo "$ip|$ip_associated_with|$resource_name|$ip_additional_info"
done

# list all the new IPs/Endpoints (to possibly be checked)
echo
echo "New (to be checked?) IPs/Endpoints"
echo "----------------------------------"
grep -i "|New$" $PUB_IPS

# list all the private IPs/Endpoints (that cannot be checked)
echo
echo "Private (cannot be checked?) IPs/Endpoints"
echo "----------------------------------"
grep -i "|Private$" $PUB_IPS


# cleanup
rm $ENI_INFO
rm $EC2_INFO
rm $R53_INFO
