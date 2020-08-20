#!/bin/bash

PAT=$1      # the personal access token to use
PKG_NAME=$2 # e.g. app_dashboard
MAJ_MIN=$3  # e.g. 1.2

ORG=my_org
PROJ=my_proj
FEED=my_feed
# GET_PKGS_URL="https://feeds.dev.azure.com/${ORG}/${PROJ}/_apis/packaging/Feeds/${FEED}/packages?packageNameQuery=${PKG_NAME}&includeUrls=false&includeAllVersions=true&api-version=5.1-preview.1"
GET_PKGS_URL="https://feeds.dev.azure.com/${ORG}/${PROJ}/_apis/packaging/Feeds/${FEED}/packages?packageNameQuery=${PKG_NAME}&includeUrls=false&api-version=5.1-preview.1"

pkg_uid=$(curl -X GET -s -u ":${PAT}" "$GET_PKGS_URL" | jq -r .value[].id)
if [ -z "$pkg_uid" ]; then
   echo "can't find an ADO Artifacts package matching (feed/package): $FEED/$PKG_NAME"
   exit
elif [ "$(wc -l <<< "$pkg_uid")" -gt 1 ]; then
   echo "found more than 1 ADO Artifacts packages matching (feed/packages): $FEED/$PKG_NAME"
   # echo "debug: package IDs found: " $pkg_uid
   pkg_names=$(curl -X GET -s -u ":${PAT}" "$GET_PKGS_URL" | jq -r .value[].name)
   echo "try one of these:" $pkg_names
   exit
else
   # echo "debug: found ADO Artifacts package ID matching (feed/packages): $FEED/$PKG_NAME"
   # echo "debug: package ID found: $pkg_uid"
   pkg_name=$(curl -X GET -s -u ":${PAT}" "$GET_PKGS_URL" | jq -r .value[].name)
fi

GET_PKG_VERSIONS_URL="https://feeds.dev.azure.com/${ORG}/${PROJ}/_apis/packaging/Feeds/${FEED}/Packages/${pkg_uid}/versions?api-version=5.1-preview.1"
versions=$(curl -X GET -s -u ":${PAT}" "$GET_PKG_VERSIONS_URL" | jq -r .value[].version)
# echo "debug: versions found:" $versions

latest_version=$(grep "^$MAJ_MIN." <<< "$versions" | sort -t '.' -k 3 -h | tail -1)

if [ -n "$latest_version" ]; then
   new_patch_version=$((${latest_version##*.} + 1))
   # echo "debug: found latest version: $latest_version"
   # echo "debug: need to build/create/publish version: $MAJ_MIN.$new_patch_version"
   echo "$pkg_name: latest version: [$latest_version]. build/create/publish version: [$MAJ_MIN.$new_patch_version]"
else
   # echo "debug: did not find a latest version"
   # echo "debug: need to build/create/publish version: $MAJ_MIN.0"
   echo "$pkg_name: latest version: [not found]. build/create/publish version: [$MAJ_MIN.0]"
fi
