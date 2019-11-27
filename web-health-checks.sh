#!/bin/bash
#
# description:
#   checks a list of websites for:
#    - http access
#    - https access
#    - file existance
#    - host DNS resolution
#   Displays
#    - HTTP return status codes
#    - DNS CNAME and A records

USAGE="\
$0 -f FILE [-w WEB_SITE] [-p PATH] [-h|n|s|i]
  -f FILE         File containing list of websites to check 
  -w WEB_SITE     Only check this matching website (RegEx)
  -p PATH         Check for this path/file
  -n (non-secure) Only check for HTTP
  -s (secure)     Only check for HTTPS
  -x (no DNS)     Don't show DNS resolutions
  -i              Ignore invalid SSL certs (i.e. curl -k)
  -h              Show help (this message/usage)"

function print_usage {
# show usage and exit
   echo "Usage: $USAGE"
   exit 1
}

function show_web_info {
# generate web info results
   local _proto=$1
   local _host=$2
   local _pd=$3
   local _path=$4
   uri="$_proto://$_host$_pd$_path"
   echo -ne "$uri: "
   curl_out=$(curl $ckopt -s -m 1 -I $uri)
   curl_rc=$?
   case "$curl_rc" in
      6) curl_rc_desc="Couldn't resolve host. The given remote host was not resolved" ;;
      28) curl_rc_desc="Operation timeout. Specified time-out was reached." ;;
      35) curl_rc_desc="SSL connect error. The SSL handshaking failed." ;;
      51) curl_rc_desc="Peer's SSL cert or SSH MD5 fingerprint was not OK." ;;
      60) curl_rc_desc="Peer cert can't be authenticated with known CA certs." ;;
      *) curl_rc_desc="unknown" ;;
   esac
   echo -ne "curl rc: $curl_rc - "
   if [ $curl_rc -eq 0 ]; then
      echo "$curl_out" | egrep '^HTTP|^Location' | sed 's///' | tr '\n' ',' | sed 's/,/, /;s/,$//'
   else
      echo "$curl_rc_desc"
   fi
}

function show_host_info {
# generate host (DNS) info results
   local _host=$1
   echo -ne "host: $_host - "
   host $_host | tr '\n' ',' | sed 's/is an alias for/CNAME/g;s/has address/A/g;s/,$//;s/,/, /g'
}

# set some defaults
ckopt=""
file=""
dns=1
http=1
https=1
path=""
sites=""

# parse the arguments
while getopts "h?nxsif:w:p:" opt; do
   case "$opt" in
      f) file="$OPTARG" ;;
      i) ckopt="-k" ;;
      n) https=0 ;;
      p) path="${OPTARG#/}" ;;
      s) http=0 ;;
      w) sites="$OPTARG" ;;
      x) dns=0 ;;
      h|\?) print_usage ;;
      *) print_usage ;;
   esac
done

# sanity check
[ -z "$file" ] && print_usage

# preparations
[ -n "$path" ] && pd="/" || pd=""
if [ -n "$sites" ]; then
   site_list=$(awk '{print $1}' $file | grep "$sites")
else
   site_list=$(awk '{print $1}' $file)
fi

for host in $site_list; do
   [ $http -eq 1 ] && show_web_info http $host $pd $path
   [ $https -eq 1 ] && show_web_info https $host $pd $path
   [ $dns -eq 1 ] && show_host_info $host
   [ $((http + https + dns)) -gt 1 ] && echo "~~~"
done
