#!/bin/bash

export DEV_ADMIN_GITHUB_TEAM_ID=10188509
export DEVOPS_ADMIN_GITHUB_TEAM_ID=10188507

source admin/repo_list/app_iac.sh
source admin/repo_list/tf_iac.sh
source admin/repo_list/tf_module.sh

function get_ruleset_by_name() {
    REPOSITORY_OWNER=${1}
    REPOSITORY_NAME=${2}
    RULESET_NAME=${3}
    
    echo $(gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/rulesets \
        --jq '.[] | select(.name == "'${RULESET_NAME}'") | .id')
}

function create_ruleset() {
    REPOSITORY_OWNER=${1}
    REPOSITORY_NAME=${2}
    ENVIRONMENT_NAME=${3}

    echo "Creating ruleset for ${ENVIRONMENT_NAME} - ${REPOSITORY_OWNER}/${REPOSITORY_NAME}"

    RULESET_CONTENT=$(echo $(sed \
        -e "s|\${ENVIRONMENT_NAME}|${ENVIRONMENT_NAME}|g" \
        -e "s|\${DEV_ADMIN_GITHUB_TEAM_ID}|${DEV_ADMIN_GITHUB_TEAM_ID}|g" \
        -e "s|\${DEVOPS_ADMIN_GITHUB_TEAM_ID}|${DEVOPS_ADMIN_GITHUB_TEAM_ID}|g" \
        admin/repo_static/${ENVIRONMENT_NAME}/ruleset.json.tmpl))

    echo "${RULESET_CONTENT}" | gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/rulesets \
        --input - 1>/dev/null
}

function update_ruleset() {
    REPOSITORY_OWNER=${1}
    REPOSITORY_NAME=${2}
    ENVIRONMENT_NAME=${3}
    RULESET_ID=${4}

    echo "Updating ruleset for ${ENVIRONMENT_NAME} - ${REPOSITORY_OWNER}/${REPOSITORY_NAME}"

    RULESET_CONTENT=$(echo $(sed \
        -e "s|\${ENVIRONMENT_NAME}|${ENVIRONMENT_NAME}|g" \
        -e "s|\${DEV_ADMIN_GITHUB_TEAM_ID}|${DEV_ADMIN_GITHUB_TEAM_ID}|g" \
        -e "s|\${DEVOPS_ADMIN_GITHUB_TEAM_ID}|${DEVOPS_ADMIN_GITHUB_TEAM_ID}|g" \
        admin/repo_static/${ENVIRONMENT_NAME}/ruleset.json.tmpl))

    echo "${RULESET_CONTENT}" | gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/rulesets/${RULESET_ID} \
        --input - 1>/dev/null
}

function update_repo_general_settings() {
    REPOSITORY_OWNER=${1}

    GENERAL_CONTENT=$(cat admin/repo_static/general.json)
    COMBINED_ARRAY=(${REPO_LIST_APP_IAC[@]} ${REPO_LIST_TF_IAC[@]} ${REPO_LIST_TF_MODULE[@]})
    for REPOSITORY_NAME in ${COMBINED_ARRAY[@]}; do
        echo "Updating general settings for ${REPOSITORY_OWNER}/${REPOSITORY_NAME}"
        echo "${GENERAL_CONTENT}" | gh api \
            --method PATCH \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            /repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME} \
            --input - 1>/dev/null
    done
}

function update_tf_module_rulesets() {
    REPOSITORY_OWNER=${1}
    ENVIRONMENT_NAME=${2}

    for REPOSITORY_NAME in ${REPO_LIST_TF_MODULE[@]}; do
        ruleset_id=$(get_ruleset_by_name ${REPOSITORY_OWNER} ${REPOSITORY_NAME} ${ENVIRONMENT_NAME})
        if [ -z "${ruleset_id}" ]; then
            create_ruleset ${REPOSITORY_OWNER} ${REPOSITORY_NAME} ${ENVIRONMENT_NAME}
        else
            update_ruleset ${REPOSITORY_OWNER} ${REPOSITORY_NAME} ${ENVIRONMENT_NAME} ${ruleset_id}
        fi
    done
}

function update_tf_iac_rulesets() {
    REPOSITORY_OWNER=${1}
    ENVIRONMENT_NAME=${2}

    COMBINED_ARRAY=(${REPO_LIST_APP_IAC[@]} ${REPO_LIST_TF_IAC[@]})
    for REPOSITORY_NAME in ${COMBINED_ARRAY[@]}; do
        ruleset_id=$(get_ruleset_by_name ${REPOSITORY_OWNER} ${REPOSITORY_NAME} ${ENVIRONMENT_NAME})
        if [ -z "${ruleset_id}" ]; then
            create_ruleset ${REPOSITORY_OWNER} ${REPOSITORY_NAME} ${ENVIRONMENT_NAME}
        else
            update_ruleset ${REPOSITORY_OWNER} ${REPOSITORY_NAME} ${ENVIRONMENT_NAME} ${ruleset_id}
        fi
    done
}