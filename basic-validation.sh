#!/bin/bash

## setting validation properties
source ./validation-properties.sh

function basicvalidation {
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
}

# basicvalidation

# ocp-20943 should be tested on Quay registry with unmanaged tls component
function push_multiarch_images {
    podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY}
    for tag in arm64 s390x 386; do
      podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag
      podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
      podman push --tls-verify=false --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
    done
    # sudo cp /root/openssl/quay-automation/OCP-42387/config/rootCA.pem /etc/containers/certs.d/${DEST_REGISTRY}/ca.crt
    # sudo cp /root/openssl/quay-automation/OCP-42387/config/rootCA.pem /etc/pki/ca-trust/source/anchors/
    # sudo update-ca-trust extract
    # trust list | grep quay
    podman manifest create ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest \
      ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:arm64 \
      ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:s390x \
      ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:386 --amend
    podman login -u ${DEST_REG_USER_NAME} -p ${DEST_REG_PASSWORD} ${DEST_REGISTRY}
    podman manifest push ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    for arch in arm64 s390x 386; do
      podman pull --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} --arch="$arch" ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    done

}

# push_multiarch_images

