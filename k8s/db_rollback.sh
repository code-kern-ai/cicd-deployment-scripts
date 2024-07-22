# !/bin/bash
set -e

ENVIRONMENT_NAME=""
KUBERNETES_DEPLOYMENT_NAME=""
KUBERNETES_NAMESPACE=""
AZURE_CONTAINER_REGISTRY=""
IMAGE_TAG=""
alembic_downgrade_rev=""

while getopts e:d:r:t:n:a: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) IMAGE_TAG=${OPTARG};;
        a) alembic_downgrade_rev=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

echo "Rolling back to migration revision: $rev_rollback_migrations"
kubectl exec -i deployment/${KUBERNETES_DEPLOYMENT_NAME} -c $KUBERNETES_DEPLOYMENT_NAME -- alembic downgrade ${rev_rollback_migrations}
kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT_NAME}