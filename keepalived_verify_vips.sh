#!/bin/bash
#
# Description: Keepalived VIP monitoring and reporting script for collectd
#              Used to monitor VIP connectivity and report to collectd
#
#              This script is to be run on all servers using keepalived.
#              The purpose is to monitor the VIP and report its status and
#              reattach if needed.
#
#              Reporting is sent via collectd to a monitoring server
#
# Status:      This script is not complete - it's a work in progress (WIP)
#
# Monitors:
#   - is this the MASTER and is the vip attached? - if no  -> restart keepalived
#   - is this the BACKUP and is the vip attached? - if yes -> restart keepalived
#   - connectivity of the VIP - if down -> restart keepalived
#
# Data to report/send to monitoring server via collectd
# - Host Name/Virtual Router ID/Role/VIP Attached?/Connectivity
#    examples
#       - webkeys-01/70/M/Y/U   # VIP is attached to the MASTER - connectivity UP
#       - webkeys-01/70/M/N/U   # VIP is NOT attached to the MASTER - connectivity UP
#    key
#       - Virtual Router ID
#          NN - ID of virtual router id "virtual_router_id" (10-80) in keepalived.conf
#          ?  - Unknown
#       - Role
#          M  - Master
#          B  - Backup
#          ?  - Unknown
#       - VIP Attached?
#          Y  - Yes
#          N  - No
#          R  - Restarted
#          ?  - Unknown
#       - Connectivity
#          U  - Up
#          D  - Down
#          R  - Restarted
#          ?  - Unknown
#
# Requirements: must have following to run this script
#  - commands - nc (netcat)
#
# TODO: The following improvements need/should be made
#  - does not have logic to determine that if the VIP is not attached to the MASTER,
#    because it is down (or for some other reason), then it is okay to have the VIP
#    attached to the BACKUP
#
# Updates:
#  02-DEC-2015 - initial build
#


# set some DEFAULTS
KNIFE_RB=/etc/chef/client.rb             # default knife.rb file (how to be root to use)
# set some GLOBALs
CYN="\e[36m"                             # cyan color
GRN="\e[32m"                             # green color
RED="\e[31m"                             # red color
YLW="\e[33m"                             # yellow color
NRM="\e[m"                               # to make text normal
THIS_SCRIPT=`basename $0`
LOGFILE=`mktemp /tmp/$THIS_SCRIPT.XXX.log`
AUTO_FIX="TRUE"                          # automatically fix stuff
DEBUG="FALSE"                            # do not produce debug output
NEEDS_FIP="FALSE"                        # used to determine if a server needs a FIP or not
REMOVELOGS="TRUE"                        # get rid of any old logs
SKIPSTACK="TRUE"                         # skip stack config verifications
VERBOSE="FALSE"                          # do not produce verbose output
USAGE="\
USAGE: $THIS_SCRIPT [OPTIONS]
DESCRIPTION: checks and verifies VIP connectivity and config and reports to collectd
OPTIONS (and defaults):
   -d   turn on debugging
   -h   help - show this message
   -l   keep log file when done                  (default removes log file)
   -n   no - do NOT automatically fix everything (default auto fixes all)
   -s   perform stack verifications              (default skips)
   -v   turn on verbose output
EXAMPLE:
   $THIS_SCRIPT -ns -k ~/repos/.chef/knife.rb -o ~/.openstackrc\
"
SERVERS_THAT_NEED_FIPS="haproxy-external haproxy-restricted"
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"
KEEPALIVED_VIP_ATTRIB="keepalived.vip"   # used to get node attrib of VIP from keepalived databag
EXTERNAL_NET="net04_ext"                 # used when creating FIPs - set to name of external network
# required commands
KNIFECMDNAME="knife";     KNIFECMD=`which $KNIFECMDNAME`
NEUTRONCMDNAME="neutron"; NEUTRONCMD=`which $NEUTRONCMDNAME`
NOVACMDNAME="nova";       NOVACMD=`which $NOVACMDNAME`
NCCMDNAME="nc";           NCCMD=`which nc`
# declare some arrays
declare -Ar PORTS_TO_TEST=(
   [haproxy-elasticsearch]=9200
   [haproxy-external]=80
   [haproxy-internal]=80
   [haproxy-restricted]=80
   [game-mcp]=19900
   [queue-firefall]=15672
   [webkeys]=443
)                                        # declare array with ports to check
declare -A keepalived_servers_ips        # declare array as a indexed array
declare -A keepalived_servers_vips       # declare array as a indexed array
declare -A keepalived_masters            # array of keepalived masters (key=vip)
declare -A keepalived_backups            # array of keepalived slaves (key=vip)

