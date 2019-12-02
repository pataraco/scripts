#!/bin/bash
#
# Company: Red 5 Studios
# Discription: Used to apply game server hotfixes
#  - updates the affected game servers
#
# Requirements: must have following to run this script
#  - packages - knife
#  - hotfixes - hotfix files need to be downloaded/accessible
#
# Assumptions: the following assumptions are being made
#  - game server names have the build number in their name
#
# ToDo: The following improvements need/should be made
#  - want to add/display default file locations
#  - add code to ask for information required instead of exiting
#
# Updates:
#  16-jul-2015 - initial build
#

# set some GLOBALs
ROLE_DIR=$REPO_DIR/roles
CB_DIR=$REPO_DIR/cookbooks
BLD="\e[1m"             # makes colors bold/bright
RED="\e[31m"            # red color
GRN="\e[32m"            # green color
YLW="\e[33m"            # yellow color
BLU="\e[34m"            # blue color
NRM="\e[m"              # to make text normal
THIS_SCRIPT=`basename $0`
LOGFILE=/tmp/$THIS_SCRIPT.log
PROCMOND_SERVICE=procmond
DEBUG=FALSE
DRY_RUN=FALSE
BINFILES=FALSE
R5_EXEC_UID=6000
CHUNKFILES=FALSE
STATICDBFILES=FALSE
USAGE="\
USAGE: $THIS_SCRIPT [OPTIONS]
DESCRIPTION: applies hotfixes to game servers
OPTIONS:
   -b   build number
   -c   location of knife file to use
   -d   turn on debugging
   -f   name of hotfix directory containing hotfix files
   -h   help - show this message
   -n   dry-run - do not install hotfix files
   -r   location of repo containing encription keys
EXAMPLE:
   $THIS_SCRIPT -c ~/repos/.chef/knife.rb -f /data/1298-hotfix -r ~/repos -b 1298\
"
FILES_NOT_NEEDED="bin/*.symbols staticdb/sqlcache.dat"
DIRS_NOT_NEEDED="sdb_backup"
FILES_TO_ENCRYPT="staticdb/*.sd2"
FILES_TO_DECRYPT="bin/*.r5e"
DATA_DIRS="ai_states arcs assetdb assets encounters missions raia_navigation staticdb zones32 zones64"
ROOT_DIRS="bin config etc"
BOTH_DIRS="certificates"
CHNK_DIRS="chunks32 chunks64"
RMT_HOTFIX_DIR="/tmp/hotfixes"
RMT_R5DATA_DIR="/r5"
RMT_CHUNKS_DIR="/mnt"
CLIENT_CERTS_DIR="client_certificates"
KNIFECMD=`which knife`

usage() {
   echo "$USAGE"
}

log() {
   echo -e "$*" >> $LOGFILE
}

info() {
   echo -e "info: $*"
   log  "info: $*"
}

debug() {
   echo -e "debug: $*"
   log  "debug: $*"
}

error() {
   echo -e "error: $*"
   log   "error: $*"
   exit 2
}

