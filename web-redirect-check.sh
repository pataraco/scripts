#!/bin/bash
#
# description:
#   checks an URL for:
#    - 3XX redirects
#   Displays
#    - Redirections
#    - HTTP return status codes

USAGE="\
$0 URL
  URL     URL to check for redirects"

function print_usage {
# show usage and exit
   echo "Usage: $USAGE"
   exit 1
}

# set global vars
URL=$1

# set defaults
http_return_code=0

# sanity check
[ -z "$URL" ] && print_usage

while [ $http_return_code -lt 200 -o $http_return_code -gt 299 ]; do
   curl_output=$(curl -I -s $URL)  # curl outputs ^M chars - WTF!
   curl_exit_status=$?
   [ $curl_exit_status -ne 0 ] && { echo "curl cannot get headers for URL: $URL"; exit $curl_exit_status; }
   http_return_code=$(grep "^HTTP" <<< "$curl_output" | awk '{print $2}')
   location_redirect=$(grep "^[Ll]ocation" <<< "$curl_output" | awk '{print $2}' | sed 's///g')
   if [ $http_return_code -gt 299 -a $http_return_code -lt 400 ]; then
      printf '%-45s  (%d) --> %s\n' $URL $http_return_code $location_redirect
      URL=$location_redirect
   elif [ $http_return_code -lt 200 -o $http_return_code -gt 399 ]; then
      printf '%-45s  (%d) error or not found\n' $URL $http_return_code
   else
      printf '%-45s  (%d) is not redirected\n' $URL $http_return_code
   fi
done
