#!/bin/bash

PAT=$1       # the personal access token to use
REPO_NAME=$2
ORG=$3
PROJ=$4
merge_operation_id=$5
REPO_ID=$6
REF=$7
OOID=$8
NOID=$9

CREATE_MERGE_URL="https://dev.azure.com/${ORG}/${PROJ}/_apis/git/repositories/${REPO_NAME}/merges?api-version=6.0-preview.1"
MERGE_STATUS_URL="https://dev.azure.com/${ORG}/${PROJ}/_apis/git/repositories/${REPO_NAME}/merges/${merge_operation_id}?api-version=6.0-preview.1"
UPDATE_REFS_URL="https://dev.azure.com/${ORG}/${PROJ}/_apis/git/repositories/${REPO_ID}/refs?api-version=6.0"

# body='{
#   "parents": [
#     "12ad0a3f0f352a5b0b4f9741ca91d7544c1bca07",
#     "3b0cbfdfc34eac38a297a5a04731c2c7eede859c"
#   ],
#   "comment": "Merge two refs!"
# }'
# # response=$(curl -X POST -s -u ":${PAT}" -d "$body" "$CREATE_MERGE_URL" | jq -r .value[].id)
# response=$(curl -X POST -s -u ":${PAT}" -d "$body" "$CREATE_MERGE_URL")
# echo "response:"
# echo "$response"

# status=$(curl -X GET -s -u ":${PAT}" "$MERGE_STATUS_URL")
# # echo "status:"
# echo "$status"

body='[
  {
    "name": "'"$REF"'",
    "oldObjectId": "'"$OOID"'",
    "newObjectId": "'"$NOID"'"
  }
]'
echo "$body"
status=$(curl -X POST -s -u ":${PAT}" -d "$body" -H "Content-Type: application/json" "$UPDATE_REFS_URL")
# echo "status:"
echo "$status"
