# !/bin/bash

trap "exit 1" TERM
export TOP_PID=$$

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


REFINERY_ALEMBIC_VERSION=""
KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=""

REFINERY_IMAGE_TAG_EXISTS=$(az acr repository show --name ${AZURE_CONTAINER_REGISTRY} --image ${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 2> /dev/null || true)

downgrade_alembic_migrations() {
    echo "::group::Downgrade alembic migrations"
    if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "gates-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "hosted-inference-api" ]; then
        if [ -n "$REFINERY_IMAGE_TAG_EXISTS" ]; then
            set +e
            kubectl exec -i deployment/test-${REFINERY_DEPLOYMENT_NAME} -c test-${REFINERY_DEPLOYMENT_NAME} -- alembic downgrade $REFINERY_ALEMBIC_VERSION
            if [ "$?" != "0" ]; then
                echo "::error::Alembic downgrade failed. Please update your code to support downgrading the current alembic version"
                kubectl delete --kustomize apps/${REFINERY_DEPLOYMENT_NAME}/test
                kubectl delete --kustomize infrastructure/test
                exit 1
            else
                echo "::notice::downgraded test-$REFINERY_DEPLOYMENT_NAME alembic version to $REFINERY_ALEMBIC_VERSION"
            fi
            set -e
        fi
        kubectl delete --kustomize apps/${REFINERY_DEPLOYMENT_NAME}/test
    else
        set +e
        kubectl exec -i deployment/test-${KUBERNETES_DEPLOYMENT_NAME} -c test-${KUBERNETES_DEPLOYMENT_NAME} -- alembic downgrade $KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION
        if [ "$?" != "0" ]; then
            echo "::error::Alembic downgrade failed. Please update your code to support downgrading the current alembic version"
            kubectl delete --kustomize apps/${REFINERY_DEPLOYMENT_NAME}/test
            kubectl delete --kustomize infrastructure/test
            exit 1
        else
            echo "::notice::downgraded test-$KUBERNETES_DEPLOYMENT_NAME alembic version to $REFINERY_ALEMBIC_VERSION"
        fi
        set -e
    fi
    echo "::endgroup::"
}

__safe_migration_rollout() {
    deploy=$1

    set +e
    exitcode=0
    kubectl rollout status deployment $deploy --timeout 2m 2> /dev/null
    exitcode=$?
    set -e

    if [ "$exitcode" != "0" ]; then
        echo "::error::Alembic migration failure. See logs for details"
        failed_pod_name=$(kubectl get pod \
            --selector app=$deploy \
            --field-selector status.phase!=Running \
            --output jsonpath='{.items[?(@.metadata.labels.app=="'$deploy'")].metadata.name}')
        kubectl logs $failed_pod_name -c $deploy-migrate || true
        if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
            downgrade_alembic_migrations
        fi
        kill -s TERM $TOP_PID
    fi
}

upgrade_alembic_migrations() {
    echo "::group::Upgrade alembic migrations for test"
    if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-gateway" ] && [ $KUBERNETES_DEPLOYMENT_NAME != "hosted-inference-api" ]; then
        kubectl apply --kustomize apps/${REFINERY_DEPLOYMENT_NAME}/test
        __safe_migration_rollout test-${REFINERY_DEPLOYMENT_NAME}
        echo "Applied test-${REFINERY_DEPLOYMENT_NAME} deployment"
        
        kubectl apply --kustomize apps/${KUBERNETES_DEPLOYMENT_NAME}/test
        __safe_migration_rollout test-${KUBERNETES_DEPLOYMENT_NAME}
        echo "Applied test-${KUBERNETES_DEPLOYMENT_NAME} deployment"

        REFINERY_ALEMBIC_VERSION=$(kubectl exec -i deployment/test-${REFINERY_DEPLOYMENT_NAME} -c test-${REFINERY_DEPLOYMENT_NAME} -- alembic current)
        REFINERY_ALEMBIC_VERSION=${REFINERY_ALEMBIC_VERSION:0:12}
        echo "::warning::current $REFINERY_DEPLOYMENT_NAME alembic version: $REFINERY_ALEMBIC_VERSION"
        if [ -n "$REFINERY_IMAGE_TAG_EXISTS" ]; then
            kubectl set image deployment/test-${REFINERY_DEPLOYMENT_NAME} \
                test-${REFINERY_DEPLOYMENT_NAME}-migrate=${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} \
                test-${REFINERY_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 1> /dev/null
            __safe_migration_rollout test-${REFINERY_DEPLOYMENT_NAME}
            echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${REFINERY_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
        fi
        _REFINERY_ALEMBIC_VERSION=$(kubectl exec -i deployment/test-${REFINERY_DEPLOYMENT_NAME} -c test-${REFINERY_DEPLOYMENT_NAME} -- alembic current)
        echo "::warning::upgraded $REFINERY_DEPLOYMENT_NAME alembic version: $_REFINERY_ALEMBIC_VERSION"
    else
        kubectl apply --kustomize apps/${KUBERNETES_DEPLOYMENT_NAME}/test
        __safe_migration_rollout test-${KUBERNETES_DEPLOYMENT_NAME}
        echo "Applied test-${KUBERNETES_DEPLOYMENT_NAME} deployment"

        KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=$(kubectl exec -i deployment/test-${KUBERNETES_DEPLOYMENT_NAME} -c test-${KUBERNETES_DEPLOYMENT_NAME} -- alembic current)
        KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=${KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION:0:12}
        echo "::warning::current $KUBERNETES_DEPLOYMENT_NAME alembic version: $KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION"
        kubectl set image deployment/test-${KUBERNETES_DEPLOYMENT_NAME} \
            test-${KUBERNETES_DEPLOYMENT_NAME}-migrate=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} \
            test-${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 1> /dev/null
        __safe_migration_rollout test-${KUBERNETES_DEPLOYMENT_NAME}
        echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
        _KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION=$(kubectl exec -i deployment/test-${KUBERNETES_DEPLOYMENT_NAME} -c test-${KUBERNETES_DEPLOYMENT_NAME} -- alembic current)
        echo "::warning::upgraded $KUBERNETES_DEPLOYMENT_NAME alembic version: $_KUBERNETES_DEPLOYMENT_ALEMBIC_VERSION"
    fi
    echo "::endgroup::"
}

echo "::group::Kubernetes Context & Test Infrastructure"
kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""
kubectl apply --kustomize infrastructure/test
__safe_migration_rollout test-postgres
until kubectl exec -i deployment/test-postgres -- sh -c pg_isready; do
    echo "Waiting for postgres to be ready..."
    sleep 3
done
kubectl exec -i deployment/test-postgres -- sh -c "psql -U postgres -c 'DROP DATABASE IF EXISTS refinery;'"
kubectl exec -i deployment/test-postgres -- sh -c "psql -U postgres -c '$(cat infrastructure/test/deployment/assets/init.sql)'"
echo "::endgroup::"


if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
    upgrade_alembic_migrations
else
    kubectl apply --kustomize apps/${KUBERNETES_DEPLOYMENT_NAME}/test
    __safe_migration_rollout test-${KUBERNETES_DEPLOYMENT_NAME}
    echo "Applied test-${KUBERNETES_DEPLOYMENT_NAME} deployment"
fi

echo "::group::Set test image: ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
kubectl set image deployment/test-${KUBERNETES_DEPLOYMENT_NAME} test-${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG} 1> /dev/null
__safe_migration_rollout test-${KUBERNETES_DEPLOYMENT_NAME}
echo "::notice::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"
echo "::endgroup::"

echo "::group::Running test command: kubectl exec -i deployment/test-${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- '$TEST_CMD'"
set +e
exitcode=0
kubectl exec -i deployment/test-${KUBERNETES_DEPLOYMENT_NAME} -c test-$KUBERNETES_DEPLOYMENT_NAME -- ''$TEST_CMD''
exitcode=$?
set -e
echo "::endgroup::"

if [ "$ENABLE_ALEMBIC_MIGRATIONS" = "true" ]; then
    downgrade_alembic_migrations
fi

echo "::group::Delete Test Infrastructure"
# skip deleting resources deployed by test-refinery-gatway
if [ $KUBERNETES_DEPLOYMENT_NAME != "refinery-websocket" ]; then
    kubectl delete --kustomize apps/${KUBERNETES_DEPLOYMENT_NAME}/test
fi
kubectl delete --kustomize infrastructure/test
echo "::endgroup::"

exit $exitcode