debug() {
   [ "$DEBUG" = "TRUE" -a "$VERBOSE" = "TRUE" ] && echo -e "${CYN}debug${NRM}: $*"
   [ "$DEBUG" = "TRUE" ] && log "${CYN}debug${NRM}: $*"
}

error() {
   echo -e "${RED}error${NRM}: $*"
   log "${RED}error${NRM}: $*"
   exit 2
}

info() {
   if [ "$VERBOSE" = "TRUE" ]; then
      [ "$1" = "-n" ] && (shift; echo -ne "info: $*") || echo -e "info: $*"
   fi
   [ "$1" = "-n" ] && (shift; log -n "info: $*") || log "info: $*"
}

log() {
   [ "$1" = "-n" ] && (shift; echo -ne "$*" >> $LOGFILE) || echo -e "$*" >> $LOGFILE 
}

update() {
   [ "$1" = "-n" ] && (shift; echo -ne "$*") || echo -e "$*"
   #[ "$1" = "-n" ] && (shift; log -n "update: $*") || log "update: $*"
   [ "$1" = "-n" ] && (shift; log "update: $*") || log "update: $*"
}

usage() {
   echo "$USAGE"
}

warn() {
   if [ "$VERBOSE" = "TRUE" ]; then
      echo -e "${YLW}warning${NRM}: $*"
   fi
   log "${YLW}warning${NRM}: $*"
}

sanity_check() {
# perform a bunch of sanity checks
   [ -z "$NCCMD" ] && error "required command '$NCCMDNAME' NOT found!" || debug "'$NCCMDNAME' installed: $NCCMD"
}

check_keepalived_conf() {

}
get_host_name() {
# get and retuen the hostname
   #hostname=$(hostname -f)
   hostname=$(hostname)
   return $hostname
} # end of: get_host_name()

get_the_virtual_router_id() {
# get the Virtual Router ID from the $KEEPALIVED_CONF file
   vrouter_id=$(grep virtual_router_id $KEEPALIVED_CONF | awk '{print $2}')
   return $vrouter_id
} # end of: get_the_virtual_router_id()

get_this_servers_keepalived_role() {
# getting the keepalived role of this server (MASTER or BACKUP)
   role=$(grep state /etc/keepalived/keepalived.conf|awk '{print $2}')
   role=${role,,}
   case $role in
      master) return "M"
      backup) return "B"
      *)      return "?"
   esac
} # end of: get_this_servers_keepalived_role()

get_the_vip() {
 - getting the VIP
	vip=$(awk 'found=="true" && $1~/([0-9]{1,3}\.){3}[0-9]{1,3}/ {print $1;exit}; $1=="virtual_ipaddress" {found="true"}' /etc/keepalived/keepalived.conf|cut -d'/' -f1)
} # end of: get_the_vip()

 - checking if the VIP is attached or not
	ip -f inet address | grep $vip
 - checking connectivity
	nc -n -v -w 2 -z $vip $port


