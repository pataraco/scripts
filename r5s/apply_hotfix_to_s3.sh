#!/bin/bash
#
# Company: Red 5 Studios
# Discription: Used to apply game server hotfixes to the S3 content
#   - updates the affected build number
#   - regenerates and uploads the hotfix to S3 container
# 
# Requirements: must have following to run this script
#  - packages - knife, s3cmd, aws
#  - hotfixes - hotfix files need to be pre-downloaded and accessible
#
# ToDo: The following improvements need/should be made
#  - currently only working for OpenStack, need to adapt for AWS too
#  - check for enough disk space in 'working directory'
#    - after calculating size of build and hotfix(s), make sure there
#      is enough space in the working directory to perform the hotfix
#  - add option to only perform hotfix locally and not upload to object storage
#    - this will allow user to apply severa/multiple hotfixes first before actual upload
#  - add options to specify the download and/or upload container names
#
# Updates: 
#  09-sep-2015 - initial build
#

# set some DEFAULT values
DEFAULT_AWS_CONFIG=$HOME/.aws/config	# set to the location of your aws config file
DEFAULT_AWS_PROFILE=pts			# set to the profile you use for PTS in AWS
DEFAULT_REPOS_LOCATION=$HOME/repos	# set this to your repos root dir
DEFAULT_S3CMD_UPLOAD_CFG=$S3CFG         # set $S3CFG to the s3cmd config file you use to upload
DEFAULT_WORKING_DIR=/data		# used to build default HOTFIXDIR: $DEFAULT_WORKING_DIR/$BUILD-hotfix
# set some GLOBALs
REPO_DIR=$HOME/repos		# <---- set this to your repo root dir
ROLE_DIR=$REPO_DIR/roles
RED="\e[31m"            # red color
YLW="\e[33m"            # yellow color
NRM="\e[m"              # to make text normal
THIS_SCRIPT=`basename $0`
LOGFILE=/tmp/$THIS_SCRIPT.log
DEBUG=FALSE
DRY_RUN=FALSE
BINFILES=FALSE
S3CMD_FOR_DOWNLOAD=FALSE
S3_DOWNLOAD_BUCKET_NAME_TEMPLATES="firefall-prod-build-XXXX-publictest firefall-stabilization-build-XXXX-publictest"
S3_UPLOAD_BUCKET_NAME_TEMPLATES="firefall-prod-build-XXXX-production firefall-stabilization-build-XXXX-production"
R5_EXEC_UID=6000
USAGE="\
USAGE: $THIS_SCRIPT [OPTIONS]
DESCRIPTION: applies hotfixes to game build and upload to stack (OpenStack)
OPTIONS:
   -a   aws config file to use for build download (default: $DEFAULT_AWS_CONFIG)
   -b   build number (required)
   -d   turn on debugging
   -f   hotfix directory containing hotfix files (default: /data/\$BUILD-hotfix)
   -h   help - show this message
   -n   dry-run - do not install hotfix files or apply patches to S3
   -p   aws profile to use in the aws config file (default: $DEFAULT_AWS_PROFILE)
   -r   the location of your repos (default: $DEFAULT_REPOS_LOCATION)
        (specifically the directory that contains the 'client_certificates' repo)
   -s   s3cmd config file to use for upload (default: $DEFAULT_S3CMD_UPLOAD_CFG)
   -u   use s3cmd for build download instead of aws (must supply config file)
   -w   working directory (default: /data)
EXAMPLE:
   $THIS_SCRIPT -c ~/repos/.chef/knife.rb -f /data/1298-hotfix -r ~/repos -b 1298\
