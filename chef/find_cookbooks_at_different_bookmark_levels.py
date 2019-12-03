#!/usr/bin/python
# 
# description: simple script to find cookbooks that are not at the same bookmark level
#
# TODO: this is WIP, intention was to convert this bash script into python
#       for python learning practice

import os
import sys
import argparse
import subprocess
import shlex
import readline
import json

REPOS_DIR = os.environ['HOME'] + "/repos"
COOKBOOK_REPO = REPOS_DIR + "/cookbooks"
GRN = "\033[32m"   # green color
RED = "\033[31m"   # red color
NRM = "\033[m"     # to make text normal
MAX_COOKBOOK_NAME_LEN = 0
THIS_SCRIPT = sys.argv[0]
USAGE = """\
USAGE: %s [OPTIONS]
DESCRIPTION: finds cookbooks that are at different hg bookmark levels
OPTIONS:
   -h, --help   help - show this message
   -r, --repo   name/location of your repos directory
EXAMPLE:
   %s -r ~/repos""" % (THIS_SCRIPT,THIS_SCRIPT)
VERSION = "0.0.1"

print "----------------------"
print "REPOS_DIR =",
print REPOS_DIR
print "COOKBOOK_REPO =",
print COOKBOOK_REPO
print GRN + "GRN =" + NRM,
print GRN
print RED + "RED =" + NRM,
print RED
print NRM + "NRM =",
print NRM
print "MAX_COOKBOOK_NAME_LEN =",
print MAX_COOKBOOK_NAME_LEN
print "THIS_SCRIPT =",
print THIS_SCRIPT
print "USAGE ="
print USAGE
print "----------------------"

parser = argparse.ArgumentParser(description='finds cookbooks that are at different hg bookmark levels')
parser.add_argument('-r', '--repo', default=REPOS_DIR, help='name/location of your repos directory')
parser.add_argument('--version', action='version', version='%(prog)s ' + VERSION)
args = parser.parse_args()

cookbook_repo = args.repo + "/cookbooks"

print "cookbook_repo = %s" % cookbook_repo
print "cookbook_repo = " + cookbook_repo
print("cookbook_repo = {}".format(cookbook_repo))


### for reporting purposes - get the string length of all the cookbook names
command = "/bin/ls %s" % cookbook_repo
process = subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE)
output = process.communicate()[0]
cookbooks = output

for cookbook in cookbooks:
    print cookbook

exit
#for cookbook in `/bin/ls $COOKBOOK_REPO`; do
##   if [ -d $COOKBOOK_REPO/$cookbook ]; then
##      cookbook_name_length=`expr length $cookbook`
##      [ $MAX_COOKBOOK_NAME_LEN -lt $cookbook_name_length ] && MAX_COOKBOOK_NAME_LEN=$cookbook_name_length
##   fi
##done
##MCNL=$MAX_COOKBOOK_NAME_LEN	# use an acroynm for printf below

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
