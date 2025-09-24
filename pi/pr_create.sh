# !/bin/bash
set -e

BASE_REF="dev"
HEAD_REF="parent-images"
PR_TITLE="ci(pi): update parent image"
REPOSITORY_OWNER="code-kern-ai"
REPOSITORY_NAME=""
RELEASE_TAG=""
APP=""

while getopts b:h:t:o:r:n:a: flag
do
    case "${flag}" in
        b) BASE_REF=${OPTARG};;
        h) HEAD_REF=${OPTARG};;
        t) PR_TITLE=${OPTARG};;
        o) REPOSITORY_OWNER=${OPTARG};;
        r) REPOSITORY_NAME=${OPTARG};;
        n) RELEASE_TAG=${OPTARG};;
        a) APP=${OPTARG};;
    esac
done

EXISTING_PR_NUMBER=""
EXISTING_PR_BODY=$(gh pr list --base $BASE_REF --head $HEAD_REF --json body --jq '.[].body')

if [ -z "$EXISTING_PR_BODY" ]; then
    PR_BODY=$(cat <<EOF
Automated parent image release for:
- https://github.com/$REPOSITORY_OWNER/$REPOSITORY_NAME/releases/tag/$RELEASE_TAG
EOF
)
    gh pr create \
        --base $BASE_REF \
        --head $HEAD_REF \
        --title "$PR_TITLE" \
        --body "$PR_BODY" \
        --draft \
        --repo $REPOSITORY_OWNER/$APP || true
        # --reviewer $REPOSITORY_OWNER/devops-admin \

else
    PR_BODY=$(cat <<EOF
$EXISTING_PR_BODY
- https://github.com/$REPOSITORY_OWNER/$REPOSITORY_NAME/releases/tag/$RELEASE_TAG
EOF
)
    EXISTING_PR_NUMBER=$(gh pr list \
        --base $BASE_REF \
        --head $HEAD_REF \
        --repo $REPOSITORY_OWNER/$APP \
        --json number --jq '.[].number')
    gh pr edit $EXISTING_PR_NUMBER \
        --body "$PR_BODY" \
        --repo $REPOSITORY_OWNER/$APP || true
fi

