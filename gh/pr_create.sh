# !/bin/bash
set -e

BASE_REF="dev"
HEAD_REF="automated-release-dev"
PR_TITLE="ci: automated-release-dev"
REPOSITORY_OWNER="code-kern-ai"
REPOSITORY_NAME=""
REPOSITORY_PR_NUMBER=""
KUBERNETES_CLUSTER_REPO_NAME=""

while getopts b:h:t:o:r:n:k: flag
do
    case "${flag}" in
        b) BASE_REF=${OPTARG};;
        h) HEAD_REF=${OPTARG};;
        t) PR_TITLE=${OPTARG};;
        o) REPOSITORY_OWNER=${OPTARG};;
        r) REPOSITORY_NAME=${OPTARG};;
        n) REPOSITORY_PR_NUMBER=${OPTARG};;
        k) KUBERNETES_CLUSTER_REPO_NAME=${OPTARG};;
    esac
done

EXISTING_PR_NUMBER=""
EXISTING_PR_BODY=$(gh pr list --base $BASE_REF --head $HEAD_REF --json body --jq '.[].body')

if [ -z "$EXISTING_PR_BODY" ]; then
    if [[ $REPOSITORY_PR_NUMBER =~ ^v(0|[1-9]*)\.(0|[1-9]*)\.(0|[1-9]*) ]]; then
        PR_BODY=$(cat <<EOF
Automated $BASE_REF release for:
- https://github.com/$REPOSITORY_OWNER/$REPOSITORY_NAME/releases/tag/$REPOSITORY_PR_NUMBER
EOF
)
    else
        PR_BODY=$(cat <<EOF
Automated $BASE_REF release for:
- https://github.com/$REPOSITORY_OWNER/$REPOSITORY_NAME/pull/$REPOSITORY_PR_NUMBER
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
- https://github.com/$REPOSITORY_OWNER/$REPOSITORY_NAME/pull/$REPOSITORY_PR_NUMBER
EOF
)
    gh pr edit $EXISTING_PR_NUMBER \
        --body "$PR_BODY" \
        --repo $REPOSITORY_OWNER/$KUBERNETES_CLUSTER_REPO_NAME || true
fi

