# !/bin/bash
set -e

ENVIRONMENT_NAME=""
KUBERNETES_DEPLOYMENT_NAME=""
KUBERNETES_NAMESPACE=""
AZURE_CONTAINER_REGISTRY=""
IMAGE_TAG=""
num_migrations=""

while getopts e:d:r:t:n:m: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) IMAGE_TAG=${OPTARG};;
        m) num_migrations=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

KUBERNETES_POD_IMAGE="${AZURE_CONTAINER_REGISTRY}/${KUBERNETES_DEPLOYMENT_NAME}:${IMAGE_TAG}"

function generate_db_rollback_job {
    echo "Generating DB Rollback job for ${KUBERNETES_DEPLOYMENT_NAME} in ${ENVIRONMENT_NAME}"
    sed -i.bak 's|${KUBERNETES_DEPLOYMENT_NAME}|'${KUBERNETES_DEPLOYMENT_NAME}'|g' apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.tmpl
    sed -i.bak 's|${KUBERNETES_POD_IMAGE}|'${KUBERNETES_POD_IMAGE}'|g' apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.tmpl
    sed -i.bak 's|${num_migrations}|'${num_migrations}'|g' apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.tmpl

    mv apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.tmpl apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.yml
    echo "::notice::Generated DB Rollback job successfully"
    cat apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.yml
}

function apply_db_rollback_job {
    echo "Applying DB Rollback job for ${KUBERNETES_DEPLOYMENT_NAME} in ${ENVIRONMENT_NAME}"
    kubectl apply --filename apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.yml
    echo "::notice::Applied DB Rollback job successfully"
}

function delete_db_rollback_job {
    echo "Deleting DB Rollback job for ${KUBERNETES_DEPLOYMENT_NAME} in ${ENVIRONMENT_NAME}"
    kubectl delete --filename apps/${KUBERNETES_DEPLOYMENT_NAME}/${ENVIRONMENT_NAME}/db_rollback.yml
    echo "::notice::Deleted DB Rollback job successfully"
}