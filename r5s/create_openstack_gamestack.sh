#!/bin/bash
#
# Discription: Create game servers in Openstack environment
#
# Usage: (See below or run with the "-h" option)
#
# TODO
#  - make sure there is not a server with the same name that already exists
#  - generate report at the end of all succeeded/failed servers
#  - if anything related to the VIPs/FIPs on the MCP's changed at all - need to re-cheff them
#  - add option to specify r5envname - using a default (R5_ENV_NAME) for now
#  - make sure verify that the build decryption keys exist on webkeys
#  - make sure verify that the game build exist on S3
#  - change the `nova boot` section to just run the command (not in a seperate xterm) and repeat
#    until successful - checking first if it already exists
#  - figure out how to stop the bootstrap command from asking for my password
#  - and options to specify which coremissions servers to build - currently builds set of all 4
#  - gotta fix the dry-run option/functionality
#  - gotta implement the throttling feature
#  - seems to be a bug using global "server_name" variable - make use of locals
#  - add pool option and have it default to pool 1
#  - add time-out counts and the availability for the user to abort
#
# Overview
#
# requirements: must have following to run this script
#  - commands - knife, nova, neutron, nc (netcat)
#
# updates:
#  10-NOV-2015 - PAR: initial build
#

# set some DEFAULTS
DEFAULT_KNIFE_RB=$KNIFERB                # set to your knife.rb file     or use -k option
DEFAULT_OS_RC=$OSRC                      # set to your OpenStack RC file or use -o option
DEFAULT_SSH_KEY=$HOME/.ssh/id_rsa        # set to your ssh private key   or use -i option
DEFAULT_SW_YAML_FILE=$SW_YAML_FILE       # set to your spiceweasel YAML  or use -s option
DEFAULT_THROTTLE=8                       # set how many to do at a time  or use -t option
DEF_NO_MCPs=2                            # default number of mcp's to build
DEF_NO_MMs=2                             # default number of matchmaker's to build
DEF_NO_MDs=1                             # default number of matchdirector's to build
DEF_NO_NEs=0                             # default number of neweden's to build
DEF_NO_PVEs=0                            # default number of pve's to build
DEF_NO_BLs=0                             # default number of battlelab's to build
DEF_NO_CMs=0                             # default number of coremission's to build each
NOCMS=4                                  # number of coremission types that exist
DEF_POOL_NUM=1                           # default pool to build servers in
POOL_SVRS="neweden|coremissions"         # list of servers that are pool specific, arg to egrep
# set some GLOBALs
CYN="\e[36m"                             # cyan color
GRN="\e[32m"                             # green color
RED="\e[31m"                             # red color
YLW="\e[33m"                             # yellow color
NRM="\e[m"                               # normal text
THIS_SCRIPT=`basename $0`
LOGFILE=`mktemp /tmp/$THIS_SCRIPT.XXX.log`
REPORTFILE=`echo $LOGFILE | sed 's/\.log$/.report/'`
DEBUG="FALSE"                            # do not produce debug output
REMOVELOGS="TRUE"                        # get rid of any old logs
VERBOSE="FALSE"                          # do not produce verbose output
POOLS_2A3="FALSE"                        # do not build pool 2 and 3 servers too
MCP_VIP_EXISTS="FALSE"                   # does the MCP VIP EXIST?
DRY_RUN="FALSE"                          # do not perform a dry-run
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"
KEEPALIVED_VIP_ATTRIB="keepalived.vip"   # used to get node attrib of VIP from keepalived databag
GAME_SVR_BUILD_ATTRIB="r5_build_number"  # used to get node's build number it was created with
EXTERNAL_NET="net04_ext"                 # used when creating FIPs - set to name of external network
R5_ENV_NAME="china_prod"                 # used when creating FIPs - set to name of external network
# get/set the default build number
MCP_TO_GET_DEF_BUILD_FROM=`knife node list -c $DEFAULT_KNIFE_RB 2>> $LOGFILE | /bin/grep game-mcp | /usr/bin/head -1`
DEFAULT_BUILD=`knife node show -a $GAME_SVR_BUILD_ATTRIB $MCP_TO_GET_DEF_BUILD_FROM -c $DEFAULT_KNIFE_RB 2>> $LOGFILE | /bin/grep build_number | awk '{print $2}'`
[ -z "$DEFAULT_BUILD" ] && DEFAULT_BUILD="UNKNOWN"
# required commands
KNIFECMDNAME="knife";              KNIFECMD=`which $KNIFECMDNAME`
NEUTRONCMDNAME="neutron";          NEUTRONCMD=`which $NEUTRONCMDNAME`
NOVACMDNAME="nova";                NOVACMD=`which $NOVACMDNAME`
OPENSTACKCMDNAME="openstack";      OPENSTACKCMD=`which $OPENSTACKCMDNAME`
SPICEWEASELCMDNAME="spiceweasel";  SPICEWEASELCMD=`which $SPICEWEASELCMDNAME`
XTERM="/usr/bin/xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000"
MAX_SNL=21                               # max server name length - for the report
declare -A server_ips                    # track IPs of the servers created (index: server_name/value: IP)
declare -A openstack_images=(            # openstack images (index: server_type/value: name of image)
 [game-battlelab]=game-battlelab-snapshot
 [game-coremission]=game-coremissions-snapshot
 [game-match]=game-match-snapshot
 [game-mcp]=game-mcp-snapshot
 [game-neweden]=game-neweden-snapshot
 [game-pve]=game-pve-snapshot
)
USAGE="\
USAGE: $THIS_SCRIPT [OPTIONS]
DESCRIPTION: create game stack servers in Openstack environment
OPTIONS:
  To control amount/type of servers to build and (defaults)
    -g   game build number                  ($DEFAULT_BUILD=build on $MCP_TO_GET_DEF_BUILD_FROM)
    -b   number of battlelab's to create    ($DEF_NO_BLs)
    -c   number of coremissions to create   ($DEF_NO_CMs each of all $NOCMS)
    -1   number of coremission1's to create (overides '-c' option/default)
    -2   number of coremission2's to create (overides '-c' option/default)
    -3   number of coremission3's to create (overides '-c' option/default)
    -4   number of coremission4's to create (overides '-c' option/default)
    -n   number of neweden's to create      ($DEF_NO_NEs)
    -e   number of pve's to create          ($DEF_NO_PVEs)
    -p   pool to create servers in          ($DEF_POOL_NUM)
    -z   availability zone to put servers in
  To specify name/locations of files/dirs and (defaults)
    -i   ssh private key file               ($DEFAULT_SSH_KEY)
    -k   knife.rb file                      ($DEFAULT_KNIFE_RB)
    -o   Openstack RC file                  ($DEFAULT_OS_RC)
    -s   spiceweasel YAML file              ($DEFAULT_SW_YAML_FILE)
  To control output/function of this script
    -d   turn on debugging
    -h   help - show this message
    -l   keep log and report files when done
    -v   turn on verbose output
    -x   perform a dry-run (to verify commands) [Buggy - Use at your own risk]
