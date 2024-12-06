# !/bin/bash

set -e

PARENT_IMAGE_NAME="refinery-parent-images"
PARENT_IMAGE_TYPE=""
RELEASE_TAG=""
DOCKER_REGISTRY="kernai"
DOCKERFILE_PATH="Dockerfile"

while getopts i:t:l:r:d: flag
do
    case "${flag}" in
        i) PARENT_IMAGE_NAME=${OPTARG};;
        t) PARENT_IMAGE_TYPE=$(echo ${OPTARG} | sed 's|_|-|g');;
        l) RELEASE_TAG=${OPTARG};;
        r) DOCKER_REGISTRY=${OPTARG};;
        d) DOCKERFILE_PATH=${OPTARG};;
    esac
done

PI_EXISTING_TAG=$(grep "${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:v.*-${PARENT_IMAGE_TYPE}" $DOCKERFILE_PATH | sed 's|FROM ||g' | cut -d ':' -f 2)
PI_EXISTING_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${PI_EXISTING_TAG}"
PI_NEW_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${RELEASE_TAG}"

echo "$(sed "s|${PI_EXISTING_IMAGE}|${PI_NEW_IMAGE}|g" ${DOCKERFILE_PATH})" > $DOCKERFILE_PATH
echo "::notice::Dockerfile updated with new image: ${PI_NEW_IMAGE}"