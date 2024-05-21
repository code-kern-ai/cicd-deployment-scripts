# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_MANIFEST_PATH=""

while getopts n:p: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        p) KUBERNETES_MANIFEST_PATH=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

# kubectl apply -k $KUBERNETES_MANIFEST_PATH | grep -E 'created|configured' || true
kubectl kustomize $KUBERNETES_MANIFEST_PATH --output apply.yml
cat apply.yml
