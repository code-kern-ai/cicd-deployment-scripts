#!/bin/bash

set -e

PR_NUMBER=""
SOURCE_SCRIPT="pi/settings.sh"

while getopts p:s: flag
do
    case "${flag}" in
        p) PR_NUMBER=${OPTARG};;
        s) SOURCE_SCRIPT=${OPTARG};;
    esac
done

source $SOURCE_SCRIPT

UPDATED_FILES=$(gh pr diff $PR_NUMBER --name-only)
UPDATED_PARENT_TYPES=()
while IFS= read -r file; do
    if [[ $file != requirements/* ]] || [[ $file != *.in ]]; then
        continue
    fi
    
    parent_image_type=$(basename $file | sed 's|-requirements.in||g')
    UPDATED_PARENT_TYPES+=($parent_image_type)

done <<< "$UPDATED_FILES"

INCLUDES=""
for parent_image_type in "${UPDATED_PARENT_TYPES[@]}"; do
    eval 'APP_REPOS=( "${'$(echo ${parent_image_type} | sed "s|-|_|g")'[@]}" )'
    for app in "${APP_REPOS[@]}"; do
        INCLUDES+='{ "parent_image_type": "'${parent_image_type}'", "app": "'${app}'" },'
    done
done

MATRIX='{"include": ['${INCLUDES::-1}']}'
echo $MATRIX | jq -C --indent 2 '.'
echo "include=[${INCLUDES::-1}]" >> $GITHUB_OUTPUT