"
FILES_NOT_NEEDED="bin/*.symbols staticdb/sqlcache.dat"
DIRS_NOT_NEEDED="sdb_backup"
FILES_TO_DECRYPT=""
FILES_TO_ENCRYPT="bin/*.lexe staticdb/*.sd2"
MD5SUMS_TO_SAVE="bin/gss.lexe.r5e"
R5DATAGUMBALL="r5data.tar.gz"
R5DATADIR="r5data"
R5DATA_DIRS="ai_states arcs assetdb assets encounters missions staticdb"
ROOT_DIRS="bin config etc"
RMT_HOTFIX_DIR="/tmp/hotfixes"
RMT_R5DATA_DIR="/r5"
RMT_CHUNKS_DIR="/mnt"
CLIENT_CERTS_DIR="client_certificates"
S3CMD=`which s3cmd`
AWSCMD=`which aws`

# functions
usage() {
   echo "$USAGE"
}

log() {
   echo -e "$*" >> $LOGFILE
}

info() {
   echo -e "info: $*"
   log "info: $*"
}

debug() {
   [ "$DEBUG" = "TRUE" ] && echo -e "debug: $*"
   [ "$DEBUG" = "TRUE" ] && log "debug: $*"
}

error() {
   echo -e "error: $*"
   log "error: $*"
   exit 2
}

