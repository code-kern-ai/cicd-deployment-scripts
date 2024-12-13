# !/bin/bash

set -e

PARENT_IMAGE_NAME="refinery-parent-images"
PARENT_IMAGE_TYPE=""
RELEASE_TAG=""
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

echo "--------- echo grep ---------"
echo "grep ${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME} $DOCKERFILE"
echo "-----------------------------"

grep "${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}" $DOCKERFILE | while read -r line ; do
    PI_EXISTING_TAG=$(echo $line | sed 's|FROM ||g' | cut -d ':' -f 2)
    PI_EXISTING_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${PI_EXISTING_TAG}"
    PI_NEW_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${RELEASE_TAG}-${PARENT_IMAGE_TYPE}"

    echoi "PI_EXISTING_TAG = $PI_EXISTING_TAG"
    echoi "PI_EXISTING_IMAGE = $PI_EXISTING_IMAGE"
    echoi "PI_NEW_IMAGE = $PI_NEW_IMAGE"

    sed "s|${PI_EXISTING_IMAGE}|${PI_NEW_IMAGE}|g" ${DOCKERFILE} > ${DOCKERFILE}.tmp && mv ${DOCKERFILE}.tmp ${DOCKERFILE}
done

echo "::notice::Dockerfile updated with new image: ${PI_NEW_IMAGE}"