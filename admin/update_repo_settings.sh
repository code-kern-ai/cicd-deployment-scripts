#!/bin/bash

set -e

REPOSITORY_OWNER="code-kern-ai"
REPOSITORY_NAME=""
DEV_ADMIN_GITHUB_TEAM_ID=10188509
DEVOPS_ADMIN_GITHUB_TEAM_ID=10188507

ENVIRONMENT_NAME="dev"

while getopts o:e: flag
do
    case "${flag}" in
        o) REPOSITORY_OWNER=${OPTARG};;
        e) ENVIRONMENT_NAME=${OPTARG};;
    esac
done

source admin/repo_list/app_iac.sh
source admin/repo_list/tf_iac.sh
source admin/repo_list/tf_module.sh

RULESET_CONTENT=$(echo $(sed \
    -e "s|\${ENVIRONMENT_NAME}|${ENVIRONMENT_NAME}|g" \
    -e "s|\${DEV_ADMIN_GITHUB_TEAM_ID}|${DEV_ADMIN_GITHUB_TEAM_ID}|g" \
    -e "s|\${DEVOPS_ADMIN_GITHUB_TEAM_ID}|${DEVOPS_ADMIN_GITHUB_TEAM_ID}|g" \
    admin/repo_static/${ENVIRONMENT_NAME}/ruleset.json.tmpl))


function get_ruleset_by_name() {
    REPOSITORY_NAME=${1}
    RULESET_NAME=${2}
    
    echo $(gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/rulesets \
        --jq '.[] | select(.name == "'${RULESET_NAME}'") | .id')
}

function create_ruleset() {
    REPOSITORY_NAME=${1}

    echo "${RULESET_CONTENT}" | gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/rulesets \
        --input - 1>/dev/null
}

function update_ruleset() {
    REPOSITORY_NAME=${1}
    RULESET_ID=${2}

    echo "${RULESET_CONTENT}" | gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/rulesets/${RULESET_ID} \
        --input - 1>/dev/null
}

echo "::group::Updating repository settings"
COMBINED_ARRAY=(${REPO_LIST_APP_IAC[@]} ${REPO_LIST_TF_IAC[@]} ${REPO_LIST_TF_MODULE[@]})
for REPOSITORY_NAME in ${COMBINED_ARRAY[@]}; do
    echo "Updating ${REPOSITORY_OWNER}/${REPOSITORY_NAME}"
    gh api \
        --method PATCH \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME} \
        -F "has_issues=true" \
        -F "has_projects=false" \
        -F "has_wiki=false" \
        -F "allow_squash_merge=true" \
        -F "allow_merge_commit=true" \
        -F "allow_rebase_merge=false" \
        -F "allow_auto_merge=false" \
        -F "delete_branch_on_merge=true" \
        -F "allow_update_branch=true" 1>/dev/null
done
echo "::endgroup::"

echo "::group::tf-module repository rulesets"

for REPOSITORY_NAME in ${REPO_LIST_TF_MODULE[@]}; do
    if [ "${ENVIRONMENT_NAME}" = "prod" ]; then
        # Module repositories do not need a prod ruleset
        continue
    fi

    ruleset_id=$(get_ruleset_by_name ${REPOSITORY_NAME} ${ENVIRONMENT_NAME})
    if [ -z "${ruleset_id}" ]; then
        echo "Creating ruleset for ${REPOSITORY_NAME}/${ENVIRONMENT_NAME}"
        create_ruleset ${REPOSITORY_NAME}
    else
        echo "Updating ruleset for ${REPOSITORY_NAME}/${ENVIRONMENT_NAME}"
        update_ruleset ${REPOSITORY_NAME} ${ruleset_id}
    fi
done

echo "::endgroup::"


echo "::group::app-tf-iac repository rulesets"
COMBINED_ARRAY=(${REPO_LIST_APP_IAC[@]} ${REPO_LIST_TF_IAC[@]})
for REPOSITORY_NAME in ${COMBINED_ARRAY[@]}; do
    ruleset_id=$(get_ruleset_by_name ${REPOSITORY_NAME} ${ENVIRONMENT_NAME})
    if [ -z "${ruleset_id}" ]; then
        echo "Creating ruleset for ${REPOSITORY_NAME}/${ENVIRONMENT_NAME}"
        create_ruleset ${REPOSITORY_NAME}
    else
        echo "Updating ruleset for ${REPOSITORY_NAME}/${ENVIRONMENT_NAME}"
        update_ruleset ${REPOSITORY_NAME} ${ruleset_id}
    fi
done
echo "::endgroup::"