check_keepalived_conf () {
# run a command on multiple servers matching a given pattern
  # looking for one of these 2 lines in the $KEEPALIVED_CONF file
  #state MASTER #primary peer(s) should be set to MASTER
  #state BACKUP #secondary peer(s) should be set to BACKUP
   list_of_vips=`mktemp`
   
   update -n "checking keepalived configs ($KEEPALIVED_CONF) on all servers..."
   [ "$VERBOSE" = "TRUE" ] && echo
   debug "getting the MASTERs and BACKUPs"
   for server in $keepalived_servers; do
      debug "working on $server"
      vip=${keepalived_servers_vips[$server]}
      echo $vip >> $list_of_vips
      kad_state=`ssh ${keepalived_servers_ips[$server]} "grep state $KEEPALIVED_CONF" 2>> $LOGFILE`
      if [ -n "$kad_state" ]; then
         echo "$kad_state" | grep -i "state MASTER" >> $LOGFILE 2>&1
         if [ $? -eq 0 ]; then
            info "the keepalived role for server $server is: [ MASTER ]"
            if [ -z "${keepalived_masters[$vip]}" ]; then
               keepalived_masters[$vip]=$server
            else
               warn "found more than one master for $server VIP ($vip)"
               keepalived_masters[$vip]="${keepalived_masters[$vip]} $server"
            fi
         else
            echo "$kad_state" | grep -i "state BACKUP" >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
               info "the keepalived role for server $server is: [ BACKUP ]"
               if [ -z "${keepalived_backups[$vip]}" ]; then
                  keepalived_backups[$vip]=$server
               else
                  info "found more than one backup for $server VIP ($vip)"
                  keepalived_backups[$vip]="${keepalived_backups[$vip]} $server"
               fi
            else
               warn "$server is not configured as a keepalived MASTER or BACKUP"
            fi
         fi
      else
         warn "$server does not have a $KEEPALIVED_CONF file or it is not configured properly"
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done checking keepalive configs" || update "done"
   # sort list of VIPS and get rid of dups
   sort -u $list_of_vips -o $list_of_vips.sorted
   mv -f $list_of_vips.sorted $list_of_vips
   update -n "keepalived configurations - verifying only one master and no dups for each VIP..."
   [ "$VERBOSE" = "TRUE" ] && echo
   for vip in `cat $list_of_vips`; do
      debug "working on VIP ($vip)"
      no_of_masters=`echo ${keepalived_masters[$vip]} | wc -w`
      if [ $no_of_masters -gt 1 ]; then
         info "VIP ($vip) has more than one master: ${keepalived_masters[$vip]}"
         for master in ${keepalived_masters[$vip]}; do
            echo "${keepalived_backups[$vip]}" | grep -q "$master"
            [ $? -eq 0 ] && warn "found a duplicate: $master is also configured as a BACKUP"
         done
      elif [ $no_of_masters -eq 1 ]; then
         info "VIP ($vip) only has one MASTER: ${keepalived_masters[$vip]}"
         echo "${keepalived_backups[$vip]}" | grep -q "${keepalived_masters[$vip]}"
         [ $? -eq 0 ] && warn "found a duplicate: ${keepalived_masters[$vip]} is also configured as a BACKUP"
      elif [ $no_of_masters -eq 0 ]; then
         warn "VIP ($vip) does NOT have a MASTER"
      else
         warn "failed trying to verify attached VIPs to masters"
      fi
      no_of_backups=`echo ${keepalived_backups[$vip]} | wc -w`
      if [ $no_of_backups -gt 1 ]; then
         info "VIP ($vip) has more than one BACKUP: ${keepalived_backups[$vip]}"
         for backup in ${keepalived_backups[$vip]}; do
            echo "${keepalived_masters[$vip]}" | grep -q "$backup"
            [ $? -eq 0 ] && warn "found a duplicate: $backup is also configured as a MASTER"
         done
      elif [ $no_of_backups -eq 1 ]; then
         info "VIP ($vip) only has one BACKUP: ${keepalived_backups[$vip]}"
         echo "${keepalived_masters[$vip]}" | grep -q "${keepalived_backups[$vip]}"
         [ $? -eq 0 ] && warn "found a duplicate: ${keepalived_backups[$vip]} is also configured as a MASTER"
      elif [ $no_of_backups -eq 0 ]; then
         warn "VIP ($vip) does NOT have a BACKUP"
      else
         warn "failed trying to verify attached VIPs to backups"
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done verifying only one master and no dups for each VIP" || update "done"
   rm -f $list_of_vips
}

look_for_attached_vip () {
# makes sure the VIP is attached to the MASTER keepalived peer and NOT the BACKUP
# if not - will restart keepalived
# looking for line similar to the following from the `ip -f inet address` command
#   inet 10.180.9.250/24 scope global eth0
   
   update -n "looking for the attached VIP on $server"
   # checking if the VIP is attached or not
   vip=$1
   ip -f inet address | grep -q $vip
   if [ $? -eq 0 ]; then
      info "$server: does have VIP ($vip) attached to network interface"
      [ "$VERBOSE" = "TRUE" ] && update "done looking for the attached VIP on the MASTERs" || update "done"
      return 0
   else
      return 1
   fi
} # end of: look_for_attached_vip ()

   [ "$VERBOSE" = "TRUE" ] && echo
   for server in ${keepalived_masters[*]}; do
      debug "working on $server"
      vip=${keepalived_servers_vips[$server]}
      ip_line=`ssh ${keepalived_servers_ips[$server]} "ip -f inet address" 2>> $LOGFILE`
      if [ -n "$ip_line" ]; then
         echo "$ip_line" | grep -iq "inet $vip/"
         if [ $? -eq 0 ]; then
            info "$server: does have VIP ($vip) attached to network interface"
            debug "$ip_line"
         else
            warn "$server: does NOT have VIP ($vip) attached to network interface"
            debug "$ip_line"
            debug "user chose to restart keepalived"
            info "restarting keepalived on $server"
            ssh ${keepalived_servers_ips[$server]} "sudo service keepalived restart" >> $LOGFILE 2>&1
         fi
      else
         warn "could not get the the network interface information for server: $server"
         debug "$ip_line"
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done looking for the attached VIP on the MASTERs" || update "done"
   update -n "making sure the VIP is NOT attached to any BACKUPs..."
   [ "$VERBOSE" = "TRUE" ] && echo
   for server in ${keepalived_backups[*]}; do
      debug "working on $server"
      vip=${keepalived_servers_vips[$server]}
      ip_line=`ssh ${keepalived_servers_ips[$server]} "ip -f inet address" 2>> $LOGFILE`
      if [ -n "$ip_line" ]; then
         echo "$ip_line" | grep -iq "inet $vip/"
         if [ $? -eq 0 ]; then
            warn "$server: has the VIP ($vip) attached to network interface but should NOT"
            debug "$ip_line"
            if [ "$AUTO_FIX" == "FALSE" ]; then
               ans=""
               [ "$VERBOSE" = "FALSE" ] && echo
               echo "$server: has the VIP ($vip) attached to network interface but should NOT"
               echo -n "do you want to restart keepalived [y/n]?: "
               read ans
            else
               info "automatically fixing"
            fi
            if [ "$AUTO_FIX" = "TRUE" -o "$ans" = "y" -o "$ans" = "Y" ]; then
               debug "user chose to restart keepalived"
               info "restarting keepalived on $server"
               ssh ${keepalived_servers_ips[$server]} "sudo service keepalived restart" >> $LOGFILE 2>&1
            else
               debug "user chose NOT to restart keepalived"
               info "NOT restarting keepalived on $server"
            fi
         else
            info "$server: does NOT have VIP ($vip) attached to network interface"
            debug "$ip_line"
         fi
      else
         warn "could not get the the network interface information for server: $server"
         debug "$ip_line"
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done looking for the attached VIP on the MASTERs" || update "done"
}