EXAMPLE:
   $THIS_SCRIPT -ns -k ~/repos/.chef/knife.rb -o ~/.openstackrc\
"

debug() {
   [ "$DEBUG" = "TRUE" -a "$VERBOSE" = "TRUE" ] && echo -e "${CYN}DEBUG${NRM}: $*"
   [ "$DEBUG" = "TRUE" ] && log "DEBUG: $*"
}

error() {
   echo -e "${RED}ERROR${NRM}: $*"
   log "ERROR: $*"
   exit 2
}

info() {
   if [ "$VERBOSE" = "TRUE" ]; then
      [ "$1" = "-n" ] && (shift; echo -ne "INFO: $*") || echo -e "INFO: $*"
   fi
   [ "$1" = "-n" ] && (shift; log -n "INFO: $*") || log "INFO: $*"
}

log() {
   [ "$1" = "-n" ] && (shift; echo -ne "$*" >> $LOGFILE) || echo -e "$*" >> $LOGFILE 
}

report() {
   if [ "$VERBOSE" = "TRUE" ]; then
      [ "$1" = "-n" ] && (shift; echo -ne "REPORT: $*") || echo -e "REPORT: $*"
   fi
   [ "$1" = "-n" ] && (shift; echo -ne "$*" >> $REPORTFILE) || echo -e "$*" >> $REPORTFILE 
   [ "$1" = "-n" ] && (shift; log "REPORT: $*") || log "REPORT: $*"
}

update() {
   [ "$1" = "-n" ] && (shift; echo -ne "$*") || echo -e "$*"
   [ "$1" = "-n" ] && (shift; log "UPDATE: $*") || log "UPDATE: $*"
}

usage() {
   echo "$USAGE"
}

warn() {
   if [ "$VERBOSE" = "TRUE" ]; then
      echo -e "${YLW}WARNING${NRM}: $*"
   fi
   log "WARNING: $*"
}

