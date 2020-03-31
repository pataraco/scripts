#!/bin/bash
#
# Description:
#    Get an AWS STS session token using a profile defined in ~/.aws/config
#
# Requirements:
#   Must use [profile $#PROFILE] in ~/.aws/config file for your profiles
#
#   Example ~/.aws/config
#
#      [profile dev]
#      aws_access_key_id = AERFVBNTYFVHGDSSRTGF
#      aws_secret_access_key = SDFBB#$dgADSF#$FDGdvdk$$fjkvED
#      mfa_serial = arn:aws:iam::1234567890:mfa/username
#      

# usage
#    this script needs to be sourced in order to set your current environment
#
#    e.g. -> source $THIS_SCRIPT [PROFILE]

# globals
AWS_CFG=$HOME/.aws/config
STS_DURATION=43200  # 12 hours
AWS_PROFILES=$(grep '^\[profile' $AWS_CFG | awk '{print $2}' | tr -s ']\n' ' ')
VALID_PROFILES=$(echo "${AWS_PROFILES}unset" | tr ' ' ':')
PROFILE="$1"
CODE="$2"
AWS_STS_CREDS=$HOME/.aws/${PROFILE}_mfa_credentials

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
      mfa_arn=$(awk '$2~/'"$PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/mfa_serial/) {print $3; exit}; (pfound=="true" && $1~/profile/) {exit}' $AWS_CFG | sed 's/ *$//')
      if [ -n "$CODE" ]; then
         code=$CODE
      else
         read -p "yo: Enter the 6-digit code from your MFA device: " code
      fi
      aws sts get-session-token --profile $PROFILE --serial-number $mfa_arn --token-code $code > $AWS_STS_CREDS
      if [ $? -eq 0 ]; then
         export AWS_ACCESS_KEY_ID=$(grep AccessKeyId $AWS_STS_CREDS | cut -d'"' -f4)
         export AWS_SECRET_ACCESS_KEY=$(grep SecretAccessKey $AWS_STS_CREDS | cut -d'"' -f4)
         export AWS_SESSION_TOKEN=$(grep SessionToken $AWS_STS_CREDS | cut -d'"' -f4)
         aws_default_region=$(awk '$2~/'"$PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/region/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' $AWS_CFG)
         [ -n aws_default_region ] && export AWS_DEFAULT_REGION=$aws_default_region
         export AWS_STS_EXPIRES_TS=$(grep Expiration $AWS_STS_CREDS | cut -d'"' -f4)
         echo "MFA has been set"
         true
      else
         echo "MFA could NOT be set"
         false
      fi
   fi
fi