sanity_check() {
 CLIENT_CERTS_BUILDS_DIR=`echo "$REPODIR/$CLIENT_CERTS_DIR/builds/$BUILD" | sed 's://:/:g'`
 PASS_KEY="$CLIENT_CERTS_BUILDS_DIR/publictest-aes-pass.bin"

   [ -z "$BUILD" ] && error "no build number given"
   [ -z "$KNIFE_RB" ] && error "no knife file given"
   [ -z "$HOTFIXDIR" ] && error "hotfix directory not given"
   [ -z "$REPODIR" ] && error "repo directory not given"
   [ -z "$KNIFECMD" ] && error "knife required to run this script"
   # check if the hotfix directory exists and is not empty
   [ ! -d $HOTFIXDIR ] && error "hotfix dir not found or is not a directory: $HOTFIXDIR"
   [ `find $HOTFIXDIR -maxdepth 0 -empty | wc -l` -gt 0 ] &&  error "hotfix directory is empty: $HOTFIXDIR"
   [ ! -e $KNIFE_RB ] && error "knife config file not found: $KNIFE_RB"
   [ ! -d $REPODIR ] && error "repo dir not found or is not a directory: $REPODIR"
   [ `find $REPODIR -maxdepth 0 -empty | wc -l` -gt 0 ] &&  error "repo dir is empty: $REPODIR"
   if [ ! -d $CLIENT_CERTS_BUILDS_DIR ]; then
      info "client certs build dir not found: $CLIENT_CERTS_BUILDS_DIR"
      (cd $REPODIR/$CLIENT_CERTS_DIR; hg incoming >/dev/null)
      if [ $? -eq 0 ]; then
         error "the client certs repo is NOT current: $REPODIR/$CLIENT_CERTS_DIR"
      else
         error "client certs repo is current: $REPODIR/$CLIENT_CERTS_DIR"
      fi
   else
      [ $DEBUG = "TRUE" ] && debug "client certs build dir found: $CLIENT_CERTS_BUILDS_DIR"
   fi
   [ `find $CLIENT_CERTS_BUILDS_DIR -maxdepth 0 -empty | wc -l` -gt 0 ] && error "client certs build dir is empty: $CLIENT_CERTS_DIR"
   [ ! -e $PASS_KEY ] && error "passkey file not found: $PASS_KEY"
}

