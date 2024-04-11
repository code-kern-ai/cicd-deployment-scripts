# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
AZURE_CONTAINER_REGISTRY=""
AZURE_IMAGE_TAG=""

while getopts n:r:t: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) AZURE_IMAGE_TAG=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

DOCKER_POD=$(kubectl get pods -l app=docker -o jsonpath='{.items[0].metadata.name}')

PULL_IMAGE_NAMES=(
    "refinery-ac-exec-env"
    "refinery-lf-exec-env"
    "refinery-ml-exec-env"
    "refinery-record-ide-env"
    "workflow-code-exec-env"
)
total_images=${#PULL_IMAGE_NAMES[@]}

i=0
for IMAGE_NAME in "${PULL_IMAGE_NAMES[@]}"; do
    echo "Pulling image: $AZURE_CONTAINER_REGISTRY/$image:$AZURE_IMAGE_TAG"
    kubectl exec $DOCKER_POD -c docker -- /bin/sh -c "docker pull $AZURE_CONTAINER_REGISTRY/$IMAGE_NAME:$AZURE_IMAGE_TAG"
    i=$((i+1))
    echo "::notice::Pushed $i of $total_images images"
done
