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

declare -A secret_rename_mapping=( \
    ["admin-dashboard"]="none" \
    ["cognition-gateway"]="cg-gateway" \
    ["cognition-pdf2md"]="cg-gateway" \
    ["cognition-task-master"]="cg-task-master" \
    ["cognition-ui"]="none" \
    ["refinery-authorizer"]="none" \
    ["refinery-embedder"]="rf-embedder" \
    ["refinery-entry"]="none" \
    ["refinery-gateway"]="rf-gateway" \
    ["refinery-gateway-proxy"]="rf-gw-proxy" \
    ["refinery-model-provider"]="rf-mdl-prvd" \
    ["refinery-neural-search"]="rf-nrl-search" \
    ["refinery-tokenizer"]="rf-tokenizer" \
    ["refinery-ui"]="none" \
    ["refinery-updater"]="rf-updater" \
    ["refinery-weak-supervisor"]="rf-weak-supvsr" \
    ["refinery-websocket"]="rf-websocket" \
)

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

KUBERNETES_SERVICE_NAME=$KUBERNETES_DEPLOYMENT_NAME
KUBERNETES_SECRET_NAME=${secret_rename_mapping[$KUBERNETES_DEPLOYMENT_NAME]}

kubectl delete deployment $KUBERNETES_DEPLOYMENT_NAME
kubectl delete service $KUBERNETES_SERVICE_NAME

if [ "$KUBERNETES_SECRET_NAME" != "none" ]; then
    kubectl delete secret $KUBERNETES_SECRET_NAME
fi