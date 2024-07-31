# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
TEST_IMAGE_TAG=""
AZURE_CONTAINER_REGISTRY=""
TEST_CMD=""
ENABLE_ALEMBIC_MIGRATIONS="false"

while getopts n:d:h:r:t:c:a: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        t) TEST_IMAGE_TAG=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        c) TEST_CMD=${OPTARG};;
        a) ENABLE_ALEMBIC_MIGRATIONS=${OPTARG};;
    esac
done

echo "::group::Kubernetes Context"
kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""
echo "::endgroup::"


KUBERNETES_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')

REFINERY_DEPLOYMENT_NAME="refinery-gateway"
REFINERY_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${REFINERY_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')
REFINERY_IMAGE_TAG_EXISTS=$(az acr repository show --name ${AZURE_CONTAINER_REGISTRY} --image ${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 2> /dev/null || true)


if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
    echo "::group::Preparing alembic migrations for test"
    if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "gates-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "hosted-inference-api" ]; then
        if [ -n "$REFINERY_IMAGE_TAG_EXISTS" ]; then
            kubectl set image deployment/${REFINERY_DEPLOYMENT_NAME} \
                ${REFINERY_DEPLOYMENT_NAME}-migrate=${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} \
                ${REFINERY_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}
            kubectl rollout status deployment ${REFINERY_DEPLOYMENT_NAME}
        fi
    else
        kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}-migrate=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}
    fi
    echo "::endgroup::"
fi

echo "::group::Upgrade deployment image"
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
kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_EXISTING_IMAGE}
echo "::endgroup::"

if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
    echo "::group::Reverting alembic migrations for test"
    if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "gates-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "hosted-inference-api" ]; then
        if [ -n "$REFINERY_IMAGE_TAG_EXISTS" ]; then
            kubectl set image deployment/${REFINERY_DEPLOYMENT_NAME} \
                ${REFINERY_DEPLOYMENT_NAME}-migrate=${REFINERY_POD_EXISTING_IMAGE} \
                ${REFINERY_DEPLOYMENT_NAME}=${REFINERY_POD_EXISTING_IMAGE}
            kubectl rollout status deployment ${REFINERY_DEPLOYMENT_NAME}
        fi
    else
        kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}-migrate=${REFINERY_POD_EXISTING_IMAGE}
    fi
    echo "::endgroup::"
fi

echo "::notice::using ${KUBERNETES_POD_EXISTING_IMAGE}"

exit $exitcode
