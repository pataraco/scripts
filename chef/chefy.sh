#!/bin/bash
#
# Used to find Chef shit out
# 
# note: make sure to set your environment up first
#
# todo: 
#   - add code notifying if there are updates or not (i.e. if running on old repo)
#   - add code to figure out dynamic recipes

# set some GLOBALs
REPO_DIR=/opt/repo
ROLE_DIR=$REPO_DIR/roles
CB_DIR=$REPO_DIR/cookbooks
# set character to use for showing depth (tree) - don't use '\' and <esc> specials
#DEPTH_CHAR="\t"	# use tabs
#DEPTH_CHAR=" -> "	# use arrows
#DEPTH_CHAR=" |- "
DEPTH_CHAR="├── "
BRC="└"
LTB="├"
HBR="─"
VBR="│"

look_for_includes() {
   depth=$(/bin/echo "$depth"|sed 's/\'"$DEPTH_CHAR"'/    /')
   depth="${depth}$DEPTH_CHAR"
   while `grep -v '^#' $recipe_file | grep -qF "include_recipe"`; do
      #echo "recipe_file: $recipe_file"
      #for cb_rec in `grep -F "include_recipe" $recipe_file | cut -d'"' -f2`; do
      for cb_rec in `grep -v '^#' $recipe_file | grep -F "include_recipe" | awk '{print $2}'`; do
         #echo "cb_rec: $cb_rec"
         echo $cb_rec | grep -q '^"'
         if [ $? -eq 0 ]; then
            cb_rec=$(echo "$cb_rec" | cut -d'"' -f2)
         fi 
         echo $cb_rec | grep -q "^'"
         if [ $? -eq 0 ]; then
            cb_rec=$(echo "$cb_rec" | cut -d"'" -f2)
         fi 
         echo $cb_rec | grep -qF "::"
         if [ $? -eq 0 ]; then
            cookbook="`echo $cb_rec | cut -d: -f1`"
            recipe="`echo $cb_rec | cut -d: -f3`.rb"
         else
            cookbook=$cb_rec
            recipe="default.rb"
         fi
         recipe_dir="$CB_DIR/$cookbook/recipes"
         echo $recipe | grep -qF "install_method"
         if [ $? -eq 0 ]; then
            recipe="install_package.rb"
         fi
         /bin/echo -e "$depth$cookbook::$recipe"
         recipe_file="$recipe_dir/$recipe"
         grep -v '^#' $recipe_file | grep -qF "include_recipe"
         if [ $? -eq 0 ]; then
            look_for_includes
         fi
      done
   done
      #depth=$(/bin/echo $depth|sed 's/\\t//')
      #depth=$(/bin/echo "$depth"|sed 's/\'"$DEPTH_CHAR"'//')
      depth=$(/bin/echo "$depth"|sed 's/\'"$DEPTH_CHAR"'//')
}

# make sure we're in the correct directory
cd $REPO_DIR

echo $1 | grep -qF "::"
if [ $? -eq 0 ]; then
   cookbook="`echo $1 | cut -d: -f1`"
   recipe="`echo $1 | cut -d: -f3`.rb"
else
   cookbook=$1
   recipe="default.rb"
fi
recipe_file="$CB_DIR/$cookbook/recipes/$recipe"
depth=""

echo "$cookbook::$recipe"

grep -v '^#' $recipe_file | grep -qF "include_recipe"
if [ $? -eq 0 ]; then
   look_for_includes
fi

cd - > /dev/null

# put an exit here so that i don't have to delete my old code - LOL!
exit

# get the list of webapp servers
WEB_APP_SERVERS=`knife node list | grep webapp`

echo "Here are the webapp servers"
for node in $WEB_APP_SERVERS; do
   #echo "  ============"
   #echo "  ----"
   roles=`knife node show $node | grep ^Roles | cut -d: -f2 | tr -d ','`
   #echo "  Here are ${node}'s roles: $roles"
   for role in $roles; do
      #echo "    $role"
      # look for the r5_loadbalancer::thin recipe in the role
      role_file="$ROLE_DIR/$role.rb"
      #echo "role: $role_file"
      if [ -e $role_file ]; then
         line=`grep 'recipe.*r5_loadbalancer.*thin' $role_file`
         if [ $? -eq 0 ]; then
            #/bin/echo -e "$node\t(role): \t $role: \t $line"
            /usr/bin/printf "%-32s\t( role )\t%-26s\t%s\n" "$node" "$role" "$line"
         fi
      else
         /usr/bin/printf "%-32s\t( role )\t%-26s\tdoes not exist\n" "$node" "$role"
      fi
   done
   recipes=`knife node show $node | grep ^Recipes | sed 's/Recipes://' | tr -d ','`
   #echo "  Here are ${node}'s recipes: $recipes"
   for recipe in $recipes; do
      echo $recipe | grep -qF "::"
      if [ $? -eq 0 ]; then
         recipe_dir="/opt/repo/cookbooks/`echo $recipe | cut -d: -f1`"
         recipe_file="$recipe_dir/recipes/`echo $recipe | cut -d: -f3`.rb"
      else
         recipe_dir="/opt/repo/cookbooks/$recipe"
         recipe_file="$recipe_dir/recipes/default.rb"
      fi
      #echo "   recipe: $recipe -> $recipe_file"
      if [ -e $recipe_file ]; then
         line=`grep 'include.*r5_loadbalancer.*thin' $recipe_file`
         if [ $? -eq 0 ]; then
            #/bin/echo -e "$node\t(recipe): \t $recipe: \t $line"
            /usr/bin/printf "%-32s\t(recipe)\t%-26s\t%s\n" "$node" "$recipe" "$line"
         fi
         line=`grep 'include.*r5_loadbalancer.*mysql' $recipe_file`
         if [ $? -eq 0 ]; then
            #/bin/echo -e "$node\t(recipe): \t $recipe: \t $line"
            /usr/bin/printf "%-32s\t(recipe)\t%-26s\t%s\n" "$node" "$recipe" "$line"
         fi
      else
         #/bin/echo -e "$node\t(recipe): \t $recipe: \t does not exist"
         /usr/bin/printf "%-32s\t(recipe)\t%-26s\tdoes not exist\n" "$node" "$recipe"
      fi
   done
done

# get back to the dir we were in
cd - > /dev/null

# put an exit here so that i don't have to delete my old code - LOL!
exit

# set the delimiter to use in the log file
D="|"		# keeping the name of the variable short

# set the name/location of the logfile
LATENCY_LOG_FILE="/var/log/latencylog"
##LATENCY_LOG_FILE="/tmp/latencylog"	# temp for testing purposes

# header line in log file
LOG_HEADER="Date${D}Time${D}From Host${D}From IP${D}To Ashburn1${D}Ashburn1 IP${D}Ashburn1 RT Min${D}Ashburn1 RT Max${D}Ashburn1 RT Avg${D}Ashburn1 Pkt Loss${D}To Ashburn2${D}Ashburn2 IP${D}Ashburn2 RT Min${D}Ashburn2 RT Max${D}Ashburn2 RT Avg${D}Ashburn2 Pkt Loss${D}To Chicago1${D}Chicago1 IP${D}Chicago1 RT Min${D}Chicago1 RT Max${D}Chicago1 RT Avg${D}Chicago1 Pkt Loss${D}To Chicago2${D}Chicago2 IP${D}Chicago2 RT Min${D}Chicago2 RT Max${D}Chicago2 RT Avg${D}Chicago2 Pkt Loss${D}To Denver1${D}Denver1 IP${D}Denver1 RT Min${D}Denver1 RT Max${D}Denver1 RT Avg${D}Denver1 Pkt Loss${D}To Denver2${D}Denver2 IP${D}Denver2 RT Min${D}Denver2 RT Max${D}Denver2 RT Avg${D}Denver2 Pkt Loss${D}To Irvine1${D}Irvine1 IP${D}Irvine1 RT Min${D}Irvine1 RT Max${D}Irvine1 RT Avg${D}Irvine1 Pkt Loss${D}To Irvine2${D}Irvine2 IP${D}Irvine2 RT Min${D}Irvine2 RT Max${D}Irvine2 RT Avg${D}Irvine2 Pkt Loss${D}To London1${D}London1 IP${D}London1 RT Min${D}London1 RT Max${D}London1 RT Avg${D}London1 Pkt Loss${D}To London2${D}London2 IP${D}London2 RT Min${D}London2 RT Max${D}London2 RT Avg${D}London2 Pkt Loss${D}"

# get the hostname and IP of the host log generated from
THIS_HOST_NAME=`/bin/hostname`
THIS_HOST_IP=`/usr/bin/host $THIS_HOST_NAME | awk '{print $NF}'`

# list of servers to ping
# - Ashburn -
#dns01.ash01.latisys.net - 208.54.240.4
#dns02.ash01.latisys.net - 208.54.240.20
# - Chicago - 
#dns01.oak01.latisys.net - 207.223.34.212
#dns02.oak01.latisys.net - 207.223.33.4
# - Denver -
#dns01.eng01.latisys.net - 216.7.191.14
#dns02.eng01.latisys.net - 216.7.191.4
# - Irvine - 
#dns01.irv01.latisys.net - 207.38.29.4
#dns02.irv01.latisys.net - 207.38.29.5
# - London - 
#dns01.lon01.latisys.net - 209.197.231.252
#dns02.lon01.latisys.net - 209.197.231.253
SERVERS_TO_PING="
dns01.ash01.latisys.net
dns02.ash01.latisys.net
dns01.oak01.latisys.net
dns02.oak01.latisys.net
dns01.eng01.latisys.net
dns02.eng01.latisys.net
dns01.irv01.latisys.net
dns02.irv01.latisys.net
dns01.lon01.latisys.net
dns02.lon01.latisys.net
"

# make sure there is a header line in the log file or create the log file
if [ -e $LATENCY_LOG_FILE ]; then
    /usr/bin/head -1 $LATENCY_LOG_FILE | /bin/grep "$LOG_HEADER" > /dev/null
   if [ $? -ne 0 ]; then
      echo $LOG_HEADER > $LATENCY_LOG_FILE.NEW
      cat $LATENCY_LOG_FILE >> $LATENCY_LOG_FILE.NEW
      mv -f $LATENCY_LOG_FILE.NEW $LATENCY_LOG_FILE
   fi
else	# log file doesn't exist, create it
   echo $LOG_HEADER > $LATENCY_LOG_FILE
fi

# initialize the log line
DATE=`date +'%d-%b-%Y'`
TIME=`date +'%H:%M'`
output_log_line="$DATE$D$TIME$D$THIS_HOST_NAME$D$THIS_HOST_IP"

# ping the servers and log the data
for server in $SERVERS_TO_PING; do
   ping_tmp_file=`mktemp /tmp/pingresults.$server.XXXX`
   ping -c $PING_COUNT $server > $ping_tmp_file
   server_ip=`grep PING $ping_tmp_file | cut -d'(' -f2 | cut -d')' -f1`
   pkt_loss=`awk '/loss/ {print $6}' $ping_tmp_file`
   rtt_nums=`awk '/avg/ {print $4}' $ping_tmp_file`
   rtt_min=`echo "$rtt_nums" | cut -d/ -f1`
   rtt_max=`echo "$rtt_nums" | cut -d/ -f3`
   rtt_avg=`echo "$rtt_nums" | cut -d/ -f2`
   # add on to the log line
   output_log_line="$output_log_line$D$server$D$server_ip$D$rtt_min$D$rtt_max$D$rtt_avg$D$pkt_loss"
   rm -f $ping_tmp_file
done

# output the log line, append to log file
##echo "$output_log_line"		# for debugging only - get rid of for prod
echo "$output_log_line" >> $LATENCY_LOG_FILE

# EOF 
