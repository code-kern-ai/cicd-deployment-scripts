#!/bin/bash

set -e

PR_NUMBER=""

while getopts p: flag
do
    case "${flag}" in
        p) PR_NUMBER=${OPTARG};;
    esac
done

UPDATED_FILES=$(git diff --name-only)
while IFS= read -r file; do
    if [[ $file != requirements/* ]] || [[ $file != *.in ]]; then
        continue
    fi
    
    parent_image_type=$(basename $file | sed 's|-requirements.in||g')

    echo "::group::Compiling $parent_image_type-requirements.in"
    pip-compile requirements/$parent_image_type-requirements.in

    echo "Running pip install for $parent_image_type"
    python -m venv ./venv/
    source ./venv/bin/activate
    pip install -r requirements/$parent_image_type-requirements.txt
    echo "::endgroup::"

done <<< "$UPDATED_FILES"
