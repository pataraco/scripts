#!/usr/bin/env bash
#
# description:
#   deploys/removes a list of serverless configs in a specific order

# set up trap ASAP (and the temp and log files first)
THIS_SCRIPT=$(basename $0)
TMP_FILE=$(mktemp /tmp/$THIS_SCRIPT.out.XXXXX) || exit 1
trap "rm -f $TMP_FILE" EXIT
LOG_FILE="/tmp/$THIS_SCRIPT.log"
true > $LOG_FILE

DEPLOYMENT_ORDER="
   serverless-api-gateway.yml
   serverless-stripe-events.yml
   serverless-cloudwatch-logs-to-elasticsearch.yml
   serverless-cognito-triggers-service.yml
   serverless-creditcheck-service.yml
   serverless-data-export-service.yml
   serverless-inventory-service.yml
   serverless-notification-service.yml
   serverless-portal-service.yml
   serverless-s3-inventory-import-service.yml
   serverless-s3-signed-url-service.yml
   serverless-schedule-service.yml
   serverless-user-service.yml
   serverless-api-domain.yml
"

# get O.S. name
OS_NAME=$(uname)

# get git info
GIT_REPO="$(basename $(git remote get-url origin) .git)"
if [ -n "$CODEBUILD_WEBHOOK_HEAD_REF" ]; then
   GIT_BRANCH=${CODEBUILD_WEBHOOK_HEAD_REF##*/}
   GIT_COMMIT=$CODEBUILD_SOURCE_VERSION
else
   GIT_BRANCH=$(git rev-parse --quiet --abbrev-ref HEAD)
   GIT_COMMIT=$(git rev-parse --quiet HEAD)
fi

# Slack deploy message variables
SLACK_COLOR_FAIL="danger"
SLACK_COLOR_PASS="good"
SLACK_EMOJI_FAIL=":rage:"
SLACK_EMOJI_PASS=":grinning:"
SLACK_STATUS_FAIL="failed"
SLACK_STATUS_PASS="success"
SLACK_SSM_PARAM_WEBHOOK="/slack/webhooks/be-sls-deploys"
SLACK_WEBHOOK=$(aws ssm get-parameter --name $SLACK_SSM_PARAM_WEBHOOK --with-decryption --query Parameter.Value --output text)

# some ansi colorization escape sequences
[ "$OS_NAME" == "Darwin" ] && ESC="\033" || ESC="\e"
D2E="${ESC}[K"      # delete text to end of line
RED="${ESC}[1;31m"  # red    FG (failures)
GRN="${ESC}[1;32m"  # green  FG (successful/updated)
YLW="${ESC}[1;33m"  # yellow FG (warnings)
BLU="${ESC}[1;34m"  # blue   FG (no changes)
NRM="${ESC}[m"      # to make text normal

# get the correct 'echo -e'
[ "$(echo -e)" == "-e" ] && ECHO_E="echo" || ECHO_E="echo -e"

# some globals
DEFAULT_STAGE="dev"
SLS_CMD_NAME="serverless"
SLS_CMD=$(command -v $SLS_CMD_NAME)
VALID_ACTIONS="deploy info"
VALID_STAGES="dev stg staging prod"
exit_status=0  # the script's exit status

# status codes
if [ "$CODEBUILD_CI" == "true" ]; then # CodeBuild run - don't colorize results
   # exit statuses
   FAILED="✗"
   SUCCESS="✓"
   # results
   CREATED="Created"
   ERROR="Error"
   NO_CHANGES="No Changes"
   SKIPPED="Skipped"
   UPDATED="Updated"
   WARNING="Warning"
else
   # exit statuses
   FAILED="${RED}✗${NRM}"
   SUCCESS="${GRN}✓${NRM}"
   # results
   CREATED="${GRN}Created${NRM}"
   NO_CHANGES="${BLU}No Changes${NRM}"
   ERROR="${RED}Error${NRM}"
   SKIPPED="${BLU}Skipped${NRM}"
   UPDATED="${GRN}Updated${NRM}"
   WARNING="${YLW}Warning${NRM}"
fi

# serverless output messages
SLS_CF_STACK="stack:"
SLS_CREATE_FINISHED="Stack create finished"
SLS_ERROR="Error -"
SLS_RESOURCES="resources:"
SLS_SKIPPING="Service files not changed. Skipping deployment"
SLS_UPDATE_FINISHED="Stack update finished"
SLS_WARNING="Serverless Warning"

# set the usage
USAGE="\
$0 -a ACTION [-s STAGE] [-p PROFILE] [-h] [-v] [-d]
   -a ACTION   SLS action to perform [${VALID_ACTIONS// /|}] (required)
   -s STAGE    Stage (environment) to deploy (default: $DEFAULT_STAGE)
   -p PROFILE  AWS profile to use (optional)
   -d          Dry-run - show the commands that would be run, but don't run them
   -v          Verbose - show all stack events
   -x          Debug - enable debugging output
   -h          Show help/usage (this message)"

# declare some arrays to save the errors, results and warnings
declare -a all_errs  # all the errors
declare -a all_warns # all the warnings
declare -a cf_stats  # CloudFormation stack stats
declare -a errs      # configs that have errors
declare -a execs     # execution results (✔︎ or ✗)
declare -a stats     # status results (Error, No Changes, Skipped, etc.)
declare -a warns     # configs that have warnings

# define functions
function line {
# prints a line of length $2 of char $1
   printf -- "$1%.s" $(seq 1 $2)
}

function print_usage {
# show usage and exit
   echo "Usage: $USAGE"
   exit 1
}

# parse the arguments
while getopts "a:dhp:s:vx" opt; do
   case "$opt" in
      a) action=$OPTARG                  ;;
      d) dry_run="true"                  ;;
      h) print_usage                     ;;
      p) profile="--aws-profile $OPTARG" ;;
      s) stage=$OPTARG                   ;;
      v) verbose="--verbose"             ;;
      x) export SLS_DEBUG="true"         ;;
      *) print_usage                     ;;
   esac
