function listcrts2 {
   # another way to list all info in a crt bundle
   for _c; do
      echo
      echo "Certificate: $_c"
      [ ! -f "$_c" ] && { echo " X - Certificate not found"; continue; }
      _n_cert=$(grep -hc "BEGIN CERTIFICATE" "$_c")
      [ "$_n_cert" -lt 1 ] && { echo " X - Not valid certificate"; continue; }
      for n in $(seq 1 $_n_cert);do
         awk -v n=$n '/BEGIN CERT/ { n -= 1;} n == 0 { print }' "$_c" | \
            openssl x509 -noout -text | sed -n \
               -e 's/^/ o - /' \
               -e 's/ *Signature Algorithm: / signature=/p' \
               -e 's/ *Not Before: / notBefore=/p' \
               -e 's/ *Not After *: / notAfter=/p' \
               -e 's/ *Issuer: / issuer=/p' \
               -e 's/ *Subject: / subject=/p' \
               -e '/Subject Public Key Info/q' | sort -r
         echo " -------------"
      done
   done
}
