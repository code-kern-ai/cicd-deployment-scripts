# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
GITHUB_HEAD_REF=""
AZURE_CONTAINER_REGISTRY=""
TEST_CMD=""

while getopts n:d:h:r:t: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        h) GITHUB_HEAD_REF=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) TEST_CMD=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

KUBERNETES_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[] | .spec.containers[0].image')

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:test-${GITHUB_HEAD_REF}
echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:test-${GITHUB_HEAD_REF}"

kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}

set +e
exitcode=0
kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- "$TEST_CMD"
exitcode=$?
set -e

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_EXISTING_IMAGE}
echo "::notice::using ${KUBERNETES_POD_EXISTING_IMAGE}"

exit $exitcode
