#!/bin/bash
#
# OpenStack attach a VIP (and optional FIP)
#
# Also, if the VIP and FIP are already attached - it will let you know and nothing will happen
# 
# Usage: $THIS_SCRIPT [-f] <instance> <last octet of vip>
# Option: -f	Create and attach a FIP to the VIP

THIS_SCRIPT=`basename $0`
USAGE="\
USAGE: $THIS_SCRIPT [-f] <instance> <last octet of vip>
DESCRIPTION: attaches a VIP to an instance in OpenStack and optional FIP
OPTIONS:
   -f   also create and attach a FIP
   -h   help - show this message
EXAMPLE:
   $THIS_SCRIPT -f haproxy-external-01 91\
"

if [ -z "$OS_PASSWORD" -o -z "$OS_AUTH_URL" -o -z "$OS_USERNAME" -o -z "$OS_TENANT_NAME" ]; then
   echo "error: all of the OpenStack Environment variables aren't set"
   exit 2
fi
if [ "$1" = "-h" ]; then
   echo "$USAGE"
   exit 1
fi
if [ "$1" = "-f" ]; then
   afip="true"
   shift
else
   afip="false"
fi
if [ $# -lt 2 ]; then
   echo "$USAGE"
fi
instance=$1
loov=$2
if [ -n "$instance" -a -n "$loov" ]; then
   instance_interfaces=`nova interface-list $instance | \grep ACTIVE`
   if [ $? -eq 0 ]; then
      instance_portid=`echo $instance_interfaces | awk '{print $4}'`
      instance_netid=`echo $instance_interfaces | awk '{print $6}'`
      instance_ip=`echo $instance_interfaces | awk '{print $8}'`
      iilo=`echo $instance_ip | cut -d'.' -f4`	#instance_ip_last_octect
      vip=`echo $instance_ip | sed 's/.'"$iilo"'$/.'"$loov"'/'`
      vippll=`neutron port-list | \fgrep '"'$vip'"'`
      if [ $? -ne 0 ]; then
         echo "creating VIP $vip with the following command:"
         for isg in `nova list-secgroup $instance | \egrep -v 'Id.*Name.*Description|------+------'|awk '{print $2}'`; do
            [ -n "$isg" ] && pcsgo="$pcsgo --security-group $isg"
         done
         echo "  neutron port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid"
         ##vipid=test_vipid ##debug##
         vipid=`neutron port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid | \fgrep "| id " | awk '{print $4}'`
      else
         echo "the VIP $vip already exists"
         vipid=`echo $vippll | awk '{print $2}'`
      fi
      ipsal=`neutron port-show $instance_portid | \fgrep allowed_address_pairs | \fgrep '"'$vip'"'`
      if [ $? -ne 0 ]; then
         echo "allowing the VIP to send traffic to the instance with the following command:"
         echo "  neutron port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip"
         neutron port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip
      else
         echo "the VIP is already allowed to send traffic to the instance"
         echo "  $ipsal"
      fi
      if [ "$afip" = "true" ]; then
         fipll=`neutron floatingip-list | \fgrep " $vip "`
         if [ $? -ne 0 ]; then
            echo "creating a FIP with the following command:"
            echo "  neutron floatingip-create net04_ext"
            ##fipid=test_fipid ##debug##
            fipid=`neutron floatingip-create net04_ext | \fgrep "| id " | awk '{print $4}'`
            echo "attaching a FIP using the following command"
            echo "  neutron floatingip-associate $fipid $vipid"
            ##fip=`neutron floatingip-associate $fipid $vipid | \fgrep "| id " | awk '{print $4}'` 
            neutron floatingip-associate $fipid $vipid > /dev/null
            fip=`neutron floatingip-list | \fgrep $fipid | awk '{print $6}'` 
            echo "VIP ($vip) is now attached to FIP ($fip)"
         else
            fip=`echo $fipll | awk '{print $6}'`
            echo "VIP ($vip) is already attached to FIP ($fip)"
         fi
      else
         echo "not creating a FIP or attaching it to the VIP"
      fi
   else
      echo "cannot get the interface info for instance: $instance"
   fi
else
   echo "error: you did not specify an instance to attach the VIP to and last ip octet for the VIP"
fi
