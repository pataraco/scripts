#!/bin/bash
#
#
USAGE="\
usage: $0 ENI_ID EIP_NAME_TAG
   ENI_ID        ENI ID to create the new private IP for and attach an EIP to
   EIP_NAME_TAG  Name tag to give the EIP"

eniid=$1
eipname=$2

[ -z "$eniid" -o -z "$eipname" ] && { echo "$USAGE"; exit 1; }

if [ -n "$eniid" -a -n "$eipname" ]; then
   echo "adding new private ip to eni: $eniid"
   echo -ne "list of existing private IPs on eni ($eniid): "
   aws ec2 describe-network-interfaces --network-interface-ids $eniid | jq -r .NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress | tr '\n' ',' | sed 's/,$//'
   aws ec2 assign-private-ip-addresses --network-interface-id $eniid --secondary-private-ip-address-count 1
   if [ $? -eq 0 ]; then
      newip=$(aws ec2 describe-network-interfaces --network-interface-ids $eniid | jq -r .NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress | tail -1)
      echo "new private IP created on eni ($eniid): $newip"
      echo "confirm that it's correct and hit [return] to continue"
      read junk
      neweip=$(aws ec2 allocate-address --domain vpc | jq -r '. | .PublicIp + ":" + .AllocationId')
      if [ -n "$neweip" ]; then
         eippubip=${neweip%:*}
         eipallid=${neweip#*:}
         echo "new public EIP ($eipallid) created: $eippubip"
      else
         echo "could not create new public EIP"
         exit 1
      fi
      aws ec2 create-tags --resources $eipallid --tags Key=Name,Value=$eipname
      if [ $? -eq 0 ]; then
         echo "tagged new EIP ($neweip) with name: $eipname"
      else
         echo "could not tag new EIP ($neweip) with name: $eipname"
         exit 1
      fi
      assid=$(aws ec2 associate-address --allocation-id $eipallid --network-interface-id $eniid --private-ip-address $newip | jq -r .AssociationId)
      if [ $? -eq 0 ]; then
         echo "associated new EIP ($eippubip) with private IP ($newip) on eni ($eniid): $assid"
      else
         echo "could not associate new EIP ($eippubip) with private IP ($newip) on eni: $eniid"
      fi
   else
      echo "could not create new private IP on eni: $eni"
   fi
else
   echo "usage: $0 ENI-ID EIP-NAME"
fi
