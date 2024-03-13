# !/bin/bash
set -e

KUBERNETES_DEPLOYMENTS=$(kubectl get deployment --output json | jq -r '.items[].metadata.name')
KUBERNETES_SERVICES=$(kubectl get service --output json | jq -r '.items[].metadata.name')

for deploy in $KUBERNETES_DEPLOYMENTS; do
  kubectl delete deployment $deploy
done

for svc in $KUBERNETES_SERVICES; do
  kubectl delete service $svc
done