done

# sanity checks / set defaults
# make sure valid stage provided, if not, set to default
if [ -n "$stage" ]; then
  if [[ ! $VALID_STAGES =~ $stage ]]; then
     echo "error: '$stage' is not a valid stage"
     echo "please choose one of these: $VALID_STAGES"
     exit 1
  fi
else
   stage=$DEFAULT_STAGE
fi
# make sure 'sls' command was found
if [ -z "$SLS_CMD" ]; then
  echo "error: '$SLS_CMD_NAME' command not found"
  exit 1
fi

# set the list of configs to process
case "$action" in
   deploy) configs=$DEPLOYMENT_ORDER;;
   info) configs=$DEPLOYMENT_ORDER;;
   '')
      echo "error: did not specify an action"
      print_usage;;
   *)
      echo "error: not a valid action: $action"
      echo "please choose one of these: $VALID_ACTIONS"
      exit 1;;
esac

# ensure that the syntax of the configurations are correct and/or that the
# variables are resolving as expected using the 'print' command
echo | tee -a $LOG_FILE
echo "testing the configuration syntax and variable resolution" | tee -a $LOG_FILE
echo "of all the serverless configuration files" | tee -a $LOG_FILE
for config in $configs; do
   config_name=${config%.yml}
   command="$SLS_CMD print --config $config"
   $ECHO_E "  checking: ${config}...${D2E}\c"
   eval "$command > $TMP_FILE 2> /dev/null"
   # check for warnings
   if [ "$(fgrep -o "$SLS_WARNING" $TMP_FILE)" ]; then
      while read warning; do
         all_warns+=(" - $warning\n")
      done <<< "$(awk 'f && NR==f+2; /'"$SLS_WARNING"'/ {f=NR}' $TMP_FILE)"
      exit_status=1
   fi
   $ECHO_E "done\r\c"
done


