# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
PR_NUMBER=""
DEPLOY_SUCCESSFUL=true

while getopts n:p: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        p) PR_NUMBER=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

UPDATED_FILES=$(gh pr diff $PR_NUMBER --name-only)
while IFS= read -r file; do
    if [[ $file != apps/* ]]; then
        continue
    fi

    deploy=$(echo "$file" | cut -d/ -f 2)

    set +e
    kubectl rollout status deploy $deploy --timeout 30s
    if [ $? -ne 0 ]; then
        echo "::error::Deployment $deploy failed to rollout"
        DEPLOY_SUCCESSFUL=false
    fi
    set -e
    
done <<< "$UPDATED_FILES"

if [ $DEPLOY_SUCCESSFUL = true ]; then
    echo "::notice::Automated release successful"
else
    echo "::error::Automated release failed"
    exit 1
fi