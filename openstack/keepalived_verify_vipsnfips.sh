#!/bin/bash
#
# description: Used to verify VIPs and FIPs configs and settings for keepalived
#              in/for an OpenStack infrastructure/environment
#
#              This script finds all the of the host running keepalived
#              (via knife) and checks the configrations and statuses of the
#              VIPs and FIPs
#
# Requirements: must have following to run this script
#  - commands - knife, nova, neutron, nc (netcat)
#
# TODO: The following improvements need/should be made
#  - currently only working for OpenStack, need to adapt for AWS too
#  - does not have logic to determine if the VIP is not attached to the MASTER
#    because it is down (or some other reason), then it is okay to have the VIP
#    attached to the BACKUP
#  - does not have the logic to check if the keepalived service is running or not
#    on the keeplived servers - currently it just restarts keepalive if it finds
#    problems (i.e. the VIP is not attached to the MASTER and/or attached to BACKUP
#  - need to handle time-outs from this command:  
#               vippll=`$NEUTRONCMD port-list | \fgrep '"'$vip'"'`
#
# updates:
#  21-SEP-2015 - initial build
#  01-OCT-2015 - changed the defaults to:
#		 "skip the stack verifications"
#		 "remove logs at the end"
#		 "automatically fix things"
#


# set some DEFAULTS
DEFAULT_REPOS_LOCATION=$HOME/repos       # set this to your repos root dir
DEFAULT_KNIFE_RB=$KNIFERB                # set this to your knife.rb env var (if applicable)
DEFAULT_OS_RC=$OSRC                      # set this to your OpenStack RC env var (if applicable)
# set some GLOBALs
CYN="\e[36m"                             # cyan color
GRN="\e[32m"                             # green color
RED="\e[31m"                             # red color
YLW="\e[33m"                             # yellow color
NRM="\e[m"                               # to make text normal
THIS_SCRIPT=`basename $0`
LOGFILE=`mktemp /tmp/$THIS_SCRIPT.XXX.log`
REPORTFILE=`echo $LOGFILE | sed 's/\.log$/.report/'`
AUTO_FIX="TRUE"                          # automatically fix stuff
DEBUG="FALSE"                            # do not produce debug output
NEEDS_FIP="FALSE"                        # used to determine if a server needs a FIP or not
REMOVELOGS="TRUE"                        # get rid of any old logs
SKIPSTACK="TRUE"                         # skip stack config verifications
VERBOSE="FALSE"                          # do not produce verbose output
USAGE="\
USAGE: $THIS_SCRIPT [OPTIONS]
DESCRIPTION: checks and verifies all VIPs and FIPs are configured and working correctly
OPTIONS (and defaults):
   -d   turn on debugging
   -h   help - show this message
   -k   name/location of knife.rb file           ($DEFAULT_KNIFE_RB)
   -l   keep log and report files when done      (default removes logs)
   -n   no - do NOT automatically fix everything (default auto fixes all)
   -o   name/location of OpenStack RC file       ($DEFAULT_OS_RC)
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
MAX_SGNL=21                              # max server group name length - for the report
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

report() {
   if [ "$VERBOSE" = "TRUE" ]; then
      [ "$1" = "-n" ] && (shift; echo -ne "report: $*") || echo -e "report: $*"
   fi
   [ "$1" = "-n" ] && (shift; echo -ne "$*" >> $REPORTFILE) || echo -e "$*" >> $REPORTFILE 
   #[ "$1" = "-n" ] && (shift; log -n "report: $*") || log "report: $*"
   [ "$1" = "-n" ] && (shift; log "report: $*") || log "report: $*"
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
   if [ -z "$KNIFE_RB" ]; then
      KNIFE_RB=$DEFAULT_KNIFE_RB
      debug "no knife.rb file given, set to default: $KNIFE_RB"
   else
      debug "knife.rb file given, set to: $KNIFE_RB"
   fi
   [ ! -e "$KNIFE_RB" ] && error "$KNIFECMDNAME config file not found: $KNIFE_RB"
   if [ "$SKIPSTACK" = "FALSE" ]; then
      debug "NOT skipping stack config verifications"
      if [ -z "$OS_RC" ]; then
         OS_RC=$DEFAULT_OS_RC
         debug "no OpenStack RC file given, set to default: $OS_RC"
      else
         debug "OpenStack RC file given, set to: $OS_RC"
      fi
      [ ! -e "$OS_RC" ] && error "OpenStack RC file not found: $OS_RC"
      source $OS_RC
      if [ -z "$OS_PASSWORD" -o -z "$OS_AUTH_URL" -o -z "$OS_USERNAME" -o -z "$OS_TENANT_NAME" ]; then
         error "all required OpenStack environment variables are NOT set"
      else
         debug "all required OpenStack environment variables are set"
      fi
      [ -z "$NEUTRONCMD" ] && error "required command '$NEUTRONCMDNAME' NOT found!" || debug "'$NEUTRONCMDNAME' installed: $NEUTRONCMD"
      [ -z "$NOVACMD" ] && error "required command '$NOVACMDNAME' NOT found!" || debug "'$NOVACMDNAME' installed: $NOVACMD"
   fi
   [ -z "$KNIFECMD" ] && error "required command '$KNIFECMDNAME' NOT found!" || debug "'$KNIFECMDNAME' installed: $KNIFECMD"
   [ -z "$NCCMD" ] && error "required command '$NCCMDNAME' NOT found!" || debug "'$NCCMDNAME' installed: $NCCMD"
}