sanity_check() {
# perform a bunch of sanity checks
   [ -z "$BUILD" ] && error "no build number given" || debug "build number set to: $BUILD"
   if [ -z "$WORKING_DIR" ]; then
      WORKING_DIR=$DEFAULT_WORKING_DIR
      debug "working dir not provided, set to default: $WORKING_DIR"
   fi
   [ ! -d $WORKING_DIR ] && error "working dir NOT found (or is not a directory): $WORKING_DIR" || debug "working dir found: $WORKING_DIR"
   if [ -z "$HOTFIXDIR" ]; then
      HOTFIXDIR=$WORKING_DIR/$BUILD-hotfix
      debug "hotfix directory not provided, set to: $HOTFIXDIR"
   fi
   if [ -z "$REPOS_ROOT_DIR" ]; then
      REPOS_ROOT_DIR=$DEFAULT_REPOS_LOCATION
      debug "repos root directory not provided, set to default: $REPOS_ROOT_DIR"
   fi
   CLIENT_CERTS_BUILDS_DIR=`echo "$REPOS_ROOT_DIR/$CLIENT_CERTS_DIR/builds/$BUILD" | sed 's://:/:g'`
   debug "client certs builds dir set to: $CLIENT_CERTS_BUILDS_DIR"
   PASS_KEY="$CLIENT_CERTS_BUILDS_DIR/publictest-aes-pass.bin"
   debug "pass key set to: $PASS_KEY"
   [ -z "$S3CMD" ] && error "required command 's3cmd' NOT found!" || debug "'s3cmd' installed: $S3CMD"
   if [ "$S3CMD_FOR_DOWNLOAD" = "FALSE" ]; then
      debug "using 'aws' to download the build - not 's3cmd'"
      [ -z "$AWSCMD" ] && error "required command 'aws' NOT found!" || debug "'aws' installed: $AWSCMD"
      if [ -z "$AWS_CONFIG" ]; then
         AWS_CONFIG=$DEFAULT_AWS_CONFIG
         debug "no aws config file given, set to default: $AWS_CONFIG"
      fi
      if [ -z "$AWS_PROFILE" ]; then
         AWS_PROFILE=$DEFAULT_AWS_PROFILE
         debug "no aws profile given, set to default: $AWS_PROFILE"
      fi
      [ ! -e "$AWS_CONFIG" ] && error "aws config file NOT found: $AWS_CONFIG" || debug "aws config file found: $AWS_CONFIG"
      AWSCMD="$AWSCMD --profile $AWS_PROFILE"
   else
      [ ! -e "$S3CMD_DOWNLOAD_CONFIG" ] && error "s3cmd download config file NOT found: $S3CMD_DOWNLOAD_CONFIG" || debug "s3cmd download config file found: $S3CMD_DOWNLOAD_CONFIG"
   fi
   # find the correct download bucket name
   S3_DOWNLOAD_BUCKET=""
   for download_template in $S3_DOWNLOAD_BUCKET_NAME_TEMPLATES; do
      test_download_bucket="s3://`echo "$download_template" | sed 's/XXXX/'"$BUILD"'/'`"
      debug "determining correct download container - trying: $test_download_bucket"
      if [ "$S3CMD_FOR_DOWNLOAD" = "FALSE" ]; then
         $AWSCMD s3 ls $test_download_bucket >> $LOGFILE
      else
         $S3CMD -c $S3CMD_DOWNLOAD_CONFIG ls $test_download_bucket >> $LOGFILE
      fi
      if [ $? -eq 0 ]; then
         [ -z "$S3_DOWNLOAD_BUCKET" ] && debug "found matching S3 download container: $test_download_bucket" || error "found more than one matching S3 download container name"
         S3_DOWNLOAD_BUCKET=$test_download_bucket
      else
         debug "this S3 download container doesn't exist: $test_download_bucket"
      fi
   done
   [ -z "$S3_DOWNLOAD_BUCKET" ] && error "cannot find a correct S3 download container" || debug "S3 download container set to: $S3_DOWNLOAD_BUCKET"
   # find the correct upload bucket name
   if [ -z "$S3CMD_UPLOAD_CONFIG" ]; then
      S3CMD_UPLOAD_CONFIG=$DEFAULT_S3CMD_UPLOAD_CFG
      debug "s3cmd upload config file not given, set to default: $S3CMD_UPLOAD_CONFIG"
   fi
   S3_UPLOAD_BUCKET=""
   for upload_template in $S3_UPLOAD_BUCKET_NAME_TEMPLATES; do
      test_upload_bucket="s3://`echo "$upload_template" | sed 's/XXXX/'"$BUILD"'/'`"
      debug "determining correct upload container - trying: $test_upload_bucket"
      $S3CMD -c $S3CMD_UPLOAD_CONFIG ls $test_upload_bucket >> $LOGFILE
      if [ $? -eq 0 ]; then
         [ -z "$S3_UPLOAD_BUCKET" ] && debug "found matching S3 upload container: $test_upload_bucket" || error "found more than one matching S3 upload container name"
         S3_UPLOAD_BUCKET=$test_upload_bucket
      else
         debug "this S3 upload container doesn't exist: $test_upload_bucket"
      fi
   done
   [ -z "$S3_UPLOAD_BUCKET" ] && error "cannot find a correct S3 upload container" || debug "S3 upload container set to: $S3_UPLOAD_BUCKET"
   [ ! -d $HOTFIXDIR ] && error "hotfix dir NOT found (or is not a directory): $HOTFIXDIR" || debug "hotfix dir found: $HOTFIXDIR"
   [ `find $HOTFIXDIR -maxdepth 0 -empty | wc -l` -gt 0 ] && error "hotfix directory is empty: $HOTFIXDIR" || debug "hotfix directory is not empty: $HOTFIXDIR"
   [ ! -d $REPOS_ROOT_DIR ] && error "repos root dir NOT found (or is not a directory): $REPOS_ROOT_DIR" || debug "repos root dir found: $REPOS_ROOT_DIR"
   [ `find $REPOS_ROOT_DIR -maxdepth 0 -empty | wc -l` -gt 0 ] && error "repos root dir is empty: $REPOS_ROOT_DIR"|| debug "repos root dir is not empty: $REPOS_ROOT_DIR"
   if [ ! -d $CLIENT_CERTS_BUILDS_DIR ]; then
      info "client certs build dir NOT found (or is not a directory): $CLIENT_CERTS_BUILDS_DIR"
      (cd $REPOS_ROOT_DIR/$CLIENT_CERTS_DIR; hg incoming >/dev/null)
      if [ $? -eq 0 ]; then
         error "the client certs repo is NOT current: $REPOS_ROOT_DIR/$CLIENT_CERTS_DIR"
      else
         error "client certs repo is current and build NOT found: $REPOS_ROOT_DIR/$CLIENT_CERTS_DIR"
      fi
   else
      debug "client certs build dir found: $CLIENT_CERTS_BUILDS_DIR"
   fi
   [ ! -e "$S3CMD_UPLOAD_CONFIG" ] && error "s3cmd upload config file NOT found: $S3CMD_UPLOAD_CONFIG" || debug "s3cmd upload config file found: $S3CMD_UPLOAD_CONFIG"
   [ `find $CLIENT_CERTS_BUILDS_DIR -maxdepth 0 -empty | wc -l` -gt 0 ] && error "client certs build dir is empty: $CLIENT_CERTS_BUILDS_DIR" || debug "client certs build dir is not empty: $CLIENT_CERTS_BUILDS_DIR"
   [ ! -e "$PASS_KEY" ] && error "passkey file NOT found: $PASS_KEY" || debug "passkey file found: $PASS_KEY"
}

