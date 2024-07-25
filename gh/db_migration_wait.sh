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


RUNNING_DB_UPGRADE_WORKFLOW=""
RUNNING_DB_UPGRADE_WORKFLOW_ID=$(gh run list \
    --json conclusion,databaseId,headBranch,status,workflowName \
    --jq ".[] | select(.workflowName==\"$WAIT_WORKFLOW_NAME\" and .status!=\"completed\" and .headBranch!=\"$ENVIRONMENT_NAME\" and .databaseId!=\"$CURRENT_WORKFLOW_DATABASE_ID\") | .databaseId" \
    --repo code-kern-ai/refinery-gateway)

# while [ -z $RUNNING_DB_UPGRADE_WORKFLOW ]; do
#     RUNNING_DB_UPGRADE_WORKFLOW=$(gh run list \
#         --json conclusion,databaseId,headBranch,status,workflowName \
#         --jq '.[] | select(.workflowName=="'$WAIT_WORKFLOW_NAME'" and .status!="completed" and .headBranch!="'$ENVIRONMENT_NAME'" and .databaseId!="'$CURRENT_WORKFLOW_DATABASE_ID'")' \
#         --repo code-kern-ai/refinery-gateway)
#     echo "Waiting for running db upgrade workflow to complete ..."
#     if [ -z $RUNNING_DB_UPGRADE_WORKFLOW ]; then
#         sleep 5
#     fi
# done
gh run watch $RUNNING_DB_UPGRADE_WORKFLOW_ID --repo code-kern-ai/refinery-gateway