# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""
KUBERNETES_DEPLOYMENT_NAME=""
APPLICATION_STARTUP_MESSAGE="Application startup complete"

while getopts n:d:m: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
        d) KUBERNETES_DEPLOYMENT_NAME=${OPTARG};;
        m) APPLICATION_STARTUP_MESSAGE=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

echo "Reading logs to determine application startup status for '$KUBERNETES_DEPLOYMENT_NAME'"
echo "Searching for message: '$APPLICATION_STARTUP_MESSAGE'"

LOG_CONTENTS=$(kubectl logs deployment/${KUBERNETES_DEPLOYMENT_NAME} \
    || echo "Waiting for application startuop ...")

while [[ "$LOG_CONTENTS" != *"$APPLICATION_STARTUP_MESSAGE"* ]]; do
    echo "Waiting for application startup..."
    sleep 3
    LOG_CONTENTS=$(kubectl logs deployment/${KUBERNETES_DEPLOYMENT_NAME} \
        || echo "Waiting for application startuop ...")
done

echo "Application startup successful:"
echo "$LOG_CONTENTS"
