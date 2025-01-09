# !/bin/bash

trap "exit 1" TERM
export TOP_PID=$$

set -e

ENVIRONMENT_NAME="dev"
GITHUB_OWNER="code-kern-ai"
REGISTRY_URL="registry.dev.kern.ai"
APP_NAME="hosted-inference-api"
DELETE_TAG=""
HTTPS_USERNAME=""
DELETE_SINCE_DAYS=""
SSH_KEY=""
SSH_USER=""
SSH_HOST=""
FORCE_DELETE_REPO=false

while getopts e:g:r:a:t:u:d:p:s:h:f: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        g) GITHUB_OWNER=${OPTARG};;
        r) REGISTRY_URL=${OPTARG};;
        a) APP_NAME=${OPTARG};;
        t) DELETE_TAG=${OPTARG};;
        u) HTTPS_USERNAME=${OPTARG};;
        d) DELETE_SINCE_DAYS=${OPTARG};;
        p) SSH_KEY=${OPTARG};;
        s) SSH_USER=${OPTARG};;
        h) SSH_HOST=${OPTARG};;
        f) FORCE_DELETE_REPO=${OPTARG};;
    esac
done


function validate_image_tag() {
    manifest=$1
    image=$2
    errors=$(echo $manifest | jq -r '.errors')
    if [ "$errors" != "null" ]; then
        echo "::error::$image => $(echo $errors | jq -r '.[0].code')"
        echo $manifest | jq -rc '.errors'
        kill -s TERM $TOP_PID
    fi
}

function delete_since_days() {
    repo_tags=$1
    delete_since_days=$2

    while IFS= read -r tag; do
        manifest=$(curl -s -u $HTTPS_USERNAME \
            -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$tag)
        
        validate_image_tag "$manifest" "$REGISTRY_URL/$GITHUB_OWNER/$APP_NAME:$tag"

        created=$(curl -s -u $HTTPS_USERNAME \
            https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$tag \
            | jq -r '.history[0].v1Compatibility' | jq -r '.created')
        created_date=$(date -d $created +%s)
        current_date=$(date +%s)
        days_since=$(( (current_date - created_date) / (60*60*24) ))
        
        if [ $days_since -gt $delete_since_days ]; then
            digest=$(curl -s -u $HTTPS_USERNAME \
                -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$tag \
                | sha256sum | cut -d ' ' -f 1)
            curl -X DELETE -u $HTTPS_USERNAME -s https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/sha256:$digest
            echo "::warning::deleted $APP_NAME:$tag, $days_since days old"
        else
            echo "$APP_NAME:$tag is $days_since days old"
        fi
    done <<< "$repo_tags"
}

function force_delete_repo() {
    echo "$SSH_KEY" | ssh $SSH_USER@$SSH_HOST "cd ci-setup && docker exec -i -u root ci-setup_registry_1 bin/registry garbage-collect --delete-untagged /etc/docker/registry/config.yml"
    echo "$SSH_KEY" | ssh $SSH_USER@$SSH_HOST "cd ci-setup && docker exec -i -u root ci-setup_registry_1 rm -rf /var/lib/registry/docker/registry/v2/repositories/$GITHUB_OWNER/$APP_NAME"
    echo "::warning::force deleted $REGISTRY_URL/$GITHUB_OWNER/$APP_NAME"
}

# Main thread

## Force delete image repository and exit 0
if [ "$FORCE_DELETE_REPO" == "true" ]; then
    repo_tags=$(curl -s -u $HTTPS_USERNAME https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/tags/list | jq -r '.tags[]?')
    if [ -n "$repo_tags" ]; then
        echo "::error::found existing manifests for $REGISTRY_URL/$GITHUB_OWNER/$APP_NAME"
        exit 1
    fi

    delete_since_days "$repo_tags" "0"
    force_delete_repo
    exit 0
fi

## Delete images older than DELETE_SINCE_DAYS and exit 0
if [ -n "$DELETE_SINCE_DAYS" ]; then
    echo "::notice::Deleting images older than $DELETE_SINCE_DAYS days"
    repo_tags=$(curl -s -u $HTTPS_USERNAME https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/tags/list | jq -r '.tags[]?')
    if [ -z "$repo_tags" ]; then
        echo "::notice::No images found for $APP_NAME"
        exit 0
    fi

    delete_since_days "$repo_tags" "$DELETE_SINCE_DAYS"
    exit 0
fi

## Delete a specific image and exit 0
if [ -n $DELETE_TAG ]; then
    manifest=$(curl -s -u $HTTPS_USERNAME \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$DELETE_TAG)
    
    validate_image_tag "$manifest" "$REGISTRY_URL/$GITHUB_OWNER/$APP_NAME:$DELETE_TAG"

    digest=$(curl -s -u $HTTPS_USERNAME \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$DELETE_TAG \
        | sha256sum | cut -d ' ' -f 1)
    curl -X DELETE -u $HTTPS_USERNAME -s \
        https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/sha256:$digest
    
    echo "::warning::deleted $REGISTRY_URL/$GITHUB_OWNER/$APP_NAME:$DELETE_TAG"
    exit 0
fi

# End of main thread