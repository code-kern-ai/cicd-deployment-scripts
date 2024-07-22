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

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

set +e
alembic_exitcode=0
ALEMBIC_CURRENT_REVISION=$(kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- alembic current 2> /dev/null)
alembic_exitcode=$?
set -e

echo "::notice::running test command: kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- '$TEST_CMD'"

KUBERNETES_POD_EXISTING_IMAGE=$(kubectl get pod --output json \
    --selector app=${KUBERNETES_DEPLOYMENT_NAME} \
    | jq -r '.items[0] | .spec.containers[0].image')

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}
echo "::warning::using ${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${TEST_IMAGE_TAG}"

kubectl rollout status deployment ${KUBERNETES_DEPLOYMENT_NAME}

set +e
exitcode=0
echo "::warning::running test command: kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- '$TEST_CMD'"
kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- "$TEST_CMD"
exitcode=$?
set -e

kubectl set image deployment/${KUBERNETES_DEPLOYMENT_NAME} ${KUBERNETES_DEPLOYMENT_NAME}=${KUBERNETES_POD_EXISTING_IMAGE}
echo "::notice::using ${KUBERNETES_POD_EXISTING_IMAGE}"

if [ alembic_exitcode -eq 0 ]; then
    ALEMBIC_HEAD=${ALEMBIC_CURRENT_REVISION:0:12}
    
    ALEMBIC_UPDATED_REVISION=$(kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- alembic current)
    ALEMBIC_UPDATED_HEAD=${ALEMBIC_UPDATED_REVISION:0:12}

    if [ $ALEMBIC_HEAD = $ALEMBIC_UPDATED_HEAD ]; then
        echo "::notice::skipping alembic downgrade"
    else
        echo "::notice::downgrading to alembic revision: $ALEMBIC_HEAD"
        kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- alembic downgrade $ALEMBIC_HEAD
    fi
fi

exit $exitcode