test_vip () {
# use nc (netcat) to test the ports using the VIPs
   update -n "testing the VIPs using netcat(nc)..."
   [ "$VERBOSE" = "TRUE" ] && echo
   for server in ${keepalived_masters[*]}; do
      debug "working on $server"
      if [ `echo "$server" | sed 's/-/ /g' | wc -w` -eq 2 ]; then
         ptti=`echo "$server" | cut -d'-' -f1`
      elif [ `echo "$server" | sed 's/-/ /g' | wc -w` -eq 3 ]; then
         ptti=`echo "$server" | cut -d'-' -f1-2`
      else
         ptti=""
         warn "can't figure out what type of server this is: $server"
      fi
      if [ -n "$ptti" ]; then
         port=${PORTS_TO_TEST[$ptti]}
         vip=${keepalived_servers_vips[$server]}
         debug "testing server group ($ptti) VIP ($vip) port ($port)"
         $NCCMD -n -v -w 3 -z $vip $port >> $LOGFILE 2>&1
         if [ $? -eq 0 ]; then
            info "VIP ($vip) test for server group $ptti: [ ${GRN}PASSED${NRM} ]"
         else
            warn "VIP ($vip) test for server group $ptti: [ ${RED}FAILED${NRM} ]"
         fi
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done looking for the attached VIP on the MASTERs" || update "done"
}

#
# MAIN
#

# get rid of any old logs
rm -f $LOGFILE 2> /dev/null

# parse command line options
while getopts "dhk:lno:sv" OPT; do
  case ${OPT} in
     d) DEBUG="TRUE";       debug "debugging turned on"                     ;;
     h) usage;              debug "usage requested";       exit 1           ;;
     k) KNIFE_RB=$OPTARG;   debug "knife.rb file option given"              ;;
     l) REMOVELOGS="FALSE"; debug "NOT removing log files when finished"    ;;
     n) AUTO_FIX="FALSE";   debug "NOT automatically fixing everything"     ;;
     o) OS_RC=$OPTARG;      debug "OpenStack RC file option given"          ;;
     v) VERBOSE="TRUE";     debug "verbose output turned on"                ;;
     ?) usage;              debug "unknown option given";  exit 1           ;;
  esac
done

# give name and location of the log file
update "the log file for this script is: [ $LOGFILE ]"

sanity_check                 # perform sanity checks
get_list_of_servers          # get list of servers that use keepalived
check_keepalived_conf        # verify only one MASTER configured for each VIP
look_for_attached_vip        # make sure the VIP is attached to the MASTER
test_vip                     # check connectivity to the VIPs

if [ "$REMOVELOGS" = "TRUE" ]; then   # get rid of any old logs
   info "removing log files"
   debug "removing file: $LOGFILE"
   [ "$VERBOSE" = "TRUE" ] && rm -rvf $LOGFILE || rm -rf $LOGFILE
else
   info "NOT removing log files"
   info " log file   : $LOGFILE"
fi

echo "all done"
exit 0
# EOF


