#!/bin/bash

## setting validation properties
source ./validation-properties.sh

if [ $(jq --version | cut -d '/' -f1) == "jq" ]; then
  echo "jq tool is available"
else
  echo "installing jq.."
  yum install -y jq
fi

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

basicvalidation

# ocp-20943 should be tested on Quay registry with unmanaged tls component
function push_multiarch_images {
    podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY}
    for tag in arm64, s390x, 386; do
      podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag
      podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
      podman push --tls-verify=false --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
    done
    podman manifest create ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest \
      ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:arm64 \
      ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:s390x \
      ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:386 --amend
    podman manifest push --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} --tls-verify=fasle ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    podman pull --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} --tls-verify=fasle ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest

}

# ocp-20944 should get info about multiarch manifests via API
function getInfoofMultiarchManifests {

  # Copy any multiarch image from the remote registry

  if [ $(skopeo --version | cut -d '/' -f1) == "skopeo" ]; then
    echo "skopeo tool is availble"
    echo "$(skopeo --version)"
    skopeo copy --src-creds=${SRC_REG_USER_NAME}:${SRC_REG_PASSWORD} --dest-creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} \
    --dest-tls-verify=false --all docker://${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:latest \
    docker://${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
  else
    echo "Installing skopeo tool"
    yum install -y skopeo
    skopeo copy --src-creds=${SRC_REG_USER_NAME}:${SRC_REG_PASSWORD} --dest-creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} \
    --dest-tls-verify=false --all docker://${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:latest \
    docker://${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
  fi

  ## Create OAuth token for the destination registry and configure in validation-properties.sh file with QUAY_API_TOKEN

  # Check manifest list via api
  echo "Check manifest list via api"
  curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/tag/ |jq .

  # get information about multi-arch manifests via API
  echo "Get information about multi-arch manifests via API"
  MANIFEST_DIGEST="$(curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/tag/ |jq '.tags[0].manifest_digest')"
  curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/manifest/${MANIFEST_DIGEST} |jq .

  # get information about  specific arch  manifests via API
  echo "Get information about  specific arch  manifests via API"
  DIGEST=$(curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/manifest/${MANIFEST_DIGEST} |\
  jq .manifest_data | sed 's/^"//;s/"$//' | tr -d '\' | jq .manifests[0].digest)
  curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/manifest/${DIGEST} |jq .

}

# getInfoofMultiarchManifests

