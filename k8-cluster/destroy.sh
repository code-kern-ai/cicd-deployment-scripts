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

KUBERNETES_JOBS=$(kubectl get jobs --output json | jq -r '.items[].metadata.name')
KUBERNETES_DEPLOYMENTS=$(kubectl get deployment --output json \
    | jq -r '.items[] | select(.metadata.name as $name 
        | ["caddy", "docker"] 
        | index($name) | not) 
    | .metadata.name')
KUBERNETES_SERVICES=$(kubectl get service --output json \
    | jq -r '.items[] | select(.metadata.name as $name 
        | ["caddy", "docker"] 
        | index($name) | not) 
    | .metadata.name')

for job in $KUBERNETES_JOBS; do
  kubectl delete job $job
done

for deploy in $KUBERNETES_DEPLOYMENTS; do
  kubectl delete deployment $deploy
done

for svc in $KUBERNETES_SERVICES; do
  kubectl delete service $svc
done