process_hotfix_files() {
# process the hotfix files
#  - check for and remove files and dirs not needed
#  - encript/decrypt necessary files
#  - move/copy directories into correct tree structure
#  - check for and flag if bin/chunk files need to be patched

   # remove dirs and files not needed
   info "removing unnecessary dirs and files from hotfix"
   for dir2del in $DIRS_NOT_NEEDED; do
      actual_dir="$HOTFIXDIR/$dir2del"
      debug "looking for dir: $actual_dir"
      if [ -d $actual_dir ]; then
         debug "found and removing dir: $actual_dir"
         rm -rvf $actual_dir >> $LOGFILE && debug "successfully removed file: $actual_dir" || error "could not remove dir: $actual_dir"
      else
         debug "dir not found: $actual_dir"
      fi
   done
   for file2del in $FILES_NOT_NEEDED; do
      actual_file="$HOTFIXDIR/$file2del"
      debug "looking for file(s): $actual_file"
      ls $actual_file >> $LOGFILE 2>&1
      if [ $? -eq 0 ]; then
         debug "removing file(s): $actual_file"
         rm -vf $actual_file >> $LOGFILE && debug "successfully removed file: $actual_file" || error "could not remove file(s): $actual_file"
      else
         debug "file(s) not found: $actual_file"
      fi
   done
   # check if there are files to encrypt
   info "checking for files that need to be encrypted"
   for file_ls in $FILES_TO_ENCRYPT; do
      ls $HOTFIXDIR/$file_ls >> $LOGFILE 2>&1
      if [ $? -eq 0 ]; then
         debug "found files that need to be encrypted: $HOTFIXDIR/$file_ls"
         for file2encrypt in `ls $HOTFIXDIR/$file_ls`; do
            debug "encrypting file: $file2encrypt"
            openssl enc -e -in $file2encrypt -out $file2encrypt.r5e -pass file:$PASS_KEY -aes-256-cbc >> $LOGFILE && debug "successfully encrypted file: $file2encrypt" || error "could not encrypt file: $file2encrypt"
            rm -vf $file2encrypt >> $LOGFILE 2>&1 && debug "successfully removed file: $file2encrypt" || error "could not remove file: $file2encrypt"
         done
      else
         debug "did not find file(s) to be encrypted in: $HOTFIXDIR/$file_ls"
      fi
   done
   # check if there are files to decrypt
   info "checking for files that need to be decrypted"
   for file_ls in $FILES_TO_DECRYPT; do
      ls $HOTFIXDIR/$file_ls >> $LOGFILE 2>&1
      if [ $? -eq 0 ]; then
         debug "found files that need to be decrypted: $HOTFIXDIR/$file_ls"
         for file2decrypt in `ls $HOTFIXDIR/$file_ls`; do
            debug "decrypting file: $file2decrypt"
            openssl enc -d -in $file2decrypt -out ${file2decrypt%.r5e} -pass file:$PASS_KEY -aes-256-cbc >> $LOGFILE && debug "successfully decrypted file: $file2decrypt" || error "could not decrypt file: $file2decrypt"
            rm -vf $file2decrypt >> $LOGFILE 2>&1 && debug "successfully removed file: $file2decrypt" || error "could not remove file: $file2decrypt"
         done
      else
         debug "did not find file(s) to be decrypted in: $HOTFIXDIR/$file_ls"
      fi
   done
   # generate the md5sum of files
   info "checking for files that need md5 checksums saved"
   for file_2md5 in $MD5SUMS_TO_SAVE; do
      ls $HOTFIXDIR/$file_2md5 >> $LOGFILE 2>&1
      if [ $? -eq 0 ]; then
         debug "found files that need their md5 checksums saved: $HOTFIXDIR/$file_2md5"
         for file2md5sum in `ls $HOTFIXDIR/$file_2md5`; do
            debug "generating/saving md5sum for file: $file2md5sum"
            cd `dirname $file2md5sum` >> $LOGFILE && debug "cd succeeded to: `dirname $file2md5sum`" || error "could NOT cd to: `dirname $file2md5sum`"
            md5sum `basename $file2md5sum` > `basename $file2md5sum`.md5sum && debug "successfully generated/saved md5sum for file: `basename $file2md5sum`" || error "could not generate/save md5sum for file: `basename $file2md5sum`"
            cd - >> $LOGFILE 2>&1 && debug "cd back to original location succeeded" || error "could not cd back up to $HOTFIXDIR"
         done
      else
         debug "did not find file(s) that need their md5 checksums saved: $HOTFIXDIR/$file_2md5"
      fi
   done
   # rearrange files into proper directory tree structure
   info "rearranging files into proper directory tree structure"
   if [ ! -d $HOTFIXDIR/$R5DATADIR ]; then
      /bin/mkdir $HOTFIXDIR/$R5DATADIR && debug "successfully made dir: $HOTFIXDIR/$R5DATADIR" || error "could not make dir: $HOTFIXDIR/$R5DATADIR"
   else
      debug "directory already exists: $HOTFIXDIR/$R5DATADIR"
   fi
   for dir_to_move in $R5DATA_DIRS; do
      if [ -d $HOTFIXDIR/$dir_to_move ]; then
         debug "moving dir to $R5DATADIR directory: $dir_to_move"
         mv $HOTFIXDIR/$dir_to_move $HOTFIXDIR/$R5DATADIR/ && debug "successfully moved dir to $R5DATADIR: $dir_to_move" || error "could NOT move dir to $R5DATADIR: $dir_to_move"
      else
         debug "did not find dir in hotfix: $dir_to_move"
      fi
   done
}