sanity_check() {
# perform a bunch of sanity checks
   debug "starting 'sanity_check(args=$*)'"
   if [ -z "$BUILD" ]; then
      if [ $DEFAULT_BUILD != "UNKNOWN" ]; then
         BUILD=$DEFAULT_BUILD
         debug "no build number given, set to default: $BUILD"
      else
         error "no build number given and default is $DEFAULT_BUILD"
      fi
   else
      debug "build number given, set to: $BUILD"
   fi
   if [ -z "$KNIFE_RB" ]; then
      KNIFE_RB=$DEFAULT_KNIFE_RB
      debug "no knife.rb file given, set to default: $KNIFE_RB"
   else
      debug "knife.rb file given, set to: $KNIFE_RB"
   fi
   [ ! -e "$KNIFE_RB" ] && error "$KNIFECMDNAME config file not found: $KNIFE_RB"
   if [ -z "$SSH_KEY" ]; then
      SSH_KEY=$DEFAULT_SSH_KEY
      debug "no SSH key file given, set to default: $SSH_KEY"
   else
      debug "SSH key file given, set to: $SSH_KEY"
   fi
   [ ! -e "$SSH_KEY" ] && error "SSH key file not found: $SSH_KEY"
   if [ -z "$OS_RC" ]; then
      OS_RC=$DEFAULT_OS_RC
      debug "no OpenStack RC file given, set to default: $OS_RC"
   else
      debug "OpenStack RC file given, set to: $OS_RC"
   fi
   [ ! -e "$OS_RC" ] && error "OpenStack RC file not found: $OS_RC"
   source $OS_RC
   if [ -z "$OS_PASSWORD" -o -z "$OS_AUTH_URL" -o -z "$OS_USERNAME" -o -z "$OS_TENANT_NAME" ]; then
      warn "all required OpenStack environment variables are NOT set"
      debug "OS_PASSWORD   ='$OS_PASSWORD'"
      debug "OS_AUTH_URL   ='$OS_AUTH_URL'"
      debug "OS_USERNAME   ='$OS_USERNAME'"
      debug "OS_TENANT_NAME='$OS_TENANT_NAME'"
      error "cannnot run OpenStack CLIs without all environment variables being set"
   else
      debug "all required OpenStack environment variables are set"
   fi
   if [ -z "$SW_YAML_FILE" ]; then
      SW_YAML_FILE=$DEFAULT_SW_YAML_FILE
      debug "no $SPICEWEASELCMDNAME YAML file given, set to default: $SW_YAML_FILE"
   else
      debug "$SPICEWEASELCMDNAME YAML file given, set to: $SW_YAML_FILE"
   fi
   [ ! -e "$SW_YAML_FILE" ] && error "$SPICEWEASELCMDNAME YAML file not found: $SW_YAML_FILE"
   if [ -z "$POOL_NUM" ]; then
      printf -v POOL_NUM "%d" $DEF_POOL_NUM
      printf -v POOL_ID "p%02d" $POOL_NUM
      debug "no pool number given, set to default: $POOL_NUM (pool ID: $POOL_ID)"
   else
      printf -v POOL_NUM "%d" $POOL_NUM
      printf -v POOL_ID "p%02d" $POOL_NUM
      debug "pool number given, set to: $POOL_NUM (pool ID: $POOL_ID)"
   fi
   if [ -z "$NO_OF_CM1" ]; then
      if [ -z "$NO_OF_CM" ]; then
         NO_OF_CM1=$DEF_NO_CMs
         debug "quantity of CoreMissions to build NOT given, set to default: $NO_OF_CM1"
      else
         NO_OF_CM1=$NO_OF_CM
         debug "quantity of CoreMissions specified, set quantity of CoreMissions1 to: $NO_OF_CM1"
      fi
   else
      debug "quantity of CoreMissions1 specified, set to: $NO_OF_CM1"
   fi
   if [ -z "$NO_OF_CM2" ]; then
      if [ -z "$NO_OF_CM" ]; then
         NO_OF_CM2=$DEF_NO_CMs
         debug "quantity of CoreMissions to build NOT given, set to default: $NO_OF_CM2"
      else
         NO_OF_CM2=$NO_OF_CM
         debug "quantity of CoreMissions specified, set quantity of CoreMissions2 to: $NO_OF_CM2"
      fi
   else
      debug "quantity of CoreMissions2 specified, set to: $NO_OF_CM2"
   fi
   if [ -z "$NO_OF_CM3" ]; then
      if [ -z "$NO_OF_CM" ]; then
         NO_OF_CM3=$DEF_NO_CMs
         debug "quantity of CoreMissions to build NOT given, set to default: $NO_OF_CM3"
      else
         NO_OF_CM3=$NO_OF_CM
         debug "quantity of CoreMissions specified, set quantity of CoreMissions3 to: $NO_OF_CM3"
      fi
   else
      debug "quantity of CoreMissions3 specified, set to: $NO_OF_CM3"
   fi
   if [ -z "$NO_OF_CM4" ]; then
      if [ -z "$NO_OF_CM" ]; then
         NO_OF_CM4=$DEF_NO_CMs
         debug "quantity of CoreMissions to build NOT given, set to default: $NO_OF_CM4"
      else
         NO_OF_CM4=$NO_OF_CM
         debug "quantity of CoreMissions specified, set quantity of CoreMissions4 to: $NO_OF_CM4"
      fi
   else
      debug "quantity of CoreMissions4 specified, set to: $NO_OF_CM4"
   fi
   if [ -z "$NO_OF_NE" ]; then
      NO_OF_NE=$DEF_NO_NEs
      debug "quantity of NewEdens to build NOT given, set to default: $NO_OF_NE"
   else
      debug "quantity of NewEdens specified, set to: $NO_OF_NE"
   fi
   if [ -z "$NO_OF_PV" ]; then
      NO_OF_PV=$DEF_NO_PVEs
      debug "quantity of PVEs to build NOT given, set to default: $NO_OF_PV"
   else
      debug "quantity of PVEs specified, set to: $NO_OF_PV"
   fi
   if [ -z "$NO_OF_BL" ]; then
      NO_OF_BL=$DEF_NO_BLs
      debug "quantity of BattleLabs to build NOT given, set to default: $NO_OF_BL"
   else
      debug "quantity of BattleLabs specified, set to: $NO_OF_BL"
   fi
   [ -z "$NEUTRONCMD" ] && error "required command '$NEUTRONCMDNAME' NOT found!" || debug "'$NEUTRONCMDNAME' installed: $NEUTRONCMD"
   [ -z "$NOVACMD" ] && error "required command '$NOVACMDNAME' NOT found!" || debug "'$NOVACMDNAME' installed: $NOVACMD"
   [ -z "$KNIFECMD" ] && error "required command '$KNIFECMDNAME' NOT found!" || debug "'$KNIFECMDNAME' installed: $KNIFECMD"
   [ -z "$OPENSTACKCMD" ] && error "required command '$OPENSTACKCMDNAME' NOT found!" || debug "'$OPENSTACKCMDNAME' installed: $OPENSTACKCMD"
   [ -z "$SPICEWEASELCMD" ] && error "required command '$SPICEWEASELCMDNAME' NOT found!" || debug "'$SPICEWEASELCMDNAME' installed: $SPICEWEASELCMD"
   debug "end of 'sanity_check()'"
}

verify_spiceweasel_repo_current () {
# make sure that the spiceweasel repo is up to date and current
   debug "starting 'verify_spiceweasel_repo_current(args=$*)'"
   update "verifying your spiceweasel repo is current"
   SPICEWEASELREPO=`dirname $SW_YAML_FILE`
   cd $SPICEWEASELREPO >> $LOGFILE
   hg incoming >> $LOGFILE
   if [ $? -eq 0 ]; then
      echo -n "your $SPICEWEASELCMDNAME repo not up to date - updating... "
      hg pull -uv >> $LOGFILE
      echo "done"
   else
      echo "$SPICEWEASELCMDNAME repo is up to date."
   fi
   cd - >> $LOGFILE
   debug "end of 'verify_spiceweasel_repo_current()'"
}

get_vpc_no_and_availability_zones () {
# get the vpc we're working in and the list of AV's
   debug "starting 'get_vpc_no_and_availability_zones(args=$*)'"
   cmd_output=`mktemp /tmp/$THIS_SCRIPT.command.XXXX.out`
   update "getting the VPC number and game availability zones"
   vpc=`echo $OS_TENANT_NAME | cut -d'-' -f2`		# get the vpc number from rc file
   vpcsn=`echo $vpc | sed 's/pc//'`			# convert to short name
   $OPENSTACKCMD availability zone list -f value -c "Zone Name" > $cmd_output 2>> $LOGFILE
   while [ $? -ne 0 ]; do
      warn "couldn't get availability zone list - '$OPENSTACKCMD availability zone list' command timed-out or failed - retrying"
      $OPENSTACKCMD availability zone list -f value -c "Zone Name" > $cmd_output 2>> $LOGFILE
   done
   availability_zones=`grep ${vpcsn}-game $cmd_output | sort | tr '\n' ' '`
   if [ -n "$availability_zones" ]; then
      info "found these availability zones: $availability_zones"
      if [ -n "$AVAIL_ZONES" ]; then
         echo "$availability_zones" | /bin/fgrep -q $AVAIL_ZONES
         if [ $? -eq 0 ]; then
            availability_zones=$AVAIL_ZONES
         else
            error "incorrect availability zone specified. pick one from these: $availability_zones"
         fi
      fi
   else
      error "could not get availability zones"
   fi
   noaz=`echo $availability_zones | wc -w`		# get how many availability zones there are
   rm -f $cmd_output
   debug "end of 'get_vpc_no_and_availability_zones()'"
}

