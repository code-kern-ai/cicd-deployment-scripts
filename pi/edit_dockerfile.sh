# !/bin/bash

set -e

HEAD_REF="parent-image-updates"
PARENT_IMAGE_NAME="refinery-parent-images"
RELEASE_TAG="parent-image-updates"
DOCKER_REGISTRY="kernai"
DEV_REGISTRY="registry.dev.kern.ai/code-kern-ai"
DOCKERFILE="Dockerfile"
EDIT_TYPE="build"

while getopts i:l:r:e:d:t: flag
do
    case "${flag}" in
        i) PARENT_IMAGE_NAME=${OPTARG};;
        l) RELEASE_TAG=${OPTARG};;
        r) DOCKER_REGISTRY=${OPTARG};;
        e) DEV_REGISTRY=${OPTARG};;
        d) DOCKERFILE=${OPTARG};;
        t) EDIT_TYPE=${OPTARG};;
    esac
done

DEV_UPDATED=$(grep "${DEV_REGISTRY}/${PARENT_IMAGE_NAME}:${HEAD_REF}" $DOCKERFILE || true)
if [ "$EDIT_TYPE" = "build" ]; then
    if [ -n "$DEV_UPDATED" ]; then
        echo "Parent image already updated in $DOCKERFILE"
        exit 0
    else
        REGISTRY="${DOCKER_REGISTRY}"
    fi
elif [ "$EDIT_TYPE" = "release" ]; then
    if [ -n "$DEV_UPDATED" ]; then
        REGISTRY="${DEV_REGISTRY}"
    else
        REGISTRY="${DOCKER_REGISTRY}"
    fi
else
    echo "::error::Invalid EDIT_TYPE: $EDIT_TYPE. Use 'build' or 'release'"
    exit 1
fi

grep "${REGISTRY}/${PARENT_IMAGE_NAME}" $DOCKERFILE | while read -r line ; do
    PI_EXISTING_TAG=$(echo $line | sed 's|ARG PARENT_IMAGE=||g' | cut -d ':' -f 2)
    PI_EXISTING_IMAGE="${REGISTRY}/${PARENT_IMAGE_NAME}:${PI_EXISTING_TAG}"

    if [ -n "$DEV_UPDATED" ]; then
        PARENT_IMAGE_TYPE=$(echo $PI_EXISTING_TAG | sed "s|${HEAD_REF}-||g")
    else
        image_version=$(echo $PI_EXISTING_TAG | cut -d '-' -f 1)
        PARENT_IMAGE_TYPE=$(echo $PI_EXISTING_TAG | sed "s|${image_version}-||g")
    fi

    if [ "$EDIT_TYPE" = "build" ]; then
        PI_NEW_IMAGE="${DEV_REGISTRY}/${PARENT_IMAGE_NAME}:${HEAD_REF}-${PARENT_IMAGE_TYPE}"
    elif [ "$EDIT_TYPE" = "release" ]; then
        PI_NEW_IMAGE="${DOCKER_REGISTRY}/${PARENT_IMAGE_NAME}:${RELEASE_TAG}-${PARENT_IMAGE_TYPE}"
    fi

    sed "s|${PI_EXISTING_IMAGE}|${PI_NEW_IMAGE}|g" ${DOCKERFILE} > ${DOCKERFILE}.tmp && mv ${DOCKERFILE}.tmp ${DOCKERFILE}
    echo "::notice::${DOCKERFILE} updated with new image: ${PI_NEW_IMAGE}"
done
