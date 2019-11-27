#!/bin/bash
#
# description:
#   copies files from one directory to another
#   - if the file does not exist in the dest directory, just copy the file
#   - if the file does exist in the dest directory, show a diff and ask
#
#   does not traverse sub dirs
#
# description:
#   uses `colordiff` for pretty colors
#
# todo:
#   - add option to traverse sub dirs

USAGE="\
$0 [-drh] SRC_DIR DST_DIR
  -d        Dry Run - perform a dry-run, including diffs
  -r        Recursive - traverse sub directories (not available yet)
  -h        Help - show this message
  SRC_DIR   Source directory to copy files from
  DST_DIR   Destination directory to copy files to"
CLR_DFF="$(which colordiff)"

function print_usage {
   # show usage and exit
   echo "Usage: $USAGE"
   exit 1
}

function get_confirmation {
   # get confirmation to replace the existing file in dest dir
   local _dst_file=$1
   read -p "confirm  : do you want to replace $_dst_file [y/n]? " ans
   [[ "$ans" == [yY] ]] && return 1 || return 0
}

function get_diffs {
   # show diff of source and dest files
   local _file=$1
   local _dstd=$2
   $CLR_DFF -q $_dstd $_file > /dev/null
   if [ $? -eq 1 ]; then
      read -p "exists   : $file (differs) - hit [return] to see details... " junk
      $CLR_DFF -u $_dstd $_file | less -FrX
      return 1
   else
      return 0
   fi
}

# set some defaults
dry_run=0

# parse the arguments
while getopts "dhr" opt; do
   case "$opt" in
      d) echo "Performing a dry run"; dry_run=1 ;;
      h) print_usage ;;
      r) echo "Sorry, the recursive option is not available yet"; print_usage ;;
      *) print_usage ;;
   esac
done
# shift to get remaining arguments
shift $(($OPTIND - 1))

# get the dirs
SRC_DIR=${1%/}
DST_DIR=${2%/}

# sanity checks
[ -z "$CLR_DFF" ] && echo "error: colordiff required for this script"
[ -z "$SRC_DIR" -o -z "$DST_DIR" ] && { echo "error: missing source/dest dir(s)"; print_usage; }
[ ! -d "$SRC_DIR" ] && { echo "error: source ($SRC_DIR) is not a dir"; print_usage; }
[ ! -d "$DST_DIR" ] && { echo "error: destination ($SRC_DIR) is not a dir"; print_usage; }

# preparations
SRC_FILES=$(/bin/ls -d $SRC_DIR/*)

# process the files
for src_file_full_path in $SRC_FILES; do
   if [ ! -d $src_file_full_path ]; then
      file=$(basename $src_file_full_path)
      dst_file_full_path=$DST_DIR/$file
      if [ -e $dst_file_full_path ]; then
         get_diffs $src_file_full_path $dst_file_full_path
         if [ $? -eq 1 ]; then
            echo -n "source   : "
            ls -l $src_file_full_path
            echo -n "dest     : "
            ls -l $dst_file_full_path
            get_confirmation $dst_file_full_path
            if [ $? -eq 1 ]; then
               if [ $dry_run -eq 0 ]; then
                  echo "replacing: $file (differs) - replacing $DST_DIR with $SRC_DIR"
                  /bin/cp -f $src_file_full_path $DST_DIR
               else
                  echo "dry-run  : $file (differs) - NOT replacing $DST_DIR with $SRC_DIR"
               fi
            else
               echo "keeping  : $file (differs) - but NOT replacing $DST_DIR with $SRC_DIR"
            fi
         else
            echo "exists   : $file (identical) - NOT copying from $SRC_DIR to $DST_DIR"
         fi
      else
         if [ $dry_run -eq 0 ]; then
            echo "copying  : $file (new) - copying from $SRC_DIR to $DST_DIR"
            /bin/cp $src_file_full_path $DST_DIR
         else
            echo "dry-run  : $file (new) - NOT copying from $SRC_DIR to $DST_DIR"
         fi
      fi
   else
      echo "directory: $src_file_full_path - not copying to $DST_DIR"
   fi
done
