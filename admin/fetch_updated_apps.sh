#!/bin/bash

export THIRD_PARTY_SERVICES=(
    caddy
    postgres-migrate
    kratos-migrate
    kratos
    oathkeeper
    object-storage
    qdrant
)


function get_docker_compose_services() {
    for service in $(docker compose config --services); do
        is_third_party_service="false"
        for tps in ${THIRD_PARTY_SERVICES[@]}; do
            if [[ "${service}" == "${tps}" ]]; then
                is_third_party_service="true"
            fi
        done

        if [[ "${is_third_party_service}" == "false" ]]; then
            echo "${service}"
        fi
    done
}

function get_latest_app_tag() {
    owner=$1
    app=$2
    gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/${owner}/${app}/releases/latest | jq -r '.tag_name'
}

function fetch_updated_apps() {
    owner=$1
    echo "" > diff.json

    for app in $(get_docker_compose_services); do
        echo "Fetching ${app}..."
        latest_app_tag=$(get_latest_app_tag ${owner} ${app})
        latest_app_tag_dttm=$(gh api \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            /repos/${owner}/${app}/releases/latest | jq -r '.published_at')
        total_commits=$(gh api \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            /repos/${owner}/${app}/releases/latest | jq -r '.published_at')

        JQ_QUERY='{
            app: "'${app}'", 
            latest_tag: "'${latest_app_tag}'", 
            latest_tag_dttm: "'${latest_app_tag_dttm}'", 
            total_commits: .total_commits, 
            commits: [
                .commits[].commit | {
                    author: .author.name, 
                    date: .author.date, 
                    message: .message
                }
            ]
        }'

        gh api \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            /repos/${owner}/${app}/compare/${latest_app_tag}...dev \
            | jq -r "${JQ_QUERY}" >> diff.json
    done

    jq --slurp '. | sort_by(.app)' diff.json > __diff.json
    mv __diff.json diff.json
}