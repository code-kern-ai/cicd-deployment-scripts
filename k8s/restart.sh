# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""

while getopts n:d: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

kubectl rollout restart deployment ${KUBERNETES_DEPLOYMENT_NAME}
kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}

echo "::notice::Restarted ${KUBERNETES_DEPLOYMENT_NAME} successfully"
