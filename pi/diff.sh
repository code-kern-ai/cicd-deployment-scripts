#!/bin/bash

set -e

PR_NUMBER=""

while getopts p: flag
do
    case "${flag}" in
        p) PR_NUMBER=${OPTARG};;
    esac
done

UPDATED_FILES=$(gh pr diff $PR_NUMBER --name-only)
UPDATED_PARENT_TYPES=()
while IFS= read -r file; do
    if [[ $file != requirements/* ]] || [[ $file != *.in ]]; then
        continue
    fi
    
    parent_image_type=$(basename $file | sed 's|-requirements.in||g')
    UPDATED_PARENT_TYPES+=($parent_image_type)

done <<< "$UPDATED_FILES"

JSON=""
for parent_image_type in "${UPDATED_PARENT_TYPES[@]}"; do
    JSON+="\"$parent_image_type\","
done
JSON="[${JSON::-1}]"
echo "updated_parent_types=$JSON" >> $GITHUB_OUTPUT