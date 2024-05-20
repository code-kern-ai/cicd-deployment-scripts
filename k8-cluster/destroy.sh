# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_FILE_SHARE=""

while getopts n:s:f: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        s) AZURE_STORAGE_ACCOUNT=${OPTARG};;
        f) AZURE_STORAGE_FILE_SHARE=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""



kubectl delete namespace $KUBERNETES_NAMESPACE
kubectl delete persistentvolumeclaims --all
kubectl delete persistentvolumes --all
kubectl delete storageclass --all
