#!/bin/bash
#
# find the matching crt/csr/key files in the current directory
#
# usage:
#	1. cd to the directory with the crt/csr/key files
#	2. execute the script
#
# to-do
#	none for now
#
# changes:
#	modified to capture multiple matching key files per set
#

max_crt_fn_len=12
max_csr_fn_len=12
max_key_fn_len=12
declare -A crt_files        # declare array as a indexed array
declare -A csr_files        # declare array as a indexed array
declare -A key_files        # declare array as a indexed array
temp_modulus_list_file=`mktemp /tmp/modulus_list_file.XXX.txt`

# find the type of file and record it when found
for file in `ls`; do
   #debug#echo -n "checking file: $file..."
   if [ -f $file ]; then
      modulus_raw=`openssl x509 -noout -modulus -in $file 2>/dev/null`
      if [ $? -eq 0 ]; then
         fn_len=`expr length "$file"`
         [ $max_crt_fn_len -lt $fn_len ] && max_crt_fn_len=$fn_len
         modulus=`echo $modulus_raw|openssl md5|awk '{print $NF}'`
         crt_files[$modulus]=$file
      else
         modulus_raw=`openssl req -noout -modulus -in $file 2>/dev/null`
         if [ $? -eq 0 ]; then
            fn_len=`expr length "$file"`
            [ $max_csr_fn_len -lt $fn_len ] && max_csr_fn_len=$fn_len
            modulus=`echo $modulus_raw|openssl md5|awk '{print $NF}'`
            csr_files[$modulus]=$file
         else
            modulus_raw=`openssl rsa -noout -modulus -in $file 2>/dev/null`
            if [ $? -eq 0 ]; then
               fn_len=`expr length "$file"`
               [ $max_key_fn_len -lt $fn_len ] && max_key_fn_len=$fn_len
               modulus=`echo $modulus_raw|openssl md5|awk '{print $NF}'`
               if [ -z "${key_files[$modulus]}" ]; then
                  key_files[$modulus]=$file
               else
                  key_files[$modulus]="${key_files[$modulus]} $file"
               fi
               #debug#echo "key_files[$modulus]='${key_files[$modulus]}'"
            fi
         fi
      fi
      echo $modulus >> $temp_modulus_list_file
   fi
   #debug#echo "done"
done

# display the results
# TODO: find a better way of doing this
i=`expr $max_crt_fn_len + $max_csr_fn_len + $max_key_fn_len + 9`
while [ $i -gt 0 ]; do echo -n "-"; ((i--)); done; echo "-"
printf "| %-${max_crt_fn_len}s | %-${max_csr_fn_len}s | %-${max_key_fn_len}s |\n" "crt filename" "csr filename" "key filename"
i=`expr $max_crt_fn_len + 2`
echo -n "|"; while [ $i -gt 0 ]; do echo -n "-"; ((i--)); done
i=`expr $max_csr_fn_len + 2`
echo -n "|"; while [ $i -gt 0 ]; do echo -n "-"; ((i--)); done
i=`expr $max_key_fn_len + 2`
echo -n "|"; while [ $i -gt 0 ]; do echo -n "-"; ((i--)); done; echo "|"
for modulus in `sort -u $temp_modulus_list_file`; do
   #debug#echo "modulus=$modulus: crt_file='${crt_files[$modulus]}' csr_file='${csr_files[$modulus]}' key_file='${key_files[$modulus]}'"
   no_of_kfs=`echo ${key_files[$modulus]} | wc -w`
   if [ $no_of_kfs -gt 1 ]; then
      for kf in ${key_files[$modulus]}; do
         printf "| %-${max_crt_fn_len}s | %-${max_csr_fn_len}s | %-${max_key_fn_len}s |\n" "${crt_files[$modulus]}" "${csr_files[$modulus]}" "$kf"
      done
   else
      printf "| %-${max_crt_fn_len}s | %-${max_csr_fn_len}s | %-${max_key_fn_len}s |\n" "${crt_files[$modulus]}" "${csr_files[$modulus]}" "${key_files[$modulus]}"
   fi
done
i=`expr $max_crt_fn_len + $max_csr_fn_len + $max_key_fn_len + 9`
while [ $i -gt 0 ]; do echo -n "-"; ((i--)); done; echo "-"

# remove the temp file
rm $temp_modulus_list_file
