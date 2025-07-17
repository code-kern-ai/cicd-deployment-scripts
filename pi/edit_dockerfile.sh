# !/bin/bash

set -e

PARENT_IMAGE_NAME="refinery-parent-images"
RELEASE_TAG="parent-image-updates"
DOCKER_REGISTRY="kernai"
DOCKERFILE="Dockerfile"
HEAD_REF=""

while getopts i:l:r:d:h: flag
do
    case "${flag}" in
        i) PARENT_IMAGE_NAME=${OPTARG};;
        l) RELEASE_TAG=${OPTARG};;
        r) DOCKER_REGISTRY=${OPTARG};;
        d) DOCKERFILE=${OPTARG};;
        h) HEAD_REF=${OPTARG};;
    esac
done

grep "${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}" $DOCKERFILE | while read -r line ; do
    PI_EXISTING_TAG=$(echo $line | sed 's|FROM ||g' | cut -d ':' -f 2)
    ALREADY_UPDATED=$(echo $PI_EXISTING_TAG | grep $RELEASE_TAG || true)

    if [ -z $ALREADY_UPDATED ] && [ -z $HEAD_REF ]; then
        image_version=$(echo $PI_EXISTING_TAG | cut -d '-' -f 1)
        PARENT_IMAGE_TYPE=$(echo $PI_EXISTING_TAG | sed "s|${image_version}-||g")
    elif [ -n $ALREADY_UPDATED ] && [ -z $HEAD_REF ]; then
        PARENT_IMAGE_TYPE=$(echo $PI_EXISTING_TAG | sed "s|${RELEASE_TAG}-||g")
    elif [ -n $HEAD_REF ]; then
        PARENT_IMAGE_TYPE=$(echo $PI_EXISTING_TAG | sed "s|${HEAD_REF}-||g")
    else
        echo "::error::Failed to determine parent image type from tag: ${PI_EXISTING_TAG}"
        exit 1
    fi

    PI_EXISTING_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${PI_EXISTING_TAG}"
    PI_NEW_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${RELEASE_TAG}-${PARENT_IMAGE_TYPE}"

    sed "s|${PI_EXISTING_IMAGE}|${PI_NEW_IMAGE}|g" ${DOCKERFILE} > ${DOCKERFILE}.tmp && mv ${DOCKERFILE}.tmp ${DOCKERFILE}
    echo "::notice::${DOCKERFILE} updated with new image: ${PI_NEW_IMAGE}"
done
