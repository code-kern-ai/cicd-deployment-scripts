# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
ENVIRONMENT_NAME=""

while getopts n:e: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        e) ENVIRONMENT_NAME=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

kubectl delete --kustomize cluster/$ENVIRONMENT_NAME