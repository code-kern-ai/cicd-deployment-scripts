#!/bin/bash

set -e

PR_NUMBER=""
DIFF_REF="dev"

while getopts p:r: flag
do
    case "${flag}" in
        p) PR_NUMBER=${OPTARG};;
        r) DIFF_REF=${OPTARG};;
    esac
done

echo "Printing diff"
git diff $DIFF_REF --color
UPDATED_FILES=$(git diff $DIFF_REF --name-only)
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
