# !/bin/bash
set -e

BASE_REF="dev"
HEAD_REF="automated-release-dev"
PR_TITLE="ci: automated-release-dev"
REPOSITORY_OWNER="code-kern-ai"
REPOSITORY_NAME=""
POD_IMAGE_NAME=""
KUBERNETES_CLUSTER_REPO_NAME=""

while getopts b:h:t:o:r:p:k: flag
do
    case "${flag}" in
        b) BASE_REF=${OPTARG};;
        h) HEAD_REF=${OPTARG};;
        t) PR_TITLE=${OPTARG};;
        o) REPOSITORY_OWNER=${OPTARG};;
        r) REPOSITORY_NAME=${OPTARG};;
        p) POD_IMAGE_NAME=${OPTARG};;
        k) KUBERNETES_CLUSTER_REPO_NAME=${OPTARG};;
    esac
done

EXISTING_PR_NUMBER=""
EXISTING_PR_BODY=$(gh pr list --base $BASE_REF --head $HEAD_REF --json body --jq '.[].body')

if [ -z "$EXISTING_PR_BODY" ]; then
    PR_BODY=$(cat <<EOF
Automated $BASE_REF release:
- $POD_IMAGE_NAME
EOF
)
    gh pr create \
        --base $BASE_REF \
        --head $HEAD_REF \
        --title "$PR_TITLE" \
        --body "$PR_BODY" \
        --draft \
        --repo $REPOSITORY_OWNER/$KUBERNETES_CLUSTER_REPO_NAME
        # --reviewer $REPOSITORY_OWNER/devops-admin \

else
    EXISTING_PR_NUMBER=$(gh pr list \
        --base $BASE_REF \
        --head $HEAD_REF \
        --repo $REPOSITORY_OWNER/$KUBERNETES_CLUSTER_REPO_NAME \
        --json number --jq '.[].number')
    PR_BODY=$(cat <<EOF
$EXISTING_PR_BODY
- $POD_IMAGE_NAME
EOF
)
    gh pr edit $EXISTING_PR_NUMBER \
        --body "$PR_BODY" \
        --repo $REPOSITORY_OWNER/$KUBERNETES_CLUSTER_REPO_NAME || true
fi