download_game_build() {
   # make a directory to download the current build into
   download_dir=$WORKING_DIR/$BUILD-download
   if [ -d $download_dir ]; then
      debug "download dir already exists: $download_dir"
   else
      debug "creating download dir - does not exist: $download_dir"
      /bin/mkdir $download_dir && debug "successfully made download dir: $download_dir" || error "could not make download dir: $download_dir"
   fi
   if [ "$S3CMD_FOR_DOWNLOAD" = "FALSE" ]; then
      info "downloading the game server build files using 'aws' (be patient)"
      info "  you can 'tail -f $LOGFILE' to watch progress"
      debug "downloading the game server build using following 'aws' command:"
      debug "  '$AWSCMD s3 sync $S3_DOWNLOAD_BUCKET $download_dir'"
      $AWSCMD s3 sync $S3_DOWNLOAD_BUCKET $download_dir >> $LOGFILE
      [ $? -ne 0 ] && error "command failed: '$AWSCMD s3 sync $S3_DOWNLOAD_BUCKET $download_dir'" || debug "'aws s3 sync' completed successfully"
   else
      info "downloading the game server build files using 's3cmd' (be patient)"
      info "  you can 'tail -f $LOGFILE' to watch progress"
      debug "downloading the game server build using following 's3cmd' command:"
      debug "  '$S3CMD -c $S3CMD_DOWNLOAD_CONFIG sync $S3_DOWNLOAD_BUCKET $download_dir/'"
      $S3CMD -c $S3CMD_DOWNLOAD_CONFIG sync $S3_DOWNLOAD_BUCKET $download_dir/ >> $LOGFILE
      [ $? -ne 0 ] && error "command failed: '$S3CMD -c $S3CMD_DOWNLOAD_CONFIG sync $S3_DOWNLOAD_BUCKET $download_dir/'" || debug "'s3cmd sync' completed successfully"
   fi
}

