#!/bin/bash
#
# Description:
#    Assume a role defined in ~/.aws/config
#    Normally you can just specify '--profile' option and the AWS CLI
#    will perform the "aws sts assume-role" for you, but if/when using/enforcing
#    MFA and using environment variables with temporary credentials (from using
#    your MFA, then you have to run the 'aws sts assume-role' yourself
#
# Requirements:
#   Must have AWS credentials configured (i.e. environment variables set)
#   Must use [profile $#PROFILE] in ~/.aws/config file for your profiles
#
#   Example ~/.aws/config
#
#      [profile dev]
#      aws_access_key_id = AERFVBNTYFVHGDSSRTGF
#      aws_secret_access_key = SDFBB#$dgADSF#$FDGdvdk$$fjkvED
#      
#      [profile prod]
#      role_arn = arn:aws:iam::048395965431:role/read-only
#      source_profile = dev
#      
# TODO:
#   Modify to perform the MFA auth too (if needed)

# usage
#    this script needs to be sourced in order to set your current environment
#
#    e.g. -> source $THIS_SCRIPT [PROFILE]

# globals
AWS_CFG=$HOME/.aws/config
STS_DURATION=3600
AWS_PROFILES=$(grep '^\[profile' $AWS_CFG | awk '{print $2}' | tr -s ']\n' ' ')
VALID_PROFILES=$(echo "${AWS_PROFILES}unset" | tr ' ' ':')
PROFILE="$1"
AWS_STS_CREDS=$HOME/.aws/${PROFILE}_credentials

if [ -n "$PROFILE" ]; then
   if [[ ! $VALID_PROFILES =~ ^$PROFILE:|:$PROFILE:|:$PROFILE$ ]]; then
      echo -e "error: profile not found... Only these exist (or use 'unset'):\n   " $AWS_PROFILES
      exit 2
   fi
   if [ "$PROFILE" == "unset" ]; then
      unset AWS_ACCESS_KEY_ID
      unset AWS_DEFAULT_PROFILE
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_SECURITY_TOKEN
      unset AWS_SESSION_TOKEN
      unset AWS_DEFAULT_REGION
      echo "environment has been unset"
  else
      unset AWS_DEFAULT_PROFILE
      unset AWS_SECURITY_TOKEN
      role_arn=$(awk '$2~/'"$PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/role_arn/) {print $3; exit}; (pfound=="true" && $1~/profile/) {exit}' $AWS_CFG | sed 's/ *$//')
      role_name=$(cut -d'/' -f2- <<< $role_arn)
      aws_acct=$(cut -d':' -f5 <<< $role_arn)
      aws sts assume-role --role-arn $role_arn --role-session-name $PROFILE --duration-seconds $STS_DURATION > $AWS_STS_CREDS
      if [ $? -eq 0 ]; then
         export AWS_ACCESS_KEY_ID=$(grep AccessKeyId $AWS_STS_CREDS | cut -d'"' -f4)
         export AWS_SECRET_ACCESS_KEY=$(grep SecretAccessKey $AWS_STS_CREDS | cut -d'"' -f4)
         export AWS_SESSION_TOKEN=$(grep SessionToken $AWS_STS_CREDS | cut -d'"' -f4)
         aws_default_region=$(awk '$2~/'"$PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/region/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' $AWS_CFG)
         [ -n aws_default_region ] && export AWS_DEFAULT_REGION=$aws_default_region
         echo "role has been assumed: $aws_acct ($role_name)"
      fi
   fi
else
   echo -n "--- AWS Environment "
   [ -n "$AWS_ACCESS_KEY_ID" -a -n "$AWS_SECRET_ACCESS_KEY" ] \
      && echo "Settings ---" \
      || echo "(NOT set) ---"
   # obfuscate the keys (with 'sed') in case someone is watching
   echo "AWS_ACCESS_KEY_ID     = ${AWS_ACCESS_KEY_ID:-N/A}" | sed 's:[F-HO-QT-V3-8]:*:g'
   echo "AWS_SECRET_ACCESS_KEY = ${AWS_SECRET_ACCESS_KEY:-N/A}" | sed 's:[d-np-zF-HO-QU-V4-9+]:*:g'
   echo "AWS_DEFAULT_REGION    = ${AWS_DEFAULT_REGION:-N/A}"
fi
