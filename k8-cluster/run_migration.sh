# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_MANIFEST_PATH=""
MIGRATION_JOB_NAME=""

while getopts n:p:j: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        p) KUBERNETES_MANIFEST_PATH=${OPTARG};;
        j) MIGRATION_JOB_NAME=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

kubectl delete job $MIGRATION_JOB_NAME
bash cicd-deployment-scripts/k8-cluster/apply.sh \
    -n $KUBERNETES_NAMESPACE \
    -p $KUBERNETES_MANIFEST_PATH
