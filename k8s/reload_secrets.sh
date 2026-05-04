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
    ["cognition-gateway"]="cg-gateway" \
    ["cognition-pdf2md"]="cg-gateway" \
    ["cognition-task-master"]="cg-task-master" \
    ["kratos"]="kratos" \
    ["oathkeeper"]="oathkeeper" \
    ["object-storage"]="obj-storage" \
    ["platform-monitoring"]="plfm-monitor" \
    ["refinery-embedder"]="rf-embedder" \
    ["refinery-gateway"]="rf-gateway" \
    ["refinery-gateway-proxy"]="rf-gw-proxy" \
    ["refinery-model-provider"]="rf-mdl-prvd" \
    ["refinery-neural-search"]="rf-nrl-search" \
    ["refinery-tokenizer"]="rf-tokenizer" \
    ["refinery-weak-supervisor"]="rf-weak-supvsr" \
    ["refinery-websocket"]="rf-websocket" \
)

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

kubectl delete secret ${secret_rename_mapping[$KUBERNETES_DEPLOYMENT_NAME]}
kubectl rollout restart deployment ${KUBERNETES_DEPLOYMENT_NAME}
kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}

echo "::notice::Reloaded ${KUBERNETES_DEPLOYMENT_NAME} secret (${secret_rename_mapping[$KUBERNETES_DEPLOYMENT_NAME]}) successfully"
