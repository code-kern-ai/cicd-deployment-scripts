# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
KUBERNETES_MANIFEST_FILE_PATH=""
AZURE_CONTAINER_REGISTRY=""
IMAGE_TAG=""

while getopts n:d:r:t:f: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        f) KUBERNETES_MANIFEST_FILE_PATH=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) IMAGE_TAG=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

KUBERNETES_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')
KUBERNETES_POD_NEW_IMAGE="${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${IMAGE_TAG}"

echo "$(sed "s|${KUBERNETES_POD_EXISTING_IMAGE}|${KUBERNETES_POD_NEW_IMAGE}|g" ${KUBERNETES_MANIFEST_FILE_PATH})" > $KUBERNETES_MANIFEST_FILE_PATH
echo "::notice::Deployment manifest updated with new image: ${KUBERNETES_POD_NEW_IMAGE}"
