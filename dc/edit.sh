# !/bin/bash
set -e

ENVIRONMENT_NAME=""
CONTAINER_REGISTRY=""
DOCKER_COMPOSE_SERVICE=""
IMAGE_TAG=""

while getopts e:r:s:t: flag
do
    case "${flag}" in
        e) ENVIRONMENT_NAME=${OPTARG};;
        r) CONTAINER_REGISTRY=${OPTARG};;
        s) DOCKER_COMPOSE_SERVICE=${OPTARG};;
        t) IMAGE_TAG=${OPTARG};;
    esac
done

APP_NAME=$(echo "${DOCKER_COMPOSE_SERVICE//-/_}" | tr '[:lower:]' '[:upper:]')

line=$(grep "${APP_NAME}=" .env.${ENVIRONMENT_NAME})

APP_EXISTING_TAG=$(echo $line | sed "s|$APP_NAME=||g" | cut -d ':' -f 2)
APP_EXISTING_IMAGE="${CONTAINER_REGISTRY}/${DOCKER_COMPOSE_SERVICE}:${APP_EXISTING_TAG}"
APP_NEW_IMAGE="${CONTAINER_REGISTRY}/${DOCKER_COMPOSE_SERVICE}:${IMAGE_TAG}"

echo "$(sed 's|'${APP_EXISTING_IMAGE}'|'${APP_NEW_IMAGE}'|g' .env.${ENVIRONMENT_NAME})" > .env.${ENVIRONMENT_NAME}
echo "::notice::.env.${ENVIRONMENT_NAME} updated with new image: ${APP_NEW_IMAGE}"
