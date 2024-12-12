# !/bin/bash

set -e

PARENT_IMAGE_NAME="refinery-parent-images"
PARENT_IMAGE_TYPE="common"
RELEASE_TAG="v1.19.1"
DOCKER_REGISTRY="kernai"
DOCKERFILE="Dockerfile"

while getopts i:t:l:r:d: flag
do
    case "${flag}" in
        i) PARENT_IMAGE_NAME=${OPTARG};;
        t) PARENT_IMAGE_TYPE=$(echo ${OPTARG} | sed 's|_|-|g');;
        l) RELEASE_TAG=${OPTARG};;
        r) DOCKER_REGISTRY=${OPTARG};;
        d) DOCKERFILE=${OPTARG};;
    esac
done

PI_EXISTING_TAG=$(grep "${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:v.*-${PARENT_IMAGE_TYPE}" $DOCKERFILE | sed 's|FROM ||g' | cut -d ':' -f 2)
PI_EXISTING_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${PI_EXISTING_TAG}"
PI_NEW_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${RELEASE_TAG}-${PARENT_IMAGE_TYPE}"

DOCKER_CONTENT="$(sed 's|'${PI_EXISTING_IMAGE}'|'${PI_NEW_IMAGE}'|g' ${DOCKERFILE})"
echo ${DOCKER_CONTENT} > ${DOCKERFILE}
echo "::notice::Dockerfile updated with new image: ${PI_NEW_IMAGE}"