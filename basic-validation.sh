#!/bin/bash

# Source registry variables
SRC_REGISTRY="quay.io"
SRC_REPO="quay-qetest"
SRC_IMAGE="ubuntu"
SRC_TAG="latest"

# Destination registry variables, $1, $2, $3 values need to be set while run time. eg, ./basic-quayregistry-validation.sh quay ubuntu v1-latest
DEST_REGISTRY="rajakumar.apps.quay3113.cp.fyre.ibm.com"
DEST_REPO="$1"
DEST_IMAGE="$2"
DEST_TAG="$3"

podman login -u raja0940 -p K@mala@123 ${SRC_REGISTRY}
podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}
echo "local images list after pulling ubuntu image from docker hub registry"
podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
podman login -u quay -p password ${DEST_REGISTRY} --tls-verify=false
#podman login -u user1 -p password ${DEST_REGISTRY} --tls-verify=false
podman push --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
podman images
podman rmi ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}
podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
echo "local images list after removing ubuntu images"
podman images
podman pull --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
echo "local images list after above command"
podman images