attach_vip_and_fip () {
# Attach a VIP to a server and associate with a FIP
   debug "starting 'attach_vip_and_fip(args=$*)'"
   declare -A vip_created   # keep track of VIPs already created (index: IP/value: TRUE|FALSE)
   declare -A fip_attached  # keep track of VIPs with FIPs attached (index: IP/value: FIP)
   cmd_output=`mktemp /tmp/$THIS_SCRIPT.command.XXXX.out`
   server=$1
   $NOVACMD interface-list $server > $cmd_output 2>> $LOGFILE
   while [ $? -ne 0 ]; do
      warn "could not get interface list for $server - '$NOVACMD interface-list $server' command timed-out or failed - retrying"
      $NOVACMD interface-list $server > $cmd_output 2>> $LOGFILE
   done
   instance_interfaces=`/bin/fgrep ACTIVE $cmd_output`
   if [ $? -eq 0 ]; then
      instance_portid=`echo $instance_interfaces | awk '{print $4}'`
      instance_netid=`echo $instance_interfaces | awk '{print $6}'`
   else
      warn "could NOT get the interface info for server: '$server'"
   fi
   vip=`$KNIFECMD node show $server -a $KEEPALIVED_VIP_ATTRIB -c $KNIFE_RB | /bin/grep vip | awk '{print $2}'`
   if [ -n "$vip" ]; then
      # create the VIP
      if [ "${vip_created[$vip]}" != "TRUE" ]; then	# the VIP might not be created already 
         info "trying to attach VIP ($vip) to '$server'"
         $NEUTRONCMD port-list > $cmd_output
         while [ $? -ne 0 ]; do
            warn "could not get port list - $NEUTRONCMD command timed-out or failed - trying again"
            $NEUTRONCMD port-list > $cmd_output
         done
         vippll=`/bin/fgrep $vip $cmd_output`
         if [ $? -eq 0 ]; then      # now we're sure it's been created and exists
            info "VIP ($vip) already exists"
            vip_created["${vip}"]="TRUE"
         else               # probably sure it has NOT been created - the 'port-list' cmd could have failed
            # if we try to create it and it already exists - openstack will just give a warning
            if [ -n "$instance_netid" ]; then 
               $NOVACMD list-secgroup $server > $cmd_output 2>> $LOGFILE
               while [ $? -ne 0 ]; do
                  warn "could not get security group list for $server - '$NOVACMD list-secgroup $server' command timed-out or failed - retrying"
                  $NOVACMD list-secgroup $server > $cmd_output 2>> $LOGFILE
               done
               for isg in `/bin/egrep -v 'Id.*Name.*Description|------+------' $cmd_output | awk '{print $2}'`; do
                  [ -n "$pcsgo" ] && pcsgo="$pcsgo --security-group $isg" || pcsgo="--security-group $isg" 
               done
               info "VIP ($vip) does not exist, creating with the following command:"
               info "  $NEUTRONCMD port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid"
               if [ $DRY_RUN = "FALSE" ]; then
                  vipid=`$NEUTRONCMD port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid 2>> $LOGFILE | /bin/fgrep "| id " | awk '{print $4}'`
                  while [ -z "$vidid" ]; do
                     warn "could not create the VIP ($vip) - $NEUTRONCMD command timed-out or failed - retrying"
                     vipid=`$NEUTRONCMD port-create --fixed-ip ip_address=$vip $pcsgo $instance_netid 2>> $LOGFILE | /bin/fgrep "| id " | awk '{print $4}'`
                  done
               else
                  vipid="dry-run-vipid"
                  info "dry-run - not running the command"
               fi
               if [ $? -eq 0 ]; then
                  vip_created["${vip}"]="TRUE"
                  info "the VIP ($vip) was successfully created"
               else
                  vip_created["${vip}"]="FALSE"
                  warn "could NOT create the VIP ($vip)"
               fi
            else
               vip_created["${vip}"]="FALSE"
               warn "could NOT create the VIP ($vip) because the instance net ID is unknown"
            fi
         fi
      else
         info "VIP ($vip) already exists"
      fi
      # allow the VIP to send traffic to the instance
      if [ -n "$instance_portid" ]; then 
         ipsal=`$NEUTRONCMD port-show $instance_portid 2>> $LOGFILE | /bin/fgrep allowed_address_pairs | /bin/fgrep '"'$vip'"'`
         while [ -z "$ipsal" ]; do
            warn "could NOT get allowed_address_pair for $server - $NEUTRONCMD command timed-out or failed - retrying"
            ipsal=`$NEUTRONCMD port-show $instance_portid 2>> $LOGFILE | /bin/fgrep allowed_address_pairs`
         done
         echo "$ipsal" | /bin/fgrep -q $vip
         if [ $? -eq 0 ]; then
            info "VIP ($vip) is already allowed to send traffic to '$server'"
            debug "  $ipsal"
         else
            info "allowing the VIP ($vip) to send traffic to '$server' with the following command:"
            info "  $NEUTRONCMD port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip"
            if [ $DRY_RUN = "FALSE" ]; then
               $NEUTRONCMD port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip 2>> $LOGFILE
               while [ $? -ne 0 ]; do
                  warn "could not update the port for $server - $NEUTRONCMD command timed-out or failed - retrying"
                  $NEUTRONCMD port-update $instance_portid --allowed_address_pairs list=true type=dict ip_address=$vip 2>> $LOGFILE
               done
               info "VIP ($vip) is now allowed to send traffic to '$server'"
            else
               info "dry-run - not running the command"
            fi
         fi
      else
         warn "could NOT allow VIP ($vip) to send traffic to '$server' - instance port ID unknown"
      fi
      # attach the VIP to a FIP
      if [ -n "${fip_attached[$vip]}" ]; then     # the VIP seems like it is NOT attached to a FIP
         $NEUTRONCMD floatingip-list > $cmd_output 2>> $LOGFILE
         while [ $? -ne 0 ]; do
            warn "could NOT get floating IP list - '$NEUTRONCMD floatingip-list' command timed-out or failed - retrying"
            $NEUTRONCMD floatingip-list > $cmd_output 2>> $LOGFILE
         done
         fipll=`/bin/fgrep " $vip " $cmd_output`
         if [ $? -eq 0 ]; then         # found a FIP attached to the VIP
            fip=`echo $fipll | awk '{print $6}'`
            fip_attached["${vip}"]="$fip"
            info "VIP ($vip) is attached to FIP ($fip)"
         else
            info "VIP is not attached to a FIP - creating one with the following command:"
            info "  $NEUTRONCMD floatingip-create $EXTERNAL_NET"
            if [ $DRY_RUN = "FALSE" ]; then
               $NEUTRONCMD floatingip-create $EXTERNAL_NET > $cmd_output 2>> $LOGFILE
               while [ $? -ne 0 ]; do
                  warn "could not create a FIP - '$NEUTRONCMD floatingip-create $EXTERNAL_NET' command timed-out or failed - retrying"
                  $NEUTRONCMD floatingip-create $EXTERNAL_NET > $cmd_output 2>> $LOGFILE
               done
               info "the FIP was successfully created"
               fipid=`/bin/fgrep "| id " $cmd_output | awk '{print $4}'`
            else
               info "dry-run - not running the command"
               fipid="dummy-DRY-RUN-fipid"
            fi
            if [ -n "$fipid" ]; then
               info "attaching the FIP using the following command"
               info "  $NEUTRONCMD floatingip-associate $fipid $vipid"
               if [ $DRY_RUN = "FALSE" ]; then
                  $NEUTRONCMD floatingip-associate $fipid $vipid >> $LOGFILE 2>&1
                  while [ $? -ne 0 ]; do
                     warn "could NOT associate FIP to VIP - '$NEUTRONCMD floatingip-associate $fipid $vipid' command timed-out or failed - retrying"
                     $NEUTRONCMD floatingip-associate $fipid $vipid >> $LOGFILE 2>&1
                  done
                  info "VIP ($vip) is now attached to FIP ($fip)"
                  fip=`/bin/fgrep "| floating_ip_address " $cmd_output | awk '{print $4}'`
                  fip_attached["${vip}"]="$fip"         # record the attachment
               else
                  info "dry-run - not running the command"
               fi
            else
               warn "could not create a FIP to attach VIP ($vip)"
            fi
         fi
      else
         info "VIP ($vip) is attached to FIP (${fip_attached[$vip]})"
      fi
   else
      warn "problem getting VIP for '$server' from knife node attribute: $KEEPALIVED_VIP_ATTRIB"
   fi
   rm -f $cmd_output
   debug "end of 'attach_vip_and_fip()'"
}