# print any warnings found and exit if any
if [ ${#all_warns[*]} -gt 0 ]; then
   $ECHO_E "done testing serverless configs - [warnings found]${D2E}" | tee -a $LOG_FILE
   echo | tee -a $LOG_FILE
   echo "Warnings Found" | tee -a $LOG_FILE
   line - 14 | tee -a $LOG_FILE
   for i in $(seq 0 $((${#all_warns[*]}-1))); do
      $ECHO_E "${all_warns[$i]}" | tee -a $LOG_FILE
   done | sort -bu
   echo | tee -a $LOG_FILE
   echo "exiting" | tee -a $LOG_FILE
   exit $exit_status
else
   $ECHO_E "done testing serverless configs - [no warnings found]${D2E}" | tee -a $LOG_FILE
fi

# perform the actions
echo | tee -a $LOG_FILE
echo "performing the '$action' action in the '$stage' environment" | tee -a $LOG_FILE
echo "for all the serverless configuration files" | tee -a $LOG_FILE
# initialize vars
mcl=0          # max config name length     (for formating)
mcs=0          # max CF stack status length (for formating)
msl=0          # max status length          (for formating)
i=0            # index into arrays
for config in $configs; do
   config_name=${config%.yml}
   [ ${#config_name} -gt $mcl ] && mcl=${#config_name}
   echo | tee -a $LOG_FILE
   if [ "$CODEBUILD_CI" == "true" ]; then  # CodeBuild run - don't colorize
      echo "======= $config_name [$action|$stage|$GIT_BRANCH] =======" | tee -a $LOG_FILE
   else
      $ECHO_E "${BLU}======= ${GRN}$config_name ${YLW}[$action|$stage|$GIT_BRANCH] ${BLU}=======${NRM}" | tee -a $LOG_FILE
   fi
   echo | tee -a $LOG_FILE
   command="$SLS_CMD $action --stage $stage $profile --config $config $verbose"

   # perform the actual 'serverless' command and log the out to TMP_FILE
   if [ "$dry_run" == "true" ]; then
      echo "dry-run: $command" | tee -a $LOG_FILE
   else
      echo "running: $command" | tee -a $LOG_FILE
      echo | tee -a $LOG_FILE
      # eval "$command" | tee $TMP_FILE     # removes colorized output from sls
      if [ "$OS_NAME" == "Darwin" ]; then
         script -q $TMP_FILE $command       # this retains sls colorized output
         script_exit=$?
      elif [ "$OS_NAME" == "Linux" ]; then
         script -q -c "$command" $TMP_FILE
         script_exit=$?
      else
         echo "error: unknown 'script' command syntax for O.S.: $OS_NAME" | tee -a $LOG_FILE
         exit 1
      fi
      if [ $script_exit -eq 0 ]; then
         execs[$i]="$SUCCESS"
      else
         execs[$i]="$FAILED"
         exit_status=1
      fi
   fi

   # search through the TMP_FILE for status
   if [ "$(fgrep -o "$SLS_SKIPPING" $TMP_FILE)" ]; then
      stats[$i]="$SKIPPED"
   elif [ "$(fgrep -o "$SLS_CREATE_FINISHED" $TMP_FILE)" ]; then
      stats[$i]="$CREATED"
   elif [ "$(fgrep -o "$SLS_UPDATE_FINISHED" $TMP_FILE)" ]; then
      stats[$i]="$UPDATED"
   elif [ "$action" == "info" ]; then
      # the following `tr -d` is deleting a ^M control character
      no_of_resources=$(fgrep "$SLS_RESOURCES" $TMP_FILE | awk '{print $NF}' | tr -d '')
      [ -z "$no_of_resources" ] && no_of_resources="???"
      resource_status=$(printf "%3s Resources" $no_of_resources)
      if [ "$CODEBUILD_CI" == "true" ]; then # CodeBuild run - don't colorize results
         stats[$i]="$resource_status"
      else
         stats[$i]="${BLU}$resource_status${NRM}"
      fi
   else
      stats[$i]="$NO_CHANGES"
   fi
   [ ${#stats[$i]} -gt $msl ] && msl=${#stats[$i]}

   # check for warnings
   if [ "$(fgrep -o "$SLS_WARNING" $TMP_FILE)" ]; then
      unset config_warnings
      declare -a config_warnings
      config_warnings+=("$config_name:\n")
      while read warning; do
         config_warnings+=("   - $warning\n")
      done <<< "$(awk 'f && NR==f+2; /'"$SLS_WARNING"'/ {f=NR}' $TMP_FILE)"
      all_warns+=("${config_warnings[*]}")
      warns[$i]="$WARNING"
      [ $(fgrep -c "$SLS_WARNING" $TMP_FILE) -gt 1 ] && warns[$i]=$(sed 's/g/gs/' <<< ${warns[$i]})
      exit_status=1
   fi

   # check for errors
   if [ "$(fgrep -o "$SLS_ERROR" $TMP_FILE)" ]; then
      unset config_errors
      declare -a config_errors
      config_errors+=("$config_name:\n")
      while read error; do
         config_errors+=("   - ${error#*Error: }\n")
      done <<< "$(awk 'f && NR==f+2; /'"$SLS_ERROR"'/ {f=NR}' $TMP_FILE)"
      all_errs+=("${config_errors[*]}")
      errs[$i]="$ERROR"
      execs[$i]="$FAILED"
      exit_status=1
   fi

   # check for CloudFormation stack names and get their status
   if [ "$(fgrep -o "$SLS_CF_STACK" $TMP_FILE)" ]; then
      # the following `tr -d` is deleting a ^M control character
      cf_stack_name=$(fgrep "$SLS_CF_STACK" $TMP_FILE | cut -d' ' -f2 | tr -d '')
      cf_stats[$i]="[$(aws cloudformation describe-stacks --stack-name $cf_stack_name --query Stacks[].StackStatus --output text)]"
      [ ${#cf_stats[$i]} -gt $mcs ] && mcs=${#cf_stats[$i]}
   fi

   # save the output of the 'serverless' command to the LOG_FILE
   cat $TMP_FILE >> $LOG_FILE
   ((i++))
done

# print out summary (if not a dry-run)
if [ "$dry_run" != "true" ]; then
   echo | tee -a $LOG_FILE
   echo "Execution Summary - Serverless Action: $action (Stage: $stage) Git Branch: [$GIT_BRANCH]" | tee -a $LOG_FILE
   line - 17 | tee -a $LOG_FILE
   echo | tee -a $LOG_FILE
   if [ "$CODEBUILD_CI" == "true" ]; then # CodeBuild run - not colorized
      if [ $mcs -ne 0 ]; then
         printf "?*%-${mcl}s  %-${msl}s  %-${mcs}s\n" " Serverless Config File" " Result" " CF Stack Status" | tee -a $LOG_FILE
         echo "- $(line - $(($mcl+1))) $(line - $((msl+1))) $(line - $mcs)" | tee -a $LOG_FILE
      else
         printf "?*%-${mcl}s  %-${msl}s\n" " Serverless Config File" " Result" | tee -a $LOG_FILE
         echo "- $(line - $(($mcl+1))) $(line - $((msl+1)))" | tee -a $LOG_FILE
      fi
   else
      if [ $mcs -ne 0 ]; then
         printf "?*%-${mcl}s  %-$(($msl-16))s  %-${mcs}s\n" " Serverless Config File" " Result" " CF Stack Status" | tee -a $LOG_FILE
         echo "- $(line - $(($mcl+1))) $(line - $((msl-15))) $(line - $mcs)" | tee -a $LOG_FILE
      else
         printf "?*%-${mcl}s  %-$(($msl-16))s\n" " Serverless Config File" " Result" | tee -a $LOG_FILE
         echo "- $(line - $(($mcl+1))) $(line - $((msl-15)))" | tee -a $LOG_FILE
      fi
   fi
   i=0
   for config in $configs; do
      # get warnings and errors
      unset wsnes
      [ -n "${warns[$i]}" ] && wsnes="(${warns[$i]})"
      [ -n "${errs[$i]}" ] && wsnes="(${errs[$i]})"
      [ -n "${warns[$i]}" -a -n "${errs[$i]}" ] && wsnes="(${warns[$i]}, ${errs[$i]})"
      $ECHO_E "$(printf "${execs[$i]} %-${mcl}s - %${msl}s %${mcs}s %s" "${config%.yml}" "${stats[$i]}" "${cf_stats[$i]}" "$wsnes")" | tee -a $LOG_FILE
      ((i++))
   done
   echo | tee -a $LOG_FILE
   $ECHO_E " ?*: $SUCCESS = 'sls $action' succeeded or $FAILED = failed (has warnings/errors)" | tee -a $LOG_FILE
fi

echo | tee -a $LOG_FILE

# print any warnings
if [ ${#all_warns[*]} -gt 0 ]; then
   echo "Warnings Summary" | tee -a $LOG_FILE
   line - 16 | tee -a $LOG_FILE
   echo | tee -a $LOG_FILE
   for i in $(seq 0 $((${#all_warns[*]}-1))); do
      $ECHO_E "${all_warns[$i]}" | tee -a $LOG_FILE
   done
fi

# print any errors
if [ ${#all_errs[*]} -gt 0 ]; then
   echo "Errors Summary" | tee -a $LOG_FILE
   line - 14 | tee -a $LOG_FILE
   echo | tee -a $LOG_FILE
   for i in $(seq 0 $((${#all_errs[*]}-1))); do
      $ECHO_E "${all_errs[$i]}" | tee -a $LOG_FILE
   done
fi

echo "finished: all executions logged here: $LOG_FILE"

# send Slack notification message
[ "$dry_run" == "true" ] && dr="dry-run: "
if [ -n "$CODEBUILD_BUILD_URL" ]; then
   deploy_method="<$CODEBUILD_BUILD_URL|AWS CodeBuild>"
else
   deploy_method="manual"
fi
if [ $exit_status -eq 0 ]; then
   slack_color=$SLACK_COLOR_PASS
   slack_emoji=$SLACK_EMOJI_PASS
   slack_status=$SLACK_STATUS_PASS
else
   slack_color=$SLACK_COLOR_FAIL
   slack_emoji=$SLACK_EMOJI_FAIL
   slack_status=$SLACK_STATUS_FAIL
fi
aws_acct="$(aws iam list-account-aliases --query AccountAliases --output text)"
if [ -n "$AWS_REGION" ]; then
   aws_region=$AWS_REGION
elif [ -n "$AWS_DEFAULT_REGION" ]; then
   aws_region=$AWS_DEFAULT_REGION
else
   aws_region="$(aws configure get region)"
fi
git_info="$GIT_REPO ($GIT_BRANCH)"
slack_body='{
    "text": "Backend Serverless Control",
    "attachments": [
        {
            "color": "'"$slack_color"'",
            "fallback": "'"Summary - _Action_: *$action* | _Stage_: *$stage* | _Git_: *$git_info $GIT_COMMIT* | _Status_: *$slack_status* $slack_emoji"'",
            "fields": [
                {"title": "Script/Options:", "value": "'"$THIS_SCRIPT $*"'", "short": true},
                {"title": "Git Repo (Branch/Tag):", "value": "'"$git_info"'", "short": true},
                {"title": "Release/Git Commit:", "value": "'"$GIT_COMMIT"'", "short": false},
                {"title": "AWS Account (Region):", "value": "'"$aws_acct ($aws_region)"'", "short": true},
                {"title": "Environment:", "value": "'"$stage"'", "short": true},
                {"title": "Method:", "value": "'"${dr}$deploy_method"'", "short": true},
                {"title": "Action (Status):", "value": "'"${dr}$action ($slack_status) $slack_emoji"'", "short": true}
            ]
        }
    ]
}'
curl -s -X POST --data-urlencode "payload=$slack_body" $SLACK_WEBHOOK > /dev/null

# if any errors occured, exit with exit status = 1 (good for CI/CD)
# exit_status set to 1 (above) if/when any errors/warnings occur
exit $exit_status