get_list_of_servers() {
# get list of servers that use keepalived and VIPs
# and their ips and their VIPs
   max_snl=0		# set the initial max server name length
   update -n "getting list of servers that use keepalived..."
   [ "$VERBOSE" = "TRUE" ] && echo
   debug "using command: '$KNIFECMD search node 'recipes:keepalived\:\:default' -c $KNIFE_RB'"
   keepalived_servers=`$KNIFECMD search node 'recipes:keepalived\:\:default' -c $KNIFE_RB 2>&1 | \grep Node | awk '{print $3}' | sort`
   more_keepalived_servers=`$KNIFECMD search node 'recipes:keepalived' -c $KNIFE_RB 2>&1 | \grep Node | awk '{print $3}' | sort`
   for kads in $more_keepalived_servers; do
      echo "$keepalived_servers" | grep -q $kads
      [ $? -ne 0 ] && keepalived_servers="$keepalived_servers $kads"
   done
   [ "$VERBOSE" = "TRUE" ] && update "done getting list of keepalived servers" || update "done"
   debug "servers found:
$keepalived_servers"
   update -n "getting IPs and VIPs of keepalived servers (be patient)..."
   [ "$VERBOSE" = "TRUE" ] && echo
   debug " IPs  using this: '$KNIFECMD node show NODE -a ipaddress -c $KNIFE_RB'"
   debug " VIPs using this: '$KNIFECMD node show NODE -a $KEEPALIVED_VIP_ATTRIB -c $KNIFE_RB'"
   for server in $keepalived_servers; do
      #[ "$DEBUG" = "TRUE" ] && debug "working on $server" || log -n "working on $server "
      info "working on $server"
      node_ip=`$KNIFECMD node show $server -a ipaddress -c $KNIFE_RB | \grep ipaddress | awk '{print $2}'`
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
      #[ "$DEBUG" = "TRUE" ] && debug "node_ip: $node_ip" || log -n "IP $node_ip "
      info " $server node_ip: $node_ip"
      keepalived_servers_ips[$server]=$node_ip
      assigned_vip=`$KNIFECMD node show $server -a $KEEPALIVED_VIP_ATTRIB -c $KNIFE_RB | \grep vip | awk '{print $2}'`
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
      #[ "$DEBUG" = "TRUE" ] && debug "assigned VIP: $assigned_vip" || log "VIP $assigned_vip"
      info " $server assigned VIP: $assigned_vip"
      keepalived_servers_vips[$server]=$assigned_vip
      # get the length of the server name for reporting
      server_name_length=`expr length $server`
      [ $max_snl -lt $server_name_length ] && max_snl=$server_name_length
   done
   [ "$VERBOSE" = "TRUE" ] && update "done getting IPs and VIPs of keepalived servers - thanks for your patience" || update "done"
}