prepare_upload_directory() {
   # Make a "server build upload" directory
   upload_dir=$WORKING_DIR/$BUILD-upload
   if [ -d $upload_dir ]; then
      debug "upload dir already exists: $upload_dir"
      my_uid=`id -u`
      my_gid=`id -g`
      info "going to change user and group ownership to $my_uid:$my_gid of files in: $upload_dir"
      sudo chown -R $my_uid:$my_gid $upload_dir
      debug "changed user and group ownership to $my_uid:$my_gid of files in: $upload_dir"
   else
      debug "creating upload dir - does not exist: $upload_dir"
      /bin/mkdir $upload_dir && debug "successfully made upload dir: $upload_dir" || error "could NOT make upload dir: $upload_dir"
   fi
   # Copy the downloaded build files into it
   cd $WORKING_DIR >> $LOGFILE && debug "cd into dir succeeded: $WORKING_DIR" || error "could not cd to working dir: $WORKING_DIR"
   info "copying the downloaded build files into the upload directory (be patient)"
   info "  you can 'tail -f $LOGFILE' to watch progress"
   rsync -acv $download_dir/ $upload_dir/ >> $LOGFILE && debug "rsync $download_dir with $upload_dir succeeded" || error "could not rsync $download_dir with $upload_dir"
   # Unpack and remove the $R5DATADIR gumball file ($R5DATAGUMBALL) and it's md5sum file
   cd $upload_dir >> $LOGFILE && debug "cd into dir succeeded: $upload_dir" || error "could not cd into dir: $upload_dir"
   # Unpack the $R5DATADIR gumball file $R5DATAGUMBALL
   # make an $R5DATADIR directory if it doesn't already exist
   if [ ! -d $R5DATADIR ]; then
      /bin/mkdir $R5DATADIR && debug "successfully made dir: $upload_dir/$R5DATADIR" || error "could not make dir $upload_dir/$R5DATADIR"
   else
      debug "directory already exists: $upload_dir/$R5DATADIR"
   fi
   # cd to there
   cd $R5DATADIR >> $LOGFILE && debug "cd into dir succeeded: $upload_dir/$R5DATADIR" || error "could not cd into dir: $upload_dir/$R5DATADIR"
   # extract the $R5DATADIR gumball
   info "unpacking the $R5DATAGUMBALL file (be patient)"
   info "  you can 'tail -f $LOGFILE' to watch progress"
   tar xvf ../$R5DATAGUMBALL >> $LOGFILE && debug "unpack of $R5DATAGUMBALL succeeded" || error "could not unpack $R5DATAGUMBALL successfully"
   # cd back up one directory
   cd .. >> $LOGFILE && debug "cd into dir succeeded: $upload_dir" || error "could not cd into dir: $upload_dir"
   # remove the $R5DATADIR tarball related stuff
   rm -vf $R5DATAGUMBALL $R5DATAGUMBALL.md5sum >> $LOGFILE && debug "successfully removed files: $R5DATAGUMBALL $R5DATAGUMBALL.md5sum" || error "could not remove files: $R5DATAGUMBALL $R5DATAGUMBALL.md5sum"
}

