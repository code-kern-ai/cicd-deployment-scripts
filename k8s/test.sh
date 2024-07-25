# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
TEST_IMAGE_TAG=""
AZURE_CONTAINER_REGISTRY=""
TEST_CMD=""

while getopts n:d:h:r:t:c: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        t) TEST_IMAGE_TAG=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        c) TEST_CMD=${OPTARG};;
    esac
done

echo "::group::Kubernetes Context"
kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""
echo "::endgroup::"


echo "::group::Upgrade deployment image"
KUBERNETES_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}
kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}
echo "::endgroup::"


echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"


echo "::group::Running test command: kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- '$TEST_CMD'"
set +e
exitcode=0
kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- ''$TEST_CMD''
exitcode=$?
set -e
echo "::endgroup::"

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_EXISTING_IMAGE}

echo "::notice::using ${KUBERNETES_POD_EXISTING_IMAGE}"

exit $exitcode