verify_vipnfip_on_stack () {
# verify VIP and FIP configs are correct in the Stack
   declare -A vip_existence               # keeps track of VIPs already verified
   declare -A fip_attached                # keeps track of VIPs with FIPs attached
   update -n "verifying VIP and FIP (if applicable) configs on stack..."
   [ "$VERBOSE" = "TRUE" ] && echo
   report "< stack (OpenStack) - VIP and FIP configuration verifications >"
   for server in $keepalived_servers; do
      NEEDS_FIP=FALSE
      debug "stack - checking if VIP needs a FIP"
      for _stnaf in $SERVERS_THAT_NEED_FIPS; do       # for server_that_needs_a_FIP
         echo "$server" | \grep -q "^$_stnaf"
         [ $? -eq 0 ] && NEEDS_FIP=TRUE
      done
      [ "$NEEDS_FIP" == "TRUE" ] && info "stack - verifying VIP and FIP for server: [ $server ]" || info "verifying VIP for server: [ $server ]"
      node_ip=${keepalived_servers_ips[$server]}
      assigned_vip=${keepalived_servers_vips[$server]}
      debug "$server's IP $node_ip and VIP $assigned_vip"
      if [ -n "$node_ip" -a -n "$assigned_vip" ]; then
         instance_interfaces=`$NOVACMD interface-list $server | \grep ACTIVE`
         if [ $? -eq 0 ]; then
            instance_portid=`echo $instance_interfaces | awk '{print $4}'`
            instance_netid=`echo $instance_interfaces | awk '{print $6}'`
            instance_ip=`echo $instance_interfaces | awk '{print $8}'`
            if [ $node_ip == $instance_ip ]; then
               debug "$server: node IP $node_ip and instance IP $instance_ip match"
            else
               warn "$server: node ip $node_ip and instance ip $instance_ip do NOT match"
            fi
            vip=$assigned_vip
            # check for the existence and configuration of the VIP on the stack
            if [ "${vip_existence[$vip]}" = "TRUE" ]; then
               info " stack - server $server VIP ($vip) existence already verified and configured"
            elif [ "${vip_existence[$vip]}" = "FALSE" ]; then
               info " stack - server $server VIP ($vip) existence already verified and NOT configured"
            else
               report -n "`printf \" configuration and existence verification of VIP (%15s): \" $vip`"
               vippll=`$NEUTRONCMD port-list | \fgrep '"'$vip'"'`
               if [ $? -eq 0 ]; then
                  report "[ ${GRN}PASSED${NRM} ]"
                  vip_existence[$vip]="TRUE"
                  info "stack - VIP ($vip) is configured and exists"
                  vipid=`echo $vippll | awk '{print $2}'`
               else
                  report "[ ${RED}FAILED${NRM} ]"
                  vip_existence[$vip]="FALSE"
                  warn "stack - VIP ($vip) is NOT configured and DOES NOT exists"
                  if [ "$AUTO_FIX" == "FALSE" ]; then
                     ans=""
                     [ "$VERBOSE" = "FALSE" ] && echo
                     echo "stack - VIP ($vip) is NOT configured and DOES NOT exists"
                     echo -n "do you want to create it [y/n]?: "
                     read ans
                  else
                     info "automatically fixing"
                  fi
                  if [ "$AUTO_FIX" == "TRUE" -o $ans == y -o $ans == Y ]; then
                     debug "stack - user chose to have the VIP ($vip) created"
                     for isg in `$NOVACMD list-secgroup $server | \egrep -v 'Id.*Name.*Description|------+------'|awk '{print $2}'`; do
                        # create port create security group options
                        [ -n "$pcsgo" ] && pcsgo="$pcsgo --security-group $isg" || pcsgo="--security-group $isg"
                     done
                     info "stack - creating the VIP ($vip)"
                     debug "using the following command:"
                     debug " $NEUTRONCMD port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid"
                     # create the VIP and save the UUID of it
                     vipid=`$NEUTRONCMD port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid | \fgrep "| id " | awk '{print $4}'`
                     if [ $? -eq 0 ]; then
                        vip_existence[$vip]="TRUE"
                        info "stack - successfully created VIP ($vip)"
                        report "`printf \"  VIP (%15s) creation: [ ${GRN}SUCCES${NRM} ]\n\" $vip`"
                     else
                        warn "stack - FAILED to create VIP ($vip)"
                        report "`printf \"  VIP (%15s) creation: [ ${RED}FAILED${NRM} ]\n\" $vip`"
                     fi
                  else
                     debug "stack - user chose NOT to have the VIP ($vip) created"
                     warn "stack - NOT creating the VIP ($vip)"
                  fi
               fi
            fi       # done checking for the existence and configuration of the VIP on the stack
            # check if the VIP needs a FIP and if so, if it is attached
            if [ "$NEEDS_FIP" = "TRUE" ]; then
               info "stack - $server: VIP ($vip) needs a FIP"
               if [ -n "${fip_attached[$vip]}" ]; then
                  info "stack - VIP ($vip) attached to FIP (${fip_attached[$vip]}) already verified"
               else
                  fipll=`$NEUTRONCMD floatingip-list | \fgrep " $vip "`     # floatingip list line
                  if [ $? -eq 0 ]; then
                     fip=`echo $fipll | awk '{print $6}'`
                     report "`printf \"  VIP (%15s) attached to FIP (%15s) verification: [ ${GRN}PASSED${NRM} ]\n\" $vip $fip`"
                     info "stack - VIP ($vip) is attached to FIP ($fip)"
                     fip_attached[$vip]=$fip
                  else
                     report "`printf \"  VIP (%15s) attached to a FIP verification: [ ${RED}FAILED${NRM} ]\n\" $vip`"
                     warn "stack - VIP ($vip) is NOT attached to a FIP"
                     if [ "$AUTO_FIX" == "FALSE" ]; then
                        ans=""
                        [ "$VERBOSE" = "FALSE" ] && echo
                        echo "stack - VIP ($vip) is NOT attached to a FIP"
                        echo -n "do you want to create a FIP and attach it to VIP ($vip) [y/n]?: "
                        read ans
                     else
                        info "automatically fixing"
                     fi
                     if [ "$AUTO_FIX" == "TRUE" -o $ans == y -o $ans == Y ]; then
                        debug "stack - user chose to create a FIP for VIP ($vip)"
                        info "stack - creating a FIP"
                        debug "using the following command:"
                        debug " $NEUTRONCMD floatingip-create $EXTERNAL_NET"
                        fipid=`$NEUTRONCMD floatingip-create $EXTERNAL_NET | \fgrep "| id " | awk '{print $4}'`
                        if [ $? -eq 0 ]; then
                           fip=`$NEUTRONCMD floatingip-list | \fgrep $fipid | awk '{print $6}'` 
                           info "stack - successfully created FIP ($fip)"
                        else
                           warn "stack - FAILED trying to create a FIP"
                        fi
                        info "stack - attaching FIP ($fip) to VIP ($vip)"
                        debug "using the following command"
                        debug " $NEUTRONCMD floatingip-associate $fipid $vipid"
                        $NEUTRONCMD floatingip-associate $fipid $vipid >> $LOGFILE 2>&1
                        if [ $? -eq 0 ]; then
                           info "stack - successfully attached VIP ($vip) to FIP ($fip)"
                           fip_attached[$vip]=$fip
                           report "`printf \"  FIP (%15s) creation and attaching to VIP (%15s): [ ${GRN}SUCCES${NRM} ]\n\" $fip $vip`"
                           echo "$server: VIP ($vip) is now attached to FIP ($fip)"
                        else
                           warn "stack - FAILED trying to attached VIP ($vip) to FIP ($fip)"
                           report "`printf \"  FIP (%15s) creation and attaching to VIP (%15s): [ ${RED}FAILED${NRM} ]\n\" $fip $vip`"
                        fi
                     else
                        debug "stack - user chose NOT to create/attach a FIP for VIP ($vip)"
                        info "stack - NOT creating/attaching a FIP for VIP ($vip)"
                     fi
                  fi
               fi
            else
               info "stack - VIP ($vip) does NOT need a FIP"
            fi                      # done checking if the VIP needs a FIP and if so, if it is attached
            report -n "`printf \"  VIP (%15s) traffic allowed to %${max_snl}s verification: \" $vip $server`"
            ipsal=`$NEUTRONCMD port-show $instance_portid | \fgrep allowed_address_pairs | \fgrep '"'$vip'"' | awk '{print $2,$4,$5,$6,$7}'`
            if [ $? -eq 0 ]; then
               report "[ ${GRN}PASSED${NRM} ]"
               info "stack - VIP ($vip) is allowed to send traffic to instance $server"
               debug "  $ipsal"
            else
               report "[ ${RED}FAILED${NRM} ]"
               warn "stack - VIP ($vip) is NOT allowed to send traffic to instance $server"
               if [ "$AUTO_FIX" == "FALSE" ]; then
                  ans=""
                  [ "$VERBOSE" = "FALSE" ] && echo
                  echo "stack - VIP ($vip) is NOT allowed to send traffic to instance $server"
                  echo -n "do you want to allow it [y/n]?: "
                  read ans
               else
                  info "automatically fixing"
               fi
               if [ "$AUTO_FIX" == "TRUE" -o $ans == y -o $ans == Y ]; then
                  debug "stack - user chose to allow VIP ($vip) to send traffic to $server"
                  info "stack - allowing VIP ($vip) to send traffic to $server"
                  debug "using the following command:"
                  debug " $NEUTRONCMD port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip"
                  $NEUTRONCMD port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip >> $LOGFILE 2>&1
                  if [ $? -eq 0 ]; then
                     info "stack - successfully allowed VIP ($vip) access to instance $server"
                     report "`printf \"  allowing VIP (%15s) access to instance %${max_snl}s: [ ${GRN}SUCCES${NRM} ]\" $vip $server`"
                  else
                     warn "stack - FAILED trying to allow VIP ($vip) access to instance $server"
                     report "`printf \"  allowing VIP (%15s) access to instance %${max_snl}s: [ ${RED}FAILED${NRM} ]\" $vip $server`"
                  fi
               else
                  debug "$server: user chose NOT to allow VIP ($vip) to send traffic to the instance"
                  warn "NOT allowing VIP ($vip) to send traffic to the instance $server"
               fi
            fi
         else
            warn "cannot get the interface info for instance: $server"
         fi
      else
         warn "cannot get the IP and VIP information for server: $server"
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done verifying VIP and FIP configs on stack" || update "done"
}