attach_fip () {
# verify a FIP is attached to the instance - if not create a FIP and attach it
   debug "starting 'attach_fip(args=$*)'"
   cmd_output=`mktemp /tmp/$THIS_SCRIPT.command.XXXX.out`
   local server_name=$1
   get_server_ip $server_name
   sip=${server_ips[$server_name]}                  # sip=server IP
   [ $DRY_RUN = "TRUE" ] && sip="dummy-DRY-RUN-ip"
   update "attaching a FIP to IP ($sip) for '$server_name'"
   if [ -n "$sip" ]; then
      debug "getting interface list"
      $NOVACMD interface-list $server_name > $cmd_output 2>> $LOGFILE
      while [ $? -ne 0 ]; do
         warn "could not get interface list for $server_name - '$NOVACMD interface-list $server_name' command timed-out or failed - retrying"
         $NOVACMD interface-list $server_name > $cmd_output 2>> $LOGFILE
      done
      instance_interfaces=`/bin/fgrep ACTIVE $cmd_output`
      if [ $? -eq 0 -o $DRY_RUN = "TRUE" ]; then
         instance_portid=`echo $instance_interfaces | awk '{print $4}'`
         info "creating FIP with the following command:"
         info "  $NEUTRONCMD floatingip-create $EXTERNAL_NET"
         if [ $DRY_RUN = "FALSE" ]; then
            $NEUTRONCMD floatingip-create $EXTERNAL_NET > $cmd_output 2>> $LOGFILE
            while [ $? -ne 0 ]; do
               warn "could not create a FIP - '$NEUTRONCMD floatingip-create $EXTERNAL_NET' command timed-out or failed - retrying"
               $NEUTRONCMD floatingip-create $EXTERNAL_NET > $cmd_output 2>> $LOGFILE
            done
            info "the FIP was successfully created"
            fipid=`/bin/fgrep "| id " $cmd_output | awk '{print $4}'`
            info "attaching the FIP using the following command"
            info "  $NEUTRONCMD floatingip-associate $fipid $instance_portid"
            if [ $DRY_RUN = "FALSE" ]; then
               $NEUTRONCMD floatingip-associate $fipid $instance_portid >> $LOGFILE 2>&1
               while [ $? -ne 0 ]; do
                  warn "could NOT associate FIP to IP ($sip) - '$NEUTRONCMD floatingip-associate $fipid $vipid' command timed-out or failed - retrying"
                  $NEUTRONCMD floatingip-associate $fipid $instance_portid >> $LOGFILE 2>&1
               done
               fip=`/bin/fgrep "| floating_ip_address " $cmd_output | awk '{print $4}'`
               info "IP ($sip) is now attached to FIP ($fip)"
            else
               info "dry-run - not running the command"
            fi
         else
            fipid="dummy-DRY-RUN-fipid"
            info "dry-run - not running the command"
         fi
         
      else
         warn "could NOT get the interface info for '$server_name'"
      fi
   else
      warn "problem attaching FIP to '$server_name'"
   fi
   rm -f $cmd_output
   debug "end of 'attach_fip()'"
}

