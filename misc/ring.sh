#!/bin/bash
#
# Description
#   Similar to `ping` with the addition of `nc` to test for
#   port availabiltiy - defaults to 22 (ssh)
#   checks to see:
#     - if a host is ping-able, and
#     - if a host is listening on an (ssh:22 or other) port
#       (so that you can `ssh` to it or do other things to it)
#   output resembles `ping` output
#

[ "$(uname)" == "Darwin" ] && ESC="\033" || ESC="\e"
BLD="${ESC}[1m"         # makes the colors bold/bright
RED="${ESC}[31m"        # red color
GRN="${ESC}[32m"        # green color
YLW="${ESC}[33m"        # yellow color
BLU="${ESC}[34m"        # blue color
NRM="${ESC}[m"          # turn off all color - make text normal
SSHPORT=22              # default ssh listening port
NC_CMD=$(which nc)      # find/set the `nc` command
PING_CMD=$(which ping)  # find/set the `ping` command
USE_IP=FALSE            # used to determine if user gave an IP or hostname

if [ $# -eq 2 ]; then
  server=$1
  NCPORT=$2
elif [ $# -ne 1 ]; then
  echo "usage: $(basename "$0") destination [port]"
  exit 1
else
  server=$1
  NCPORT=$SSHPORT
fi

started_at=$(date +%T)
start_hr=$((10#${started_at:0:2}))
start_mn=$((10#${started_at:3:2}))
start_sc=$((10#${started_at:6:2}))
days=0
hr_delta=0
ping_fails=0
ping_passes=0
nc_fails=0
nc_passes=0
# ctrlc=false
trap 'break' SIGINT
[[ $server =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && USE_IP="TRUE"
# host "$server" > /dev/null 2>&1   # nslookup is deprecated
# if [[ $? -eq 0 ]] || [[ $USE_IP = "TRUE" ]]; then
if host "$server" &> /dev/null || [[ $USE_IP = "TRUE" ]]; then
  if [ $USE_IP = "TRUE" ]; then
    server_name=$server
    address=$server
  else
    server_name=$(host "$server"|head -1|awk '{print $1}')  # nslookup is deprecated
    address=$(host "$server"|tail -1|awk '{print $NF}')     # nslookup is deprecated
  fi
  case $NCPORT in
      20) nc_proto=ftp;;
      22) nc_proto=ssh;;
      23) nc_proto=telnet;;
      25) nc_proto=smtp;;
      80) nc_proto=http;;
     443) nc_proto=https;;
    3306) nc_proto=mysql;;
    5432) nc_proto=postgres;;
    6379) nc_proto=redis;;
       *) nc_proto=nc;;
  esac
  echo -ne "${BLD}RING $server_name ($address) ping and $nc_proto (port:$NCPORT)${NRM}"
  while true; do
    if [ $USE_IP = "TRUE" ]; then
      server_name=$server
      address=$server
    else
      server_name=$(host "$server"|head -1|awk '{print $1}')
      address=$(host "$server"|tail -1|awk '{print $NF}')
    fi
    if [ "$(uname -s)" == "Darwin" ]; then
      $PING_CMD -W 1 -c 1 "$server" > /dev/null 2>&1
    else
      $PING_CMD -w 1 -c 1 "$server" > /dev/null 2>&1
    fi
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        PING=TRUE
        ping="${BLD}${GRN}PASS${NRM}"
        # pingp="PASS"
        (( ping_passes++ ))
    else
      PING=FALSE
      ping="${BLD}${RED}FAIL${NRM}"
      # pingp="FAIL"
      (( ping_fails++ ))
    fi
    if [ "$(uname -s)" == "Darwin" ]; then
      $NC_CMD -G 1 -z "$server" "$NCPORT" > /dev/null 2>&1
    else
      $NC_CMD -w 1 -z "$server" "$NCPORT" > /dev/null 2>&1
    fi
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
      NC=TRUE
      nc="${BLD}${GRN}PASS${NRM}"
      # ncp="PASS"
      (( nc_passes++ ))
    else
      NC=FALSE
      nc="${BLD}${RED}FAIL${NRM}"
      # ncp="FAIL"
      (( nc_fails++ ))
    fi
    if [[ $PING == "TRUE" ]] && [[ $NC = "TRUE" ]]; then
      THC=$GRN
      if [ "$state" != "ALLPASS" ]; then
        echo
        started_at=$(date +%T)
        start_hr=$((10#${started_at:0:2}))
        start_mn=$((10#${started_at:3:2}))
        start_sc=$((10#${started_at:6:2}))
      fi
      state=ALLPASS
    elif [[ $PING == "FALSE" ]] && [[ $NC = "FALSE" ]]; then
      THC=$RED
      if [ "$state" != "ALLFAIL" ]; then
        echo
        started_at=$(date +%T)
        start_hr=$((10#${started_at:0:2}))
        start_mn=$((10#${started_at:3:2}))
        start_sc=$((10#${started_at:6:2}))
      fi
      state=ALLFAIL
    else
      THC=$YLW
      if [ "$state" != "MIXED" ]; then
        echo
        started_at=$(date +%T)
        start_hr=$((10#${started_at:0:2}))
        start_mn=$((10#${started_at:3:2}))
        start_sc=$((10#${started_at:6:2}))
      fi
      state=MIXED
    fi
    cur_time=$(date +%T)
    cur_hr=$((10#${cur_time:0:2}))
    cur_mn=$((10#${cur_time:3:2}))
    cur_sc=$((10#${cur_time:6:2}))
    if [ $cur_sc -lt $start_sc ]; then             # adjust
      (( cur_mn -= 1 ))
      (( cur_sc += 60 ))
    fi
    if [ $cur_mn -lt $start_mn ]; then             # adjust
      (( cur_hr -= 1 ))
      (( cur_mn += 60 ))
    fi
    if [[ $hr_delta -ne 0 ]] && [[ $cur_hr -le $start_hr ]]; then             # adjust
      hr_delta=$(( 24 - start_hr + cur_hr + (days * 24) ))
    else
      hr_delta=$(( cur_hr - start_hr + (days * 24) ))
    fi
    [[ $hr_delta -ne 0 ]] && [[ $((hr_delta%24)) -eq 0 ]] && (( days += 1 ))
    mn_delta=$(( cur_mn - start_mn ))
    sc_delta=$(( cur_sc - start_sc ))
    duration=$(printf "%02dh%02d'%02d\"" $hr_delta $mn_delta $sc_delta)
    echo -ne "\r${THC}$server_name ($address) ${BLU}ping${NRM} [$ping] ${BLU}$nc_proto${NRM} [$nc] $duration"
    # both the `ping` and `nc` commands wait for a second each, so taking out the `sleep`
    #sleep 1 > /dev/null 2>&1 &
    #wait > /dev/null 2>&1
  done
  echo -e "\n--- $server_name ring statistics ---"
  ping_total=$(( ping_passes + ping_fails ))
  ping_per=$(( ping_passes * 100 / ping_total ))
  nc_total=$(( nc_passes + nc_fails ))
  nc_per=$(( nc_passes * 100 / nc_total ))
  printf "%4d pings transmitted, %4d received, %3d%% success\n" $ping_total $ping_passes $ping_per
  printf "%4d  nc's transmitted, %4d received, %3d%% success\n" $nc_total $nc_passes $nc_per
  echo -ne "\033]0;$(whoami)@$(hostname)\007"
else
  echo "$(basename "$0"): unknown host $server"
fi
