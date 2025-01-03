# !/bin/bash
set -e

ENVIRONMENT_NAME="dev"
GITHUB_OWNER="code-kern-ai"
REGISTRY_URL="registry.dev.kern.ai"
APP_NAME="hosted-inference-api"
DELETE_TAG="andhrelja"
HTTPS_USERNAME="andrea:Jasan91007"
DELETE_SINCE_DAYS=""

while getopts e:g:r:a:t:u:d: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        g) GITHUB_OWNER=${OPTARG};;
        r) REGISTRY_URL=${OPTARG};;
        a) APP_NAME=${OPTARG};;
        t) DELETE_TAG=${OPTARG};;
        u) HTTPS_USERNAME=${OPTARG};;
        d) DELETE_SINCE_DAYS=${OPTARG};;
    esac
done


# Delete images older than DELETE_SINCE_DAYS and exit 0
if [ -n "$DELETE_SINCE_DAYS" ]; then
    echo "::notice::Deleting images older than $DELETE_SINCE_DAYS days"
    repo_tags=$(curl -s -u $HTTPS_USERNAME https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/tags/list | jq -r '.tags[]')
    echo $repo_tags | while read -r tag ; do
        created=$(curl -s -u $HTTPS_USERNAME \
            https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$tag \
            | jq -r '.history[0].v1Compatibility' | jq -r '.created')
        
        created_date=$(date -d $created +%s)
        current_date=$(date +%s)
        days_since=$(( (current_date - created_date) / (60*60*24) ))
        
        if [ $days_since -gt $DELETE_SINCE_DAYS ]; then
            digest=$(curl -s -u $HTTPS_USERNAME \
                -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$tag \
                | sha256sum | cut -d ' ' -f 1)
            curl -X DELETE -u $HTTPS_USERNAME https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/sha256:$digest
            echo "::warning::deleted $APP_NAME:$tag, $days_since days old"
        else
            echo "$APP_NAME:$tag is $days_since days old"
        fi
    done
    exit 0
fi

# Delete a specific image and exit 0
if [ -n $DELETE_TAG ]; then
    manifest=$(curl -s -u $HTTPS_USERNAME \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/$DELETE_TAG)
    
    errors=$(echo $manifest | jq -r '.errors')
    if [ $errors != null ]; then
        echo "::error::$REGISTRY_URL/$APP_NAME:$DELETE_TAG => $(echo $errors | jq -r '.[0].code')"
        echo $manifest | jq -rc '.errors'
        exit 1
    fi
    
    digest=$(echo $manifest | sha256sum | cut -d ' ' -f 1)
    
    curl -X DELETE -u $HTTPS_USERNAME \
        https://$REGISTRY_URL/v2/$GITHUB_OWNER/$APP_NAME/manifests/sha256:$digest
    
    echo "::warning::deleted $REGISTRY_URL/$GITHUB_OWNER/$APP_NAME:$DELETE_TAG"
    exit 0
fi
