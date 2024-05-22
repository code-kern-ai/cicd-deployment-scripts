# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
AZURE_CONTAINER_REGISTRY=""
TEST_CMD=""

while getopts n:d:r:t: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) TEST_CMD=${OPTARG};;
    esac
done

KUBERNETES_POD_NAME=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[] | .metadata.name')
KUBERNETES_POD_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[] | .spec.containers[0].image')

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:test
echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:test"

set +e
exitcode=0
kubectl exec -it $KUBERNETES_POD_NAME -- $TEST_CMD
exitcode=$?
set -e

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_IMAGE}
echo "::notice::using ${KUBERNETES_POD_IMAGE}"

exit $exitcode
