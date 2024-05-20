# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""

while getopts n: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

kubectl delete namespace $KUBERNETES_NAMESPACE
kubectl delete persistentvolumeclaims --all
kubectl delete persistentvolumes --all
kubectl delete storageclass --all