check_keepalived_conf () {
# run a command on multiple servers matching a given pattern
  # looking for one of these 2 lines in the $KEEPALIVED_CONF file
  #state MASTER #primary peer(s) should be set to MASTER
  #state BACKUP #secondary peer(s) should be set to BACKUP
   list_of_vips=`mktemp`
   
   update -n "checking keepalived configs ($KEEPALIVED_CONF) on all servers..."
   [ "$VERBOSE" = "TRUE" ] && echo
   report "< keepalived configurations - getting master and backup servers >"
   debug "getting the MASTERs and BACKUPs"
   for server in $keepalived_servers; do
      debug "working on $server"
      vip=${keepalived_servers_vips[$server]}
      echo $vip >> $list_of_vips
      kad_state=`ssh ${keepalived_servers_ips[$server]} "grep state $KEEPALIVED_CONF" 2>> $LOGFILE`
      if [ -n "$kad_state" ]; then
         report -n "`printf \" %${max_snl}s keepalived role: \" $server`"
         echo "$kad_state" | grep -i "state MASTER" >> $LOGFILE 2>&1
         if [ $? -eq 0 ]; then
            report "[ ${GRN}MASTER${NRM} ]"
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
               report "[ ${GRN}BACKUP${NRM} ]"
               info "the keepalived role for server $server is: [ BACKUP ]"
               if [ -z "${keepalived_backups[$vip]}" ]; then
                  keepalived_backups[$vip]=$server
               else
                  info "found more than one backup for $server VIP ($vip)"
                  keepalived_backups[$vip]="${keepalived_backups[$vip]} $server"
               fi
            else
               report "[ ${RED}ERROR${NRM} ]"
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
   report "< keepalived configurations - verifying only one master and no dups for each VIP >"
   for vip in `cat $list_of_vips`; do
      debug "working on VIP ($vip)"
      no_of_masters=`echo ${keepalived_masters[$vip]} | wc -w`
      report -n "`printf \" verification of VIP (%15s) only having one MASTER: \" $vip`"
      if [ $no_of_masters -gt 1 ]; then
         report "[ ${RED}FAILED${NRM} ]"
         info "VIP ($vip) has more than one master: ${keepalived_masters[$vip]}"
         for master in ${keepalived_masters[$vip]}; do
            echo "${keepalived_backups[$vip]}" | grep -q "$master"
            [ $? -eq 0 ] && warn "found a duplicate: $master is also configured as a BACKUP"
         done
      elif [ $no_of_masters -eq 1 ]; then
         report "[ ${GRN}PASSED${NRM} ]"
         info "VIP ($vip) only has one MASTER: ${keepalived_masters[$vip]}"
         echo "${keepalived_backups[$vip]}" | grep -q "${keepalived_masters[$vip]}"
         [ $? -eq 0 ] && warn "found a duplicate: ${keepalived_masters[$vip]} is also configured as a BACKUP"
      elif [ $no_of_masters -eq 0 ]; then
         report "[ ${RED}FAILED${NRM} ]"
         warn "VIP ($vip) does NOT have a MASTER"
      else
         report "[ ${RED}FAILED${NRM} ]"
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
# makes sure the VIPs are attached to the MASTER keepalived peers
# if not - will restart keepalived
# looking for lines similar to the following from the `ip -f inet address` command
#   inet 10.180.9.250/32 scope global eth0
#   inet 10.180.146.91/32 scope global eth0
   
   update -n "looking for the attached VIP on the MASTERs..."
   [ "$VERBOSE" = "TRUE" ] && echo
   report "< keepalived - verifying VIPs attached to NICs on MASTER servers >"
   for server in ${keepalived_masters[*]}; do
      debug "working on $server"
      vip=${keepalived_servers_vips[$server]}
      ip_line=`ssh ${keepalived_servers_ips[$server]} "ip -f inet address" 2>> $LOGFILE`
      report -n "`printf \" verifying VIP (%15s) attached to MASTER %${max_snl}s: \" $vip $server`"
      if [ -n "$ip_line" ]; then
         echo "$ip_line" | grep -iq "inet $vip/"
         if [ $? -eq 0 ]; then
            report "[ ${GRN}PASSED${NRM} ]"
            info "$server: does have VIP ($vip) attached to network interface"
            debug "$ip_line"
         else
            report "[ ${RED}FAILED${NRM} ]"
            warn "$server: does NOT have VIP ($vip) attached to network interface"
            debug "$ip_line"
            if [ "$AUTO_FIX" == "FALSE" ]; then
               ans=""
               [ "$VERBOSE" = "FALSE" ] && echo
               echo "$server: does NOT have VIP ($vip) attached to network interface"
               echo -n "do you want to restart keepalived [y/n]?: "
               read ans
            else
               info "automatically fixing"
            fi
            if [ "$AUTO_FIX" = "TRUE" -o "$ans" = "y" -o "$ans" = "Y" ]; then
               debug "user chose to restart keepalived"
               info "restarting keepalived on $server"
               ssh ${keepalived_servers_ips[$server]} "sudo service keepalived restart" >> $LOGFILE 2>&1
               if [ $? -eq 0 ]; then
                  report "`printf \" restarting of keepalived service on MASTER %${max_snl}s: [ ${GRN}SUCCES${NRM} ]\n\" $server`"
               else
                  report "`printf \" restarting of keepalived service on MASTER %${max_snl}s: [ ${RED}FAILED${NRM} ]\n\" $server`"
               fi
            else
               debug "user chose NOT to restart keepalived"
               info "NOT restarting keepalived on $server"
            fi
         fi
      else
         report "[ ${RED}FAILED${NRM} ]"
         warn "could not get the the network interface information for server: $server"
         debug "$ip_line"
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done looking for the attached VIP on the MASTERs" || update "done"
   update -n "making sure the VIP is NOT attached to any BACKUPs..."
   [ "$VERBOSE" = "TRUE" ] && echo
   report "< keepalived - verifying VIPs NOT attached to NICs on any BACKUP servers >"
   for server in ${keepalived_backups[*]}; do
      debug "working on $server"
      vip=${keepalived_servers_vips[$server]}
      ip_line=`ssh ${keepalived_servers_ips[$server]} "ip -f inet address" 2>> $LOGFILE`
      report -n "`printf \" verifying VIP (%15s) NOT attached to BACKUP %${max_snl}s: \" $vip $server`"
      if [ -n "$ip_line" ]; then
         echo "$ip_line" | grep -iq "inet $vip/"
         if [ $? -eq 0 ]; then
            report "[ ${RED}FAILED${NRM} ]"
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
               if [ $? -eq 0 ]; then
                  report "`printf \" restarting of keepalived service on BACKUP %${max_snl}s: [ ${GRN}SUCCES${NRM} ]\n\" $server`"
               else
                  report "`printf \" restarting of keepalived service on BACKUP %${max_snl}s: [ ${RED}FAILED${NRM} ]\n\" $server`"
               fi
            else
               debug "user chose NOT to restart keepalived"
               info "NOT restarting keepalived on $server"
            fi
         else
            report "[ ${GRN}PASSED${NRM} ]"
            info "$server: does NOT have VIP ($vip) attached to network interface"
            debug "$ip_line"
         fi
      else
         report "[ ${RED}FAILED${NRM} ]"
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
   report "< VIPs functionality - testing connectivity to VIPs >"
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
         report -n "`printf \" server group (%${MAX_SGNL}s) VIP (%15s) port (%5s) connectivity test: \" $ptti $vip $port`"
         debug "testing server group ($ptti) VIP ($vip) port ($port)"
         $NCCMD -n -v -w 3 -z $vip $port >> $LOGFILE 2>&1
         if [ $? -eq 0 ]; then
            report "[ ${GRN}PASSED${NRM} ]"
            info "VIP ($vip) test for server group $ptti: [ ${GRN}PASSED${NRM} ]"
         else
            report "[ ${RED}FAILED${NRM} ]"
            warn "VIP ($vip) test for server group $ptti: [ ${RED}FAILED${NRM} ]"
         fi
      fi
      [ "$VERBOSE" = "FALSE" ] && echo -n "."
   done
   [ "$VERBOSE" = "TRUE" ] && update "done looking for the attached VIP on the MASTERs" || update "done"
}

