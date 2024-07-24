# !/bin/bash
set -e

ENVIRONMENT_NAME=""
KUBERNETES_DEPLOYMENT_NAME=""
KUBERNETES_DEPLOYMENT_REPO_PATH=""
KUBERNETES_NAMESPACE=""
AZURE_CONTAINER_REGISTRY=""
IMAGE_TAG=""
alembic_upgrade_rev=""

while getopts e:d:p:n:r:t:a: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        p) KUBERNETES_DEPLOYMENT_REPO_PATH=${OPTARG};;
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        r) AZURE_CONTAINER_REGISTRY=${OPTARG};;
        t) IMAGE_TAG=${OPTARG};;
        a) alembic_upgrade_rev=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

echo "::group::Migrating to revision: $alembic_upgrade_rev"

sed 's|${ALEMBIC_COMMAND}|upgrade|g' \
    $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.tmpl \
    > $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.yml
sed -i.bak 's|${ALEMBIC_ARGS}|'${alembic_upgrade_rev}'|g' $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.yml
sed -i.bak 's|${IMAGE_TAG}|'${IMAGE_TAG}'|g' $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.yml

rm $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.yml.bak
cat $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.yml
echo "::endgroup::"

echo "::group::Apply Kubernetes Job"
kubectl apply --filename $KUBERNETES_DEPLOYMENT_REPO_PATH/infrastructure/$ENVIRONMENT_NAME/job/$KUBERNETES_DEPLOYMENT_NAME-migrate.yml

echo "Waiting for migration job to complete ..."
kubectl wait --for=condition=complete --timeout 60s job/$KUBERNETES_DEPLOYMENT_NAME-migrate
kubectl logs job/$KUBERNETES_DEPLOYMENT_NAME-migrate
echo "::endgroup::"

echo "::group::Rolling out deployment"
kubectl rollout restart deployment/$KUBERNETES_DEPLOYMENT_NAME
kubectl rollout status deployment/$KUBERNETES_DEPLOYMENT_NAME

kubectl rollout restart deployment/cognition-gateway
kubectl rollout status deployment/cognition-gateway

kubectl delete job/$KUBERNETES_DEPLOYMENT_NAME-migrate
echo "::endgroup::"