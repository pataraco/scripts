#!/usr/bin/python
# 
# description: simple script to find cookbooks that are not at the same bookmark level
#

import os
import sys
import argparse
import subprocess
import shlex
import readline
import json

REPOS_DIR = os.environ['HOME'] + "/repos"
COOKBOOK_REPO = REPOS_DIR + "/cookbooks"
GRN = "\e[32m"   # green color
RED = "\e[31m"   # red color
NRM = "\e[m"     # to make text normal
MAX_COOKBOOK_NAME_LEN = 0
THIS_SCRIPT = sys.argv[0]
USAGE = """\
USAGE: %s [OPTIONS]
DESCRIPTION: checks and verifies all VIPs and FIPs are configured and working correctly
OPTIONS:
   -h   help - show this message
   -r   name/location of your repos directory
EXAMPLE:
   %s -r ~/repos""" % (THIS_SCRIPT,THIS_SCRIPT)

print "REPOS_DIR =",
print REPOS_DIR
print "COOKBOOK_REPO =",
print COOKBOOK_REPO
print "GRN =",
print GRN
print "RED =",
print RED
print "NRM =",
print NRM
print "MAX_COOKBOOK_NAME_LEN =",
print MAX_COOKBOOK_NAME_LEN
print "THIS_SCRIPT =",
print THIS_SCRIPT
print "USAGE ="
print USAGE
exit

## parse command line options
##while getopts "hr:" OPT; do
##  case ${OPT} in
##     h) echo "$USAGE"; exit 2 ;;
##     r) REPOS_DIR=$OPTARG ;;
##     ?) echo "unknown option given";  echo "$USAGE"; exit 1 ;;
##  esac
##done
##
##
### for reporting purposes - get the string length of all the coombook names
##for cookbook in `/bin/ls $COOKBOOK_REPO`; do
##   if [ -d $COOKBOOK_REPO/$cookbook ]; then
##      cookbook_name_length=`expr length $cookbook`
##      [ $MAX_COOKBOOK_NAME_LEN -lt $cookbook_name_length ] && MAX_COOKBOOK_NAME_LEN=$cookbook_name_length
##   fi
##done
##MCNL=$MAX_COOKBOOK_NAME_LEN	# use an acroynm for printf below
##
### cd to each directory (cookbook) and run the `hg bookmark` command, then grab the versions
### also display the results
##for cookbook in `/bin/ls $COOKBOOK_REPO`; do
##   if [ -d $COOKBOOK_REPO/$cookbook ]; then
##      cd $COOKBOOK_REPO/$cookbook
##      bookmarks=`hg bookmarks`
##      devtest_bookmark_level=`echo "$bookmarks"|grep devtest|awk '{print $NF}'|cut -d: -f1`
##      publictest_bookmark_level=`echo "$bookmarks"|grep publictest|awk '{print $NF}'|cut -d: -f1`
##      production_bookmark_level=`echo "$bookmarks"|grep production|awk '{print $NF}'|cut -d: -f1`
##      printf "%-${MCNL}s:  devtest (%3d)  publictest (%3d)  production (%3d)  " $cookbook $devtest_bookmark_level $publictest_bookmark_level $production_bookmark_level
##      if [ $devtest_bookmark_level -ne $publictest_bookmark_level -o $publictest_bookmark_level -ne $production_bookmark_level ]; then
##         echo -e [ ${RED}DIFF${NRM} ]
##      else
##         echo -e [ ${GRN}SAME${NRM} ]
##      fi 
##      cd - > /dev/null
##   fi
##done