generate_run_knife_bootstrap_command () {
   debug "starting 'generate_run_knife_bootstrap_command(args=$*)'"
   local server_name=$1
   server_match_pattern=`echo $server_name | cut -d'-' -f1-2`			# server grep pattern
   update "attempting to bootstrap $server_name with 'knife bootstrap'"
   get_server_ip $server_name
   sip=${server_ips[$server_name]}                  # sip=server IP
   [ $DRY_RUN = "TRUE" ] && sip="dummy-DRY-RUN-ip"
   info "getting the 'knife create' command via spiceweasel"
   knife_server_create_cmd=`$SPICEWEASELCMD $SW_YAML_FILE | /bin/grep -w $server_match_pattern | sort -u`
   no_of_sw_lines_matched=`echo $knife_server_create_cmd | wc -l`
   if [ $no_of_sw_lines_matched -gt 1 ]; then
      warn "too many lines in the spiceweasel file match this pattern: $server_match_pattern"
      warn "cannot bootstrap this server: $server_name"
   else
      info "getting values: roles and bootstrap URL"
      roles=`echo "$knife_server_create_cmd" | awk 'BEGIN {RS=" "} found=="true" {print $1;exit}; $1=="-r" {found="true"}'`
      bsurl=`echo "$knife_server_create_cmd" | awk 'BEGIN {RS=" "} found=="true" {print $1;exit}; $1=="--bootstrap-url" {found="true"}'`
      info "creating the knife bootstrap command"
      echo $server_name | egrep -q "$POOL_SVRS"
      if [ $? -eq 0 ]; then
         knife_bootstrap_display="$KNIFECMD bootstrap $sip -y -r $roles -x $OS_USERNAME -i $SSH_KEY --sudo -c $KNIFE_RB -N $server_name -j '{\\\"r5_build_number\\\":$BUILD,\\\"firefall\\\":{\\\"r5envname\\\":\\\"$R5_ENV_NAME\\\"},\\\"pool_id\\\":\\\"$POOL_NUM\\\"}' --bootstrap-url $bsurl"
         knife_bootstrap_cmd="$KNIFECMD bootstrap $sip -y -r $roles -x $OS_USERNAME -i $SSH_KEY --sudo -c $KNIFE_RB -N $server_name -j '{\"r5_build_number\":$BUILD,\"firefall\":{\"r5envname\":\"$R5_ENV_NAME\"},\"pool_id\":\"$POOL_NUM\"}' --bootstrap-url $bsurl"
      else
         knife_bootstrap_display="$KNIFECMD bootstrap $sip -y -r $roles -x $OS_USERNAME -i $SSH_KEY --sudo -c $KNIFE_RB -N $server_name -j '{\\\"r5_build_number\\\":$BUILD,\\\"firefall\\\":{\\\"r5envname\\\":\\\"$R5_ENV_NAME\\\"}}' --bootstrap-url $bsurl"
         knife_bootstrap_cmd="$KNIFECMD bootstrap $sip -y -r $roles -x $OS_USERNAME -i $SSH_KEY --sudo -c $KNIFE_RB -N $server_name -j '{\"r5_build_number\":$BUILD,\"firefall\":{\"r5envname\":\"$R5_ENV_NAME\"}}' --bootstrap-url $bsurl"
      fi
      update "------ bootstraping ($server_name) command ------"
      update "$knife_bootstrap_cmd"
      if [ $DRY_RUN = "FALSE" ]; then
         $XTERM -e 'echo "------ bootstraping ('"$server_name"') ------"; echo "'"$knife_bootstrap_display"'" ; echo "-------- ------------ ------ --------" ; '"$knife_bootstrap_cmd"' ; echo "------ bootstraped ('"$server_name"') ------" ; echo "'"$knife_bootstrap_display"'" ; bash' &
         pid=$!
      else
         info "dry-run - not running the command"
      fi
   fi
   debug "end of 'generate_run_knife_bootstrap_command()'"
   return=$pid
}

get_server_ip () {
# get the server's ip address and save it in the 
   debug "starting 'get_server_ip(args=$*)'"
   cmd_output=`mktemp /tmp/$THIS_SCRIPT.command.XXXX.out`
   local server_name=$1
   info "attempting to get the IP address of server: $server_name"
   if [ -n "${server_ips[$server_name]}" ]; then       # already have it
      sip=${server_ips[$server_name]}                  # sip=server IP
      debug "already have it: $server_name ($sip)"
   else                                                # don't have it - get it from openstack (nova)
      $NOVACMD show $server_name > $cmd_output 2>> $LOGFILE
      while [ $? -ne 0 ]; do
         warn "could not show interface info for $server_name - '$NOVACMD show $server_name' command timed-out or failed - retrying"
         $NOVACMD show $server_name > $cmd_output 2>> $LOGFILE
      done
      sip=`/bin/fgrep network $cmd_output | awk '{print $5}'`	# sip=server IP
      if [ -n "$sip" ]; then
         server_ips[$server_name]=$sip
      else
         server_ips[$server_name]=UNKNOWN
      fi
   fi
   rm -f $cmd_output
   debug "end of 'get_server_ip()'"
}

