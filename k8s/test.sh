# !/bin/bash
set -e

AZURE_CONTAINER_REGISTRY=""
KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
REFINERY_DEPLOYMENT_NAME="refinery-gateway"
TEST_IMAGE_TAG=""
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


REFINERY_ALEMBIC_VERSION=""
KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=""

KUBERNETES_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')

REFINERY_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${REFINERY_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')

REFINERY_IMAGE_TAG_EXISTS=$(az acr repository show --name ${AZURE_CONTAINER_REGISTRY} --image ${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 2> /dev/null || true)


if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
    echo "::group::Upgrade alembic migrations for test"
    if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "gates-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "hosted-inference-api" ]; then
        if [ -n "$REFINERY_IMAGE_TAG_EXISTS" ]; then
            REFINERY_ALEMBIC_VERSION=$(kubectl exec -i deployment/${REFINERY_DEPLOYMENT_NAME} -c ${REFINERY_DEPLOYMENT_NAME} -- alembic current)
            REFINERY_ALEMBIC_VERSION=${REFINERY_ALEMBIC_VERSION:0:12}
            echo "::warning::current $REFINERY_DEPLOYMENT_NAME alembic version: $REFINERY_ALEMBIC_VERSION"
            kubectl set image deployment/${REFINERY_DEPLOYMENT_NAME} \
                ${REFINERY_DEPLOYMENT_NAME}-migrate=${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} \
                ${REFINERY_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 1> /dev/null
            kubectl rollout status deployment ${REFINERY_DEPLOYMENT_NAME}
            echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
            _REFINERY_ALEMBIC_VERSION=$(kubectl exec -i deployment/${REFINERY_DEPLOYMENT_NAME} -c ${REFINERY_DEPLOYMENT_NAME} -- alembic current)
            echo "::warning::upgraded $REFINERY_DEPLOYMENT_NAME alembic version: $_REFINERY_ALEMBIC_VERSION"
        fi
    else
        KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=$(kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c ${KUBERNETES_DEPLOYMENT_NAME} -- alembic current)
        KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=${KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION:0:12}
        echo "::warning::current $KUBERNETES_DEPLOYMENT_NAME alembic version: $KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION"
        kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} \
            ${KUBERNETES_DEPLOYMENT_NAME}-migrate=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} \
            ${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 1> /dev/null
        kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}
        echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
        _KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=$(kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c ${KUBERNETES_DEPLOYMENT_NAME} -- alembic current)
        echo "::warning::upgraded $KUBERNETES_DEPLOYMENT_NAME alembic version: $_KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION"
    fi
    echo "::endgroup::"
fi

echo "::group::Set test image: ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 1> /dev/null
kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}
echo "::notice::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
echo "::endgroup::"

echo "::group::Running test command: kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- '$TEST_CMD'"
set +e
exitcode=0
kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- ''$TEST_CMD''
exitcode=$?
set -e
echo "::endgroup::"

if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
    echo "::group::Downgrade alembic migrations"
    if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "gates-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "hosted-inference-api" ]; then
        if [ -n "$REFINERY_IMAGE_TAG_EXISTS" ]; then
            kubectl exec -i deployment/${REFINERY_DEPLOYMENT_NAME} -c ${REFINERY_DEPLOYMENT_NAME} -- alembic downgrade $REFINERY_ALEMBIC_VERSION
            echo "::warning::downgraded $REFINERY_DEPLOYMENT_NAME alembic version to $REFINERY_ALEMBIC_VERSION"
            kubectl set image deployment/${REFINERY_DEPLOYMENT_NAME} \
                ${REFINERY_DEPLOYMENT_NAME}-migrate=${REFINERY_POD_EXISTING_IMAGE} \
                ${REFINERY_DEPLOYMENT_NAME}=${REFINERY_POD_EXISTING_IMAGE}
            kubectl rollout status deployment ${REFINERY_DEPLOYMENT_NAME}
            echo "::warning::using ${REFINERY_POD_EXISTING_IMAGE}"
        fi
    else
        kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c ${KUBERNETES_DEPLOYMENT_NAME} -- alembic downgrade $KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION
        echo "::warning::downgraded $KUBERNETES_DEPLOYMENT_NAME alembic version to $KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION"
        kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} \
            ${KUBERNETES_DEPLOYMENT_NAME}-migrate=${KUBERNETES_POD_EXISTING_IMAGE} \
            ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_EXISTING_IMAGE}
        kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}
        echo "::warning::using ${KUBERNETES_POD_EXISTING_IMAGE}"
    fi
    echo "::endgroup::"
fi

echo "::group::Revert test image: ${KUBERNETES_POD_EXISTING_IMAGE}"
kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_EXISTING_IMAGE} 1> /dev/null
kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}
echo "::notice::using ${KUBERNETES_POD_EXISTING_IMAGE}"
echo "::endgroup::"

exit $exitcode
