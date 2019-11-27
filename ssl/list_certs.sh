#!/bin/bash

# description: lists all the info in a SSL crt bundle

USAGE="
usage:
   list_certs.sh [-h] [cert_file] [openssl_options]
      -h              show usage (this info)
      cert_file       (arg 1) - name of cert file to display info of
                      (optional - otherwise use all *.crt files in CWD)
      openssl_options (arg 2) - openssl options
                      (e.g. -subject|dates|text|serial|pubkey|modulus
                            -purpose|fingerprint|alias|hash|issuer_hash)
                      (default: -subject -dates -issuer
                       and always uses: -noout)
"

function listcrts {
   # list all info in a crt bundle
   local _DEFAULT_OPENSSL_OPTS="-subject -dates -issuer"
   local _cbs _cb
   local _cert_bundle=$1
   if [ "${_cert_bundle: -3}" == "crt" ]; then
      shift
   else
      unset _cert_bundle
   fi
   local _openssl_opts=$*
   echo "$_openssl_opts" | grep -q '+[a-z].*'
   if [ $? -eq 0 ]; then
      _openssl_opts="$_DEFAULT_OPENSSL_OPTS $(echo "$_openssl_opts" | sed 's/+/-/g')"
   fi
   _openssl_opts=${_openssl_opts:=$_DEFAULT_OPENSSL_OPTS}
   _openssl_opts="$_openssl_opts -noout"
   #echo "debug: opts: '$_openssl_opts'"
   if [ -z "$_cert_bundle" ]; then
      ls *.crt > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         echo "certificate(s) found"
         _cbs=$(ls *.crt)
      else
         echo "no certificate files found"
         return
      fi
   else
      _cbs=$_cert_bundle
   fi
   for _cb in $_cbs; do
      echo "---------------- ( $_cb ) ---------------------"
      cat $_cb | \
         awk '{\
            if ($0 == "-----BEGIN CERTIFICATE-----") cert=""; \
            else if ($0 == "-----END CERTIFICATE-----") print cert; \
            else cert=cert$0}' | \
               while read cert; do
                  [[ $_more ]] && echo "---"
                  echo "$cert" | \
                     base64 --decode | \
                     #base64 -d | \
                        openssl x509 -inform DER $_openssl_opts | \
                           awk '{
                              if ($1~/subject=/)
                                 { gsub("subject=","  sub:",$0); print $0 }
                              else if ($1~/issuer=/)
                                 { gsub("issuer=","isuer:",$0); print $0 }
                              else if ($1~/notBefore/)
                                 { gsub("notBefore=","dates: ",$0); printf $0" -> " }
                              else if ($1~/notAfter/)
                                 { gsub("notAfter=","",$0); print $0 }
                              else if ($1~/[0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z]/)
                                 { print " hash: "$0 }
                              else
                                 { print $0 }
                           }'
                  local _more=yes
               done
   done
}

# main
if [ "$1" == "-h" ]; then
   echo "$USAGE"
else
   listcrts $*
fi
