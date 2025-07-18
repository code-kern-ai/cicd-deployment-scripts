#!/bin/bash

set -e

PR_NUMBER=""
SOURCE_SCRIPT="pi/constants.sh"
PARENT_IMAGE_TYPE=""
EDIT_DOCKERFILE=false

while getopts t:p:s:d: flag
do
    case "${flag}" in
        t) PARENT_IMAGE_TYPE=${OPTARG};;
        p) PR_NUMBER=${OPTARG};;
        s) SOURCE_SCRIPT=${OPTARG};;
        d) EDIT_DOCKERFILE=${OPTARG};;
    esac
done

source $SOURCE_SCRIPT

UPDATED_PARENT_TYPES=()

if [ -n "$PR_NUMBER" ] && [ -z "$PARENT_IMAGE_TYPE" ]; then
    UPDATED_FILES=$(gh pr diff $PR_NUMBER --name-only --repo code-kern-ai/refinery-submodule-parent-images)
    while IFS= read -r file; do
        if [[ $file != requirements/* ]] || [[ $file != *.in ]]; then
            continue
        fi
        
        parent_image_type=$(basename $file | sed 's|-requirements.in||g')
        UPDATED_PARENT_TYPES+=($parent_image_type)

    done <<< "$UPDATED_FILES"
    # TODO: UPDATED_PARENT_TYPES are not resolved correctly
    echo -e "::notice::Exporting matrix for parent image types: $UPDATED_PARENT_TYPES"
elif [ -n "$PARENT_IMAGE_TYPE" ]; then
    echo "::notice::Exporting matrix for parent image type: $PARENT_IMAGE_TYPE"
    UPDATED_PARENT_TYPES=( $PARENT_IMAGE_TYPE )
fi

PARENT_IMAGE_TYPES=""
UPDATE_APPS=""
INCLUDES=""
for parent_image_type in "${UPDATED_PARENT_TYPES[@]}"; do
    PARENT_IMAGE_TYPES+="\"$parent_image_type\","
    if [ $EDIT_DOCKERFILE = true ]; then
        eval 'APP_REPOS=( "${'$(echo ${parent_image_type}_dockerfile | sed "s|-|_|g")'[@]}" )'
    else
        eval 'APP_REPOS=( "${'$(echo ${parent_image_type} | sed "s|-|_|g")'[@]}" )'
    fi
    for app in "${APP_REPOS[@]}"; do
        if [[ ! "$UPDATE_APPS" == *"$app"* ]]; then
            UPDATE_APPS+='"'$app'",'
        fi
        # Includes require keeping track of constants, but is a controlled approach (instead of UPDATE_APPS)
        INCLUDES+='{ "parent_image_type": "'${parent_image_type}'", "app": "'${app}'" },'
    done
done

MATRIX='['${UPDATE_APPS::-1}']'
echo $MATRIX | jq -C --indent 2 '.'
echo "app=[${UPDATE_APPS::-1}]" >> $GITHUB_OUTPUT
echo "parent_image_type=[${PARENT_IMAGE_TYPES::-1}]" >> $GITHUB_OUTPUT