generate_run_nova_boot_command () {
# generate the "nova boot" command to use to create the new server
   debug "starting 'generate_run_nova_boot_command(args=$*)'"
   cmd_output=`mktemp /tmp/$THIS_SCRIPT.command.XXXX.out`
   local server_name=$1
   update "attempting to create $server_name with 'nova boot'"
   server_match_pattern=`echo $server_name | cut -d'-' -f1-2`
   case $server_name in
      *battlelab*)   server_type=game-battlelab   ;;
      *coremission*) server_type=game-coremission ;;
      *match*)       server_type=game-match       ;;
      *mcp*)         server_type=game-mcp         ;;
      *neweden*)     server_type=game-neweden     ;;
      *pve*)         server_type=game-pve         ;;
   esac
   debug "getting the server create command via spiceweasel"
   knife_server_create_cmd=`$SPICEWEASELCMD $SW_YAML_FILE | /bin/grep -w $server_match_pattern | sort -u`
   no_of_sw_lines_matched=`echo $knife_server_create_cmd | wc -l`
   if [ $no_of_sw_lines_matched -gt 1 ]; then
      warn "too many lines in the spiceweasel file match this pattern: $server_match_pattern"
      warn "cannot create this server: $server_name"
   else
      image=${openstack_images[$server_type]}
      info "getting values: flavor, security groups, key name, net ID and availability zone"
      flavor=`echo "$knife_server_create_cmd" | awk 'BEGIN {RS=" "} found=="true" {print $1;exit}; $1=="-f" {found="true"}'`
      secgrps=`echo "$knife_server_create_cmd" | awk 'BEGIN {RS=" "} found=="true" {print $1;exit}; $1=="-g" {found="true"}'`
      keyname=`echo "$knife_server_create_cmd" | awk 'BEGIN {RS=" "} found=="true" {print $1;exit}; $1=="-S" {found="true"}'`
      net_id=`echo "$knife_server_create_cmd" | awk 'BEGIN {RS=" "} found=="true" {print $1;exit}; $1=="--network" {found="true"}'`
      a_zone=`echo "$availability_zones" | awk -v azn=$az_num '{print $azn}'`
      [ $((++az_num)) -gt $noaz ] && az_num=1
      if [ -n "$image" -a -n "$flavor" -a -n "$secgrps" -a -n "$keyname" -a -n "$net_id" -a -n "$a_zone" ]; then
         info "creating the nova boot command"
         nova_boot_cmd="$NOVACMD boot --poll --flavor $flavor --image $image --security-groups \"$secgrps\" --key-name $keyname --nic net-id=$net_id --availability-zone $a_zone $server_name"
         update "-------- creating ($server_name) command --------"
         update "$nova_boot_cmd"
         if [ $DRY_RUN = "FALSE" ]; then
            $NOVACMD boot --flavor $flavor --image $image --security-groups "$secgrps" --key-name $keyname --nic net-id=$net_id --availability-zone $a_zone $server_name >> $LOGFILE 2>&1
            while [ $? -ne 0 -a "$srv_exists" != "TRUE" ]; do
               warn "could not create $server_name - '$NOVACMD boot' command timed-out or failed - retrying"
               $NOVACMD list > $cmd_output 2>> $LOGFILE
               while [ $? -ne 0 ]; do
                  warn "could NOT list instances - '$NOVACMD list' command timed-out or failed - retrying"
                  $NOVACMD list > $cmd_output 2>> $LOGFILE
               done
               /bin/grep $server_name $cmd_output | /bin/fgrep -q ACTIVE
               if [ $? -eq 0 ]; then      # the server exists and is ACTIVE
                  srv_exists="TRUE"
                  info "$server_name exists and it's status is 'ACTIVE'"
               else                       # the server does NOT exist and is NOT ACTIVE
                  info "$server_name was NOT made or is NOT 'ACTIVE' - retrying to build it"
                  $NOVACMD boot --flavor $flavor --image $image --security-groups "$secgrps" --key-name $keyname --nic net-id=$net_id --availability-zone $a_zone $server_name >> $LOGFILE 2>&1
               fi
            done
            get_server_ip $server_name
            sip=${server_ips[$server_name]}                  # sip=server IP
            debug "created: $server_name ($sip)"
            retstatus=0
         else
            info "dry-run - not running the command"
            retstatus=5
         fi
      else
         warn "cannot generate '$NOVACMD boot' command for $server_name - don't have all the necessary variables"
         debug "image  ='$image'"
         debug "flavor ='$flavor'"
         debug "secgrps='$secgrps'"
         debug "keyname='$keyname'"
         debug "net_id ='$net_id'"
         debug "a_zone ='$a_zone'"
         retstatus=1
      fi
   fi
   rm -f $cmd_output
   debug "end of 'generate_run_nova_boot_command()'"
   return $retstatus
}

generate_gsuid () {
# generate a game server UID
   printf "%x" `date +%s`
}

build_bootstrap_core_servers () {
# build/bootstrap the core game servers
   debug "starting 'build_bootstrap_core_servers(args=$*)'"
   local server_name
   server_prefix=$1
   qty_to_bld=$2
   update "attempting to build $qty_to_bld $server_prefix core server(s)"
   qty_to_bts=0
   # check if there are $server_prefix servers already built
   existing_svrs=`$KNIFECMD node list -c $KNIFE_RB | /bin/grep $server_prefix`
   noes=`echo "$existing_svrs" | wc -l`
   if [ $noes -gt $qty_to_bld ]; then	# there are too many servers, panic ;)
      error "there seems to be $noes $server_prefix servers, which is more then desired ($qty_to_bld)"
   fi
   if [ $noes -gt 0 ]; then	# there are existing MCP servers, let's check their build versions
      for existing in $existing_svrs; do
         ((qty_to_bld--))
         current_build_no=`knife node show -a $GAME_SVR_BUILD_ATTRIB $existing -c $KNIFE_RB 2>> $LOGFILE | /bin/grep build_number | awk '{print $2}'`
         [ -z "$current_build_no" ] && error "can't get build number for server: $existing"
         if [ $current_build_no = $BUILD ]; then
            info "$existing is already running build: $BUILD"
         else
            ((qty_to_bts++))
            info "$existing is currently running different build: $current_build_no"
            info "need to bootstrap $existing with the new build: $BUILD"
            list_of_svrs_to_bootstrap="$list_of_svrs_to_bootstrap $existing"
         fi
      done
   fi
   if [ $qty_to_bld -gt 0 ]; then            # not enough servers - build some
      info "need to build/bootstrap $qty_to_bld $server_prefix servers"
      for i in `seq $qty_to_bld`; do
         server_name="$server_prefix-$(generate_gsuid)"
         generate_run_nova_boot_command $server_name
         if [ $? -eq 0 ]; then
            echo $server_name | /bin/fgrep -q game-mcp
            if [ $? -eq 0 ]; then
               attach_vip_and_fip $server_name  # verify the vip/fip's are good for both existing's
            fi
         else
            debug "generate_run_nova_boot_command() returned non-zero"
         fi
         generate_run_knife_bootstrap_command $server_name
      done
   fi
   if [ $qty_to_bts -gt 0 ]; then            # servers running wrong build - bootstrap them
      info "need to bootstrap $qty_to_bts $server_prefix servers"
      for server in $list_of_svrs_to_bootstrap; do
         generate_run_knife_bootstrap_command $server
      done
   fi
   debug "end of 'build_bootstrap_core_servers()'"
}

build_non_core_servers () {
# build some game servers
   debug "starting 'build_non_core_servers(args=$*)'"
   local server_name
   local server_prefix=$1
   qty_to_bld=$2
   update "attempting to build $qty_to_bld $server_prefix non_core server(s) in pool $POOL_NUM"
   if [ $qty_to_bld -gt 0 ]; then
      for i in `seq $qty_to_bld`; do
         server_name="$server_prefix-$(generate_gsuid)"
         generate_run_nova_boot_command $server_name
         if [ $? -eq 0 ]; then
            attach_fip $server_name  # verify the vip/fip's are good for both mcp's
         else
            debug "generate_run_nova_boot_command() returned non-zero"
         fi
         generate_run_knife_bootstrap_command $server_name
      done
   fi
   debug "end of 'build_non_core_servers()'"
}

