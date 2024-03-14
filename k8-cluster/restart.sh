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
KUBERNETES_DEPLOYMENTS=$(kubectl get deployment --output json \
    | jq -r '.items[] | select(.metadata.name as $name 
        | ["caddy", "docker"] 
        | index($name) | not) 
    | .metadata.name')

for deploy in $KUBERNETES_DEPLOYMENTS; do
  kubectl rollout restart deployment $deploy
done