display_report () {
   max_line_len=0
   update "displaying the results of the tests"
   echo "-------------------------------------------------------------"
   while read line; do
      str_len=`expr length "$line"`
      [ $max_line_len -lt $str_len ] && max_line_len=$str_len
   done <<< "`cut -d: -f1 $REPORTFILE`"
   while read line; do
      echo "$line" | \fgrep -q ":"
      if [ $? -eq 0 ]; then
         first_part=`echo -e "$line" | cut -d: -f1`
         second_part=`echo -e "$line" | cut -d: -f2`
         line=`printf "%-${max_line_len}s: %s" "$first_part" "$second_part"`
      fi
      echo -e "$line"
   done < $REPORTFILE
   echo "-------------------------------------------------------------"
}

#
# MAIN
#

# get rid of any old logs
rm -f $LOGFILE 2> /dev/null
rm -f $REPORTFILE 2> /dev/null

# parse command line options
while getopts "dhk:lno:sv" OPT; do
  case ${OPT} in
     d) DEBUG="TRUE";       debug "debugging turned on"                     ;;
     h) usage;              debug "usage requested";       exit 1           ;;
     k) KNIFE_RB=$OPTARG;   debug "knife.rb file option given"              ;;
     l) REMOVELOGS="FALSE"; debug "NOT removing log files when finished"    ;;
     n) AUTO_FIX="FALSE";   debug "NOT automatically fixing everything"     ;;
     o) OS_RC=$OPTARG;      debug "OpenStack RC file option given"          ;;
     s) SKIPSTACK="FALSE";  debug "NOT skipping stack config verifications" ;;
     v) VERBOSE="TRUE";     debug "verbose output turned on"                ;;
     ?) usage;              debug "unknown option given";  exit 1           ;;
  esac
done

# give name and location of the log file
update "the log file for this script is: [ $LOGFILE ]"

sanity_check                 # perform sanity checks
get_list_of_servers          # get list of servers that use keepalived
if [ "$SKIPSTACK" = "FALSE" ]; then
   verify_vipnfip_on_stack   # verify the VIP and FIP settings on the stack
fi
check_keepalived_conf        # verify only one MASTER configured for each VIP
look_for_attached_vip        # make sure the VIP is attached to the MASTER
test_vip                     # check connectivity to the VIPs
display_report               # display the report

if [ "$REMOVELOGS" = "TRUE" ]; then   # get rid of any old logs
   info "removing log files"
   debug "removing file: $LOGFILE"
   debug "removing file: $REPORTFILE"
   [ "$VERBOSE" = "TRUE" ] && rm -rvf $LOGFILE || rm -rf $LOGFILE
   [ "$VERBOSE" = "TRUE" ] && rm -rvf $REPORTFILE || rm -rf $REPORTFILE
else
   info "NOT removing log files"
   info " log file   : $LOGFILE"
   info " report file: $REPORTFILE"
fi

echo "all done"
exit 0
# EOF