build_mcp_servers () {
# build/bootstrap 2 game-mcp servers
   debug "starting 'build_mcp_servers(args=$*)'"
   update "building mcp servers"
   build_bootstrap_core_servers game-mcp $DEF_NO_MCPs
   debug "end of 'build_mcp_servers()'"
}

build_matchmaker_servers () {
# build/build 2 game-matchmaker servers
   debug "starting 'build_matchmaker_servers(args=$*)'"
   update "building matchmaker servers"
   build_bootstrap_core_servers game-matchmaker $DEF_NO_MMs
   debug "end of 'build_matchmaker_servers()'"
}

build_matchdirector_servers () {
# build 1 game-matchdirector servers
   debug "starting 'build_matchdirector_servers(args=$*)'"
   update "building matchdirector servers"
   build_bootstrap_core_servers game-matchdirector $DEF_NO_MDs
   debug "end of 'build_matchdirector_servers()'"
}

build_neweden_servers () {
# build game-neweden servers
   debug "starting 'build_neweden_servers(args=$*)'"
   update "building neweden servers"
   build_non_core_servers game-neweden-$POOL_ID $NO_OF_NE
   debug "end of 'build_neweden_servers()'"
}

build_pve_servers () {
# build game-pve servers
   debug "starting 'build_pve_servers(args=$*)'"
   update "building pve servers"
   build_non_core_servers game-pve $NO_OF_PV
   debug "end of 'build_pve_servers()'"
}

build_battlelab_servers () {
# build battlelab servers
   debug "starting 'build_battlelab_servers(args=$*)'"
   update "building battelab servers"
   build_non_core_servers game-battlelab $NO_OF_BL
   debug "end of 'build_battlelab_servers()'"
}

build_coremissions_servers () {
# build game-coremissions servers
   debug "starting 'build_coremissions_servers(args=$*)'"
   update "building coremissions servers"
   build_non_core_servers game-coremissions1-$POOL_ID $NO_OF_CM1
   build_non_core_servers game-coremissions2-$POOL_ID $NO_OF_CM2
   build_non_core_servers game-coremissions3-$POOL_ID $NO_OF_CM3
   build_non_core_servers game-coremissions4-$POOL_ID $NO_OF_CM4
   debug "end of 'build_coremissions_servers()'"
}

display_report () {
   debug "starting 'display_report(args=$*)'"
   max_line_len=0
   update "displaying the results of the tests"
   echo "-------------------------------------------------------------"
   while read line; do
      str_len=`expr length "$line"`
      [ $max_line_len -lt $str_len ] && max_line_len=$str_len
   done <<< "`cut -d: -f1 $REPORTFILE`"
   while read line; do
      echo "$line" | /bin/fgrep -q ":"
      if [ $? -eq 0 ]; then
         first_part=`echo -e "$line" | cut -d: -f1`
         second_part=`echo -e "$line" | cut -d: -f2`
         line=`printf "%-${max_line_len}s: %s" "$first_part" "$second_part"`
      fi
      echo -e "$line"
   done < $REPORTFILE
   echo "-------------------------------------------------------------"
   debug "end of 'display_report()'"
}

cleanup () {
   debug "starting 'cleanup(args=$*)'"
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
      debug "end of 'cleanup()'"
   fi
}

#
# MAIN
#

# get rid of any old logs
rm -f $LOGFILE 2> /dev/null
rm -f $REPORTFILE 2> /dev/null

# set the initial availability zone to the first one
az_num=1

# parse command line options
while getopts "g:b:c:1:2:3:4:n:e:p:z:i:k:o:s:dhlvx" OPT; do
  case ${OPT} in
     g) BUILD=$OPTARG;        debug "game build number option given"         ;;
     b) NO_OF_BL=$OPTARG;     debug "number of battlelab's option given"     ;;
     c) NO_OF_CM=$OPTARG;     debug "number of coremissions' option given"   ;;
     1) NO_OF_CM1=$OPTARG;    debug "number of coremissions1's option given" ;;
     2) NO_OF_CM2=$OPTARG;    debug "number of coremissions2's option given" ;;
     3) NO_OF_CM3=$OPTARG;    debug "number of coremissions3's option given" ;;
     4) NO_OF_CM4=$OPTARG;    debug "number of coremissions4's option given" ;;
     n) NO_OF_NE=$OPTARG;     debug "number of neweden's option given"       ;;
     e) NO_OF_PV=$OPTARG;     debug "number of PVE's option given"           ;;
     p) POOL_NUM=$OPTARG;     debug "pool number option given"               ;;
     z) AVAIL_ZONES=$OPTARG;  debug "availability zone option given"         ;;
     i) SSH_KEY=$OPTARG;      debug "SSH private key file name option given" ;;
     k) KNIFE_RB=$OPTARG;     debug "knife.rb file option given"             ;;
     o) OS_RC=$OPTARG;        debug "OpenStack RC file option given"         ;;
     s) SW_YAML_FILE=$OPTARG; debug "spiceweasel YAML file option given"     ;;
     d) DEBUG="TRUE";         debug "debugging turned on"                    ;;
     h) usage;                debug "usage requested"; cleanup;       exit 5 ;;
     l) REMOVELOGS="FALSE";   debug "NOT removing log files when finished"   ;;
     v) VERBOSE="TRUE";       debug "verbose output turned on"               ;;
     x) DRY_RUN="TRUE";       debug "dry-run turned on"                      ;;
     ?) usage;                debug "unknown option given"; cleanup;  exit 5 ;;
  esac
done

# give name and location of the log file
update "the log file for this script is: [ $LOGFILE ]"

sanity_check                       # perform sanity checks
verify_spiceweasel_repo_current    # make sure the spiceweasel repo is up to date
get_vpc_no_and_availability_zones  # get the vpc we're working in and the list of AV's
build_mcp_servers                  # build/bootstrap 2 game-mcp servers
build_matchmaker_servers           # build 2 game-matchmaker servers
build_matchdirector_servers        # build 1 game-matchdirector servers
build_neweden_servers              # build game-neweden servers
build_pve_servers                  # build game-pve servers
build_battlelab_servers            # build battlelab servers
build_coremissions_servers         # build game-coremissions servers
#display_report                     # display the report
cleanup                            # cleanup/remove files

echo "all done - now go get your game on and test the shit out of it!"
exit 0
# EOF
