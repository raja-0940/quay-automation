#!/bin/bash

## setting validation properties
source ./validation-properties.sh

podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY}
podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}
echo "local images list after pulling ubuntu image from docker hub registry"
podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
podman login -u ${DEST_REG_USER_NAME} -p ${DEST_REG_PASSWORD} ${DEST_REGISTRY} --tls-verify=false
podman push --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
podman images
podman rmi ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}
podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
echo "local images list after removing ubuntu images"
podman images
podman pull --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
echo "local images list after above command"
podman images

