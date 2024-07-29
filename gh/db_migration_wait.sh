# !/bin/bash
set -e

ENVIRONMENT_NAME="dev"
WAIT_WORKFLOW_NAME="K8: Test"
CURRENT_WORKFLOW_DATABASE_ID=""

while getopts e:w:i: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        w) WAIT_WORKFLOW_NAME=${OPTARG};;
        i) CURRENT_WORKFLOW_DATABASE_ID=${OPTARG};;
    esac
done


RUNNING_DB_UPGRADE_WORKFLOW_ID=null


while [ -n "$RUNNING_DB_UPGRADE_WORKFLOW_ID" ]; do
    RUNNING_DB_UPGRADE_WORKFLOW_ID=$(gh run list \
        --json conclusion,databaseId,headBranch,status,workflowName \
        --jq ".[] | select(.workflowName==\"$WAIT_WORKFLOW_NAME\" and .status!=\"completed\" and .headBranch!=\"$ENVIRONMENT_NAME\" and .databaseId!=$CURRENT_WORKFLOW_DATABASE_ID) | .databaseId" \
        --repo code-kern-ai/refinery-gateway)
    
    if [ -n "$RUNNING_DB_UPGRADE_WORKFLOW_ID" ]; then
        RUNNING_DB_UPGRADE_WORKFLOW_URL=$(gh run list \
            --json databaseId,url \
            --jq ".[] | select(.databaseId==$RUNNING_DB_UPGRADE_WORKFLOW_ID) | .url" \
            --repo code-kern-ai/refinery-gateway)
        echo "Waiting for running db upgrade workflow to complete: $RUNNING_DB_UPGRADE_WORKFLOW_URL"
        gh run watch $RUNNING_DB_UPGRADE_WORKFLOW_ID --interval 10 --repo code-kern-ai/refinery-gateway 1> /dev/null
    fi
done

echo "::notice::Running db upgrade workflow completed"