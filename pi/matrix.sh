#!/bin/bash

set -e

PARENT_IMAGE_TYPE=""
PR_NUMBER=""
SOURCE_SCRIPT="pi/settings.sh"

while getopts t:p:s: flag
do
    case "${flag}" in
        t) PARENT_IMAGE_TYPE=${OPTARG};;
        p) PR_NUMBER=${OPTARG};;
        s) SOURCE_SCRIPT=${OPTARG};;
    esac
done

source $SOURCE_SCRIPT

UPDATED_PARENT_TYPES=()

if [ -n $PR_NUMBER ] && [ -z $PARENT_IMAGE_TYPE ]; then
    UPDATED_FILES=$(gh pr diff $PR_NUMBER --name-only)
    while IFS= read -r file; do
        if [[ $file != requirements/* ]] || [[ $file != *.in ]]; then
            continue
        fi
        
        parent_image_type=$(basename $file | sed 's|-requirements.in||g')
        UPDATED_PARENT_TYPES+=($parent_image_type)

    done <<< "$UPDATED_FILES"
    echo "::notice::Exporting matrix for parent image types: $UPDATED_PARENT_TYPES"
elif [ -z $PR_NUMBER ] && [ -n $PARENT_IMAGE_TYPE ]; then
    echo "::notice::Exporting matrix for parent image type: $PARENT_IMAGE_TYPE"
    UPDATED_PARENT_TYPES=( $PARENT_IMAGE_TYPE )
fi

PARENT_IMAGE_TYPES=""
INCLUDES=""
for parent_image_type in "${UPDATED_PARENT_TYPES[@]}"; do
    PARENT_IMAGE_TYPES+="\"$parent_image_type\","
    eval 'APP_REPOS=( "${'$(echo ${parent_image_type} | sed "s|-|_|g")'[@]}" )'
    for app in "${APP_REPOS[@]}"; do
        INCLUDES+='{ "parent_image_type": "'${parent_image_type}'", "app": "'${app}'" },'
    done
done

MATRIX='{"include": ['${INCLUDES::-1}']}'
echo $MATRIX | jq -C --indent 2 '.'
echo "include=[${INCLUDES::-1}]" >> $GITHUB_OUTPUT
echo "parent_image_type=[${PARENT_IMAGE_TYPES::-1}]" >> $GITHUB_OUTPUT