apply_hotfix_patches_to_upload_dir() {
   # copy/apply the hotfix to the files in the upload directory
   # cd to the working directory
   cd $WORKING_DIR >> $LOGFILE && debug "cd into dir succeeded: $WORKING_DIR" || error "cannot cd to working dir: $WORKING_DIR"
   log "dir listing of `pwd`"
   ls >> $LOGFILE
   info "applying hotfix patches to files in the upload dir: $upload_dir"
   # sync/copy/apply the hotfix files/patches
   if [ "$DRY_RUN" = "TRUE" ]; then
      # perform a dry run (rsync's "-n" option) - to see what files are going to change
      info "DRY-RUN: performing a dry-run only - not patching files (see logfile: $LOGFILE)"
      info "         to perform hotfix and patch files - run again w/o '-n' option"
      rsync -acvn $HOTFIXDIR/ $upload_dir/ >> $LOGFILE && debug "successfully generated dry-run with rsync" || error "could not perform dry-run with rsync"
   else
      # run for real
      rsync -acv $HOTFIXDIR/ $upload_dir/ >> $LOGFILE && debug "successfully applied patches with rsync" || error "could not apply patches with rsync"
   fi
   # change user/group ownership to $R5_EXEC_UID
   info "changing user and group ownership of all files to $R5_EXEC_UID"
   sudo chown -R $R5_EXEC_UID:$R5_EXEC_UID $upload_dir/*
}

repack_r5data_gumball_file() {
# recreate the r5data.tar.gz file and it's md5 checksum
   info "repacking the $R5DATADIR gumball file: $R5DATAGUMBALL (be patient)"
   info "  you can 'tail -f $LOGFILE' to watch progress"
   # get into the upload r5data dir
   cd $upload_dir/$R5DATADIR >> $LOGFILE && debug "cd into dir succeeded: $upload_dir/$R5DATADIR" || error "could not cd to: $upload_dir/$R5DATADIR"
   # recreate the $R5DATADIR tarball: $R5DATAGUMBALL
   tar cvf ../$R5DATADIR.tar . >> $LOGFILE && debug "successfully created tar file: $upload_dir/$R5DATADIR.tar" || error "could not create tar file: $upload_dir/$R5DATADIR.tar"
   # cd up one dir
   cd .. >> $LOGFILE && debug "cd into dir succeeded: $upload_dir" || error "could not cd into dir: $upload_dir"
   # compress the tarball, create the gumball: r5data.tar.gz
   gzip $R5DATADIR.tar && debug "successfully compressed file with gzip: $R5DATADIR.tar" || error "could not gzip the file: $R5DATADIR.tar"
   # generate and save the gumball md5sum file: r5data.tar.gz.md5sum
   md5sum $R5DATAGUMBALL > $R5DATAGUMBALL.md5sum && debug "successfully generated/saved md5sum of file: $R5DATAGUMBALL" || error "could not generate/save md5sum of $R5DATAGUMBALL"
   # remove the $R5DATADIR dir and files
   sudo rm -rvf $R5DATADIR >> $LOGFILE && debug "successfully removed dir: $R5DATADIR" || error "could not remove dir: $R5DATADIR"
}

upload_patched_game_server_build_to_s3() {
   info "uploading the patched game server build files to S3 (be patient)"
   info "  you can 'tail -f $LOGFILE' to watch progress"
   # I like to compare the dirs/files of the upload directory with the download directory
   # the tree structure and filenames should match before the upload is performed
   cd $WORKING_DIR >> $LOGFILE && debug "cd into dir succeeded: $WORKING_DIR" || error "could not cd to working dir: $WORKING_DIR"
   log "directory tree structure of build download dir"
   ls -l $download_dir >> $LOGFILE
   log "directory tree structure of build upload dir"
   ls -l $upload_dir >> $LOGFILE
   # perform the upload with "sync" option - reduces upload time by uploading only what changed
   if [ "$DRY_RUN" = "TRUE" ]; then
      # perform a dry run (s3cmd's "-n" option) - to see what files are going to change
      info "DRY-RUN: performing a dry-run only - not uploading files (see logfile: $LOGFILE)"
      info "         to perform upload and patch files - run again w/o '-n' option"
      debug "using following 's3cmd' command:"
      debug "  '$S3CMD -c $S3CMD_UPLOAD_CONFIG -n sync $upload_dir/ $S3_UPLOAD_BUCKET'"
      $S3CMD -c $S3CMD_UPLOAD_CONFIG -n sync $upload_dir/ $S3_UPLOAD_BUCKET >> $LOGFILE 2>&1
      [ $? -ne 0 ] && error "command failed: '$S3CMD -c $S3CMD_UPLOAD_CONFIG -n sync $upload_dir/ $S3_UPLOAD_BUCKET'" || debug "'s3cmd sync' dry-run completed successfully"
   else
      # run for real
      debug "uploading using following 's3cmd' command:"
      debug "  '$S3CMD -c $S3CMD_UPLOAD_CONFIG sync $upload_dir/ $S3_UPLOAD_BUCKET'"
      $S3CMD -c $S3CMD_UPLOAD_CONFIG sync $upload_dir/ $S3_UPLOAD_BUCKET >> $LOGFILE 2>&1
      [ $? -ne 0 ] && error "command failed: '$S3CMD -c $S3CMD_UPLOAD_CONFIG sync $upload_dir/ $S3_UPLOAD_BUCKET'" || debug "'s3cmd sync' completed successfully"
   fi
}

#
# MAIN
#

# save location of cwd
original_wd=`pwd`
# get rid of old log file
rm -rf $LOGFILE

# parse command line options
while getopts "a:b:df:hnp:r:s:u:" OPT; do
   case ${OPT} in
      a) AWS_CONFIG=$OPTARG
        debug "aws config file set to: $AWS_CONFIG"
        ;;
      b) BUILD=$OPTARG
        debug "build option provided"
        ;;
      d) DEBUG=TRUE
        debug "debugging turned on"
        ;;
      f) HOTFIXDIR=`echo "$OPTARG" | sed 's:/$::'`
        debug "hotfix directory set to: $HOTFIXDIR"
        ;;
      h) usage; exit 1 ;;
      n) DRY_RUN=TRUE
        debug "performing a dry-run only"
        ;;
      p) AWS_PROFILE=$OPTARG
        debug "aws profile set to: $AWS_PROFILE"
        ;;
      r) REPOS_ROOT_DIR=`echo "$OPTARG" | sed 's:/$::'`
        debug "repos root directory set to: $REPOS_ROOT_DIR"
        ;;
      s) S3CMD_UPLOAD_CONFIG=$OPTARG
        debug "s3cmd upload config file set to: $S3CMD_UPLOAD_CONFIG"
        ;;
      u) S3CMD_DOWNLOAD_CONFIG=$OPTARG
        S3CMD_FOR_DOWNLOAD=TRUE
        debug "using 's3cmd' to download the build - not 'aws'"
        debug "s3cmd download config file set to: $S3CMD_DOWNLOAD_CONFIG"
        ;;
      w) WORKING_DIR=$OPTARG
        debug "working dir set to: $WORKING_DIR"
        ;;
      ?) usage; exit 1 ;;
   esac
done

sanity_check				# perform sanity checks
process_hotfix_files			# process the hotfix files
download_game_build			# get the game server build files
prepare_upload_directory		# copy the download and unpack gumball
apply_hotfix_patches_to_upload_dir	# apply the hotfix patches to files to be uploaded
repack_r5data_gumball_file		# repack the r5data gumball file
upload_patched_game_server_build_to_s3	# upload the patched files to S3

cd $original_wd >> $LOGFILE
info "done"
exit 0
# EOF