process_hotfix_files() {
# process the hotfix files
#  - check for and remove files and dirs not needed
#  - encript/decrypt necessary files
#  - move/copy directories into correct tree structure
#  - check for and flag if bin/chunk files need to be patched

   # remove dirs and files not needed
   info "removing unnecessary dirs and files"
   for dir2del in $DIRS_NOT_NEEDED; do
      actual_dir="$HOTFIXDIR/$dir2del"
      [ $DEBUG = "TRUE" ] && debug "looking for dir(s): $actual_dir"
      if [ -d $actual_dir ]; then
         [ $DEBUG = "TRUE" ] && debug "removing dir(s): $actual_dir"
         rm -rf $actual_dir
      else
         [ $DEBUG = "TRUE" ] && debug "dir(s) not found: $actual_dir"
      fi
   done
   for file2del in $FILES_NOT_NEEDED; do
      actual_file="$HOTFIXDIR/$file2del"
      [ $DEBUG = "TRUE" ] && debug "looking for file(s): $actual_file"
      ls $actual_file > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         [ $DEBUG = "TRUE" ] && debug "removing file(s): $actual_file"
         rm -f $actual_file
      else
         [ $DEBUG = "TRUE" ] && debug "file(s) not found: $actual_file"
      fi
   done
   # check if there are files to encrypt
   info "checking for files that need to be encrypted"
   for file_ls in $FILES_TO_ENCRYPT; do
      ls $HOTFIXDIR/$file_ls > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         [ $DEBUG = "TRUE" ] && debug "found files that need to be encrypted: $HOTFIXDIR/$file_ls"
         for file2encrypt in `ls $HOTFIXDIR/$file_ls`; do
            [ $DEBUG = "TRUE" ] && debug "encrypting file: $file2encrypt"
            openssl enc -e -in $file2encrypt -out $file2encrypt.r5e -pass file:$PASS_KEY -aes-256-cbc
            rm -f $file2encrypt
         done
      else
         [ $DEBUG = "TRUE" ] && debug "did not find file(s) to be encrypted in: $HOTFIXDIR/$file_ls"
      fi
   done
   # check if there are files to decrypt
   info "checking for files that need to be decrypted"
   for file_ls in $FILES_TO_DECRYPT; do
      ls $HOTFIXDIR/$file_ls > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         [ $DEBUG = "TRUE" ] && debug "found files that need to be decrypted: $HOTFIXDIR/$file_ls"
         for file2decrypt in `ls $HOTFIXDIR/$file_ls`; do
            [ $DEBUG = "TRUE" ] && debug "decrypting file: $file2decrypt"
            openssl enc -d -in $file2decrypt -out ${file2decrypt%.r5e} -pass file:$PASS_KEY -aes-256-cbc
            rm -f $file2decrypt
         done
      else
         [ $DEBUG = "TRUE" ] && debug "did not find file(s) to be decrypted in: $HOTFIXDIR/$file_ls"
      fi
   done
   # rearrange files into proper directory tree structure
   info "rearranging files into proper directory tree structure"
   [ ! -d $HOTFIXDIR/data ] && /bin/mkdir $HOTFIXDIR/data
   for dir_to_move in $DATA_DIRS; do
      [ -d $HOTFIXDIR/$dir_to_move -a $DEBUG = "TRUE" ] && debug "moving dir to data directory: $dir_to_move"
      [ -d $HOTFIXDIR/$dir_to_move ] && mv $HOTFIXDIR/$dir_to_move $HOTFIXDIR/data/
   done
   for dir_to_copy in $BOTH_DIRS; do
      [ -d $HOTFIXDIR/$dir_to_copy -a $DEBUG = "TRUE" ] && debug "copying dir to data directory: $dir_to_copy"
      [ -d $HOTFIXDIR/$dir_to_copy ] && cp -r $HOTFIXDIR/$dir_to_copy $HOTFIXDIR/data/
   done
   ls $HOTFIXDIR/bin/*.r5e > /dev/null 2>&1
   [ $? -eq 0 ] && BINFILES=TRUE
   ls -d $HOTFIXDIR/chunk* > /dev/null 2>&1
   [ $? -eq 0 ] && CHUNKFILES=TRUE
   /usr/bin/sudo /bin/chown -R $R5_EXEC_UID.$R5_EXEC_UID $HOTFIXDIR/*
}

tar_gzip_hotfix() {
# tar and gzip the hotfix files
   info "creating a gzipped tar file of the hotfix files"
   tar_file_name="/data/`basename $HOTFIXDIR`.tar"
   [ $DEBUG = "TRUE" ] && debug "creating tar file: $tar_file_name"
   (cd $HOTFIXDIR; tar cvf $tar_file_name * >> $LOGFILE)
   [ $? -ne 0 ] && error "tar file creation failed: $tar_file_name"
   [ $DEBUG = "TRUE" ] && debug "gzipping the tar file: $tar_file_name"
   gzip -f $tar_file_name
   [ $? -ne 0 ] && error "gzip of tar file failed: $tar_file_name"
   gzip_tar_file_name="$tar_file_name.gz"
}

generate_server_to_patch_list() {
# figure out which game servers need this hotfix
   info "generating a list of all game servers to be patched"
   info "from all servers that have the build number $BUILD in their name"
   ALL_GAME_SERVERS=`$KNIFECMD node list -c $KNIFE_RB | grep $BUILD`
   info "adding all servers that have 'mcp' in their name"
   ALL_MCP_SERVERS=`$KNIFECMD node list -c $KNIFE_RB | grep game-mcp`
   ALL_GAME_SERVERS="$ALL_GAME_SERVERS $ALL_MCP_SERVERS"
   if [ -n "$ALL_GAME_SERVERS" ]; then
      [ $DEBUG = "TRUE" ] && debug "game servers found:\n$ALL_GAME_SERVERS"
   else
      [ $DEBUG = "TRUE" ] && debug "no game servers found using: '$KNIFECMD node list -c $KNIFE_RB | grep $BUILD'"
      error "did not find any game servers"
   fi
}

copy_tgz_to_game_servers() {
# copy gzipped tarball to the games servers, unpack and install
   info "copying gzipped tar file to game servers, unpacking and then installing"
   rmt_hotfix_subdir=`basename $HOTFIXDIR`
   for game_svr in $ALL_GAME_SERVERS; do
      info "working on $game_svr"
      game_svr_ip_ary_ind=`echo $game_svr | sed 's/-/_/g'`
      game_svr_ifqdn=`$KNIFECMD node show $game_svr -a internal_fqdn -c $KNIFE_RB | awk '{print $NF}'`
      #game_svr_ip=`$KNIFECMD node show $game_svr -a ipaddress -c $KNIFE_RB | awk '{print $2}'`
      game_svr_ip=`/usr/bin/host $game_svr_ifqdn | awk '{print $NF}'`
      game_svr_ip_ary[$game_svr_ip_ary_ind]=$game_svr_ip
      nc -w 3 -z $game_svr_ip 22 > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         [ $DEBUG = "TRUE" ] && debug "nc (netcat) test to port 22 (ssh): PASSED"
         ssh $game_svr_ip "/bin/mkdir -p $RMT_HOTFIX_DIR/$rmt_hotfix_subdir" >> $LOGFILE 2>&1
         if [ $? -eq 0 ]; then
            [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"/bin/mkdir -p $RMT_HOTFIX_DIR/$rmt_hotfix_subdir\": PASSED"
            log "successfully made directory: $game_svr:$RMT_HOTFIX_DIR/$rmt_hotfix_subdir"
            scp $gzip_tar_file_name $game_svr_ip:$RMT_HOTFIX_DIR/ >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
               [ $DEBUG = "TRUE" ] && debug "scp $gzip_tar_file_name $game_svr_ip:$RMT_HOTFIX_DIR/: PASSED"
               log "successfully copied tar.gz to server: $game_svr($game_svr_ip):$RMT_HOTFIX_DIR"
               rmt_gzip_tar_file_name=`basename $gzip_tar_file_name`
               ssh $game_svr_ip "(cd $RMT_HOTFIX_DIR/$rmt_hotfix_subdir; /bin/tar xvf $RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name)" >> $LOGFILE 2>&1
               if [ $? -eq 0 ]; then
                  [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"(cd $RMT_HOTFIX_DIR/$rmt_hotfix_subdir; /bin/tar xvf $RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name)\": PASSED"
                  log "successfully unpacked tar.gz file into: $game_svr:$RMT_HOTFIX_DIR/$rmt_hotfix_subdir"
                  # use "-n" option for testing (dry-run)
                  if [ $DRY_RUN = "TRUE" ]; then
                     ssh $game_svr_ip "sudo /usr/bin/rsync -cvrlogDn --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/ $RMT_R5DATA_DIR" >> $LOGFILE 2>&1
                     if [ $? -eq 0 ]; then
                        [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogDn --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/ $RMT_R5DATA_DIR\": PASSED"
                        log "dry-run only - hotfix patches not installed into: $game_svr:$RMT_R5DATA_DIR"
                     else
                        [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogDn --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/ $RMT_R5DATA_DIR\": FAILED"
                        log "FAILED: could not perform rsync dry-run into: $game_svr:$RMT_R5DATA_DIR"
                     fi
                  else
                     ssh $game_svr_ip "sudo /usr/bin/rsync -cvrlogD --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/ $RMT_R5DATA_DIR" >> $LOGFILE
                     if [ $? -eq 0 ]; then
                        [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogD --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/ $RMT_R5DATA_DIR\": PASSED"
                        log "successfully installed hotfix patches with rsync into: $game_svr:$RMT_R5DATA_DIR"
                     else
                        [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogD --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/ $RMT_R5DATA_DIR\": FAILED"
                        log "FAILED to install hotfix patches with rsync into: $game_svr:$RMT_R5DATA_DIR"
                     fi
                  fi
               else
                  [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"(cd $RMT_HOTFIX_DIR/$rmt_hotfix_subdir; /bin/tar xvf $RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name)\": FAILED"
                  log "FAILED to unpack tar.gz file into: $game_svr:$RMT_HOTFIX_DIR/$rmt_hotfix_subdir"
               fi
            else
               [ $DEBUG = "TRUE" ] && debug "scp $gzip_tar_file_name $game_svr_ip:$RMT_HOTFIX_DIR/: FAILED"
               log "FAILED to copy tar.gz to server: $game_svr($game_svr_ip):$RMT_HOTFIX_DIR"
            fi
         else
            [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"/bin/mkdir -p $RMT_HOTFIX_DIR/$rmt_hotfix_subdir\": FAILED"
            log "FAILED to make directory: $game_svr:$RMT_HOTFIX_DIR/$rmt_hotfix_subdir"
         fi
         if [ $CHUNKFILES = "TRUE" ]; then
            [ $DEBUG = "TRUE" ] && debug "installing chunk patches with rsync into: $game_svr:$RMT_CHUNKS_DIR"
            # using "-n" option for testing
            if [ $DRY_RUN = "TRUE" ]; then
               ssh $game_svr_ip "sudo /usr/bin/rsync -cvrlogDn --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/chunks* $RMT_CHUNKS_DIR" >> $LOGFILE 2>&1
               if [ $? -eq 0 ]; then
                  [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogDn --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/chunks* $RMT_CHUNKS_DIR\": PASSED"
                  log "dry-run only - chunk patches not installed into: $game_svr:$RMT_CHUNKS_DIR"
               else
                  [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogDn --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/chunks* $RMT_CHUNKS_DIR\": FAILED"
                  [ $DEBUG = "TRUE" ] && debug "installing chunk patches with rsync into: $game_svr:$RMT_CHUNKS_DIR"
                  log "FAILED: could not perform rsync dry-run into: $game_svr:$RMT_CHUNKS_DIR"
               fi
            else
               ssh $game_svr_ip "sudo /usr/bin/rsync -cvrlogD --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/chunks* $RMT_CHUNKS_DIR" >> $LOGFILE 2>&1
               if [ $? -eq 0 ]; then
                  [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogD --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/chunks* $RMT_CHUNKS_DIR\": PASSED"
                  log "successfully installed chunk patches with rsync into: $game_svr:$RMT_CHUNKS_DIR"
               else
                  [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"sudo /usr/bin/rsync -cvrlogD --existing $RMT_HOTFIX_DIR/$rmt_hotfix_subdir/chunks* $RMT_CHUNKS_DIR\": FAILED"
                  log "FAILED to install chunk patches with rsync into: $game_svr:$RMT_CHUNKS_DIR"
               fi
            fi
         else
            [ $DEBUG = "TRUE" ] && debug "no chunk patches found"
         fi
         # not removing yet for testing/debugging purposes
         ssh $game_svr_ip "/bin/rm -rvf $RMT_HOTFIX_DIR/$rmt_hotfix_subdir; /bin/rm -vf $RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name" >> $LOGFILE 2>&1
         if [ $? -eq 0 ]; then
            [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"/bin/rm -rvf $RMT_HOTFIX_DIR/$rmt_hotfix_subdir; /bin/rm -vf $RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name\": PASSED"
            log "successfully cleaned up and removed tar.gz file: $game_svr:$RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name"
         else
            [ $DEBUG = "TRUE" ] && debug "ssh $game_svr_ip \"/bin/rm -rvf $RMT_HOTFIX_DIR/$rmt_hotfix_subdir; /bin/rm -vf $RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name\": FAILED"
            log "FAILED trying to clean up - i.e. removing tar.gz file: $game_svr($game_svr_ip):$RMT_HOTFIX_DIR/$rmt_gzip_tar_file_name"
         fi
      else
         [ $DEBUG = "TRUE" ] && debug "nc (netcat) test to port 22 (ssh): FAILED"
         log "cannot ssh to server: $game_svr"
      fi
   done
}

restart_procmond_on_game_srvs() {
# restart procmond on each game server with approval
   log "asking to restart $PROCMOND_SERVICE on the game servers to activate the hotfixes"
   log "but warning that only if players are NOT logged on"
   echo "you can restart $PROCMOND_SERVICE on the game servers to activate the hotfixes"
   echo "WARNING! ONLY do this if players are NOT logged on!"
   echo "If players are logged in, you will need to activate hotfixes manually"
   echo -n "Ready to restart $PROCMOND_SERVICE on the game servers? (\"yes\" to proceed): "
   read ans
   if [ "$ans" = "yes" ]; then
      log "user entered \"yes\" to proceed"
      info "Ok - restarting $PROCMOND_SERVICE on game servers (one by one)"
      for game_svr in $ALL_GAME_SERVERS; do
         game_svr_ip_ary_ind=`echo $game_svr | sed 's/-/_/g'`
         game_svr_ip=${game_svr_ip_ary[$game_svr_ip_ary_ind]}
         log "asking to restart $PROCMOND_SERVICE on $game_svr"
         echo -n "is '$game_svr' ready? (enter \"yes\" to restart $PROCMOND_SERVICE): "
         read ans
         if [ "$ans" = "yes" ]; then
            log "user entered \"yes\""
            info "Ok - stopping $PROCMOND_SERVICE on $game_svr"
            ssh $game_svr_ip "sudo /usr/sbin/service $PROCMOND_SERVICE stop" >> $LOGFILE 2>&1
            echo -n "now - waiting for all *.lexe processes to stop..." | tee -a $LOGFILE
            no_of_lexes=`ssh $game_svr_ip "/bin/ps -e|grep lexe" >> $LOGFILE 2>&1 | wc -l`
            while [ $no_of_lexes -gt 0 ]; do
               echo -n "." | tee -a $LOGFILE
               sleep 3
               no_of_lexes=`ssh $game_svr_ip "/bin/ps -e|grep lexe" >> $LOGFILE 2>&1 | wc -l`
            done
            echo "done" | tee -a $LOGFILE
            info "finally - restarting $PROCMOND_SERVICE on $game_svr"
            ssh $game_svr_ip "sudo /usr/sbin/service $PROCMOND_SERVICE start" >> $LOGFILE 2>&1
         else
            info "Ok - NOT restarting $PROCMOND_SERVICE on $game_svr - take care of it yourself"
         fi
      done
   else
      info "Ok - NOT restarting $PROCMOND_SERVICE on game servers - activate manually"
   fi
}

#
# MAIN
#

# get rid of old log file
rm -rf $LOGFILE

# parse command line options
while getopts "b:c:df:hnr:" OPT; do
  case ${OPT} in
     b) BUILD=$OPTARG
        [ "$DEBUG" = "TRUE" ] && debug "build set to: $BUILD"
        ;;
     c) KNIFE_RB=$OPTARG
        [ "$DEBUG" = "TRUE" ] && debug "knife.rb set to: $KNIFE_RB"
        ;;
     d) DEBUG=TRUE
        [ "$DEBUG" = "TRUE" ] && debug "debugging turned on"
        ;;
     f) HOTFIXDIR=`echo "$OPTARG" | sed 's:/$::'`
        [ "$DEBUG" = "TRUE" ] && debug "hotfix directory set to: $HOTFIXDIR"
        ;;
     h) usage; exit 1      ;;
     n) DRY_RUN=TRUE
        [ "$DEBUG" = "TRUE" ] && debug "dry-run only"
        ;;
     r) REPODIR=`echo "$OPTARG" | sed 's:/$::'`
        [ "$DEBUG" = "TRUE" ] && debug "repo directory set to: $REPODIR"
        ;;
     ?) usage; exit 1      ;;
  esac
done

sanity_check                    # perform sanity checks
process_hotfix_files            # process the hotfix files
tar_gzip_hotfix                 # tar and gzip the hotfix files
generate_server_to_patch_list   # figure out which game servers need this hotfix
copy_tgz_to_game_servers        # copy gzipped tarball to games servers, unpack & install
restart_procmond_on_game_srvs   # restart procmond on each game server with approval

info "done"
exit 0
# EOF
