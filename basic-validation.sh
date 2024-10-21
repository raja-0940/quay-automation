#!/bin/bash

## setting validation properties
source ./validation-properties.sh

if [ $(jq --version | cut -d '-' -f1) == "jq" ]; then
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
    podman manifest push --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    podman pull --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    # podman login -u ${DEST_REG_USER_NAME} -p ${DEST_REG_PASSWORD} ${DEST_REGISTRY}
    # podman manifest push ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    # podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    # for arch in arm64 s390x 386; do
    #   podman pull --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} --arch="$arch" ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:latest
    # done

}

# push_multiarch_images


# ocp-20944 should get info about multiarch manifests via API
function getInfoofMultiarchManifests {

  # Copy any multiarch image from the remote registry

  if [ $(skopeo --version | cut -d ' ' -f1) == "skopeo" ]; then
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
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/tag/ |jq '.tags[0].manifest_digest' | tr -d '"')"
  echo "****************************${MANIFEST_DIGEST}**************************"
  curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/manifest/${MANIFEST_DIGEST} |jq .

  # get information about  specific arch  manifests via API
  echo "Get information about  specific arch  manifests via API"
  DIGEST="$(curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/manifest/${MANIFEST_DIGEST} |\
  jq .manifest_data | sed 's/^"//;s/"$//' | tr -d '\' | jq .manifests[0].digest | tr -d '"')"
  echo "*************************${DIGEST}*******************************"
  curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/manifest/${DIGEST} |jq .

}

# getInfoofMultiarchManifests

# OCP-21050 - [Quay-987] Show error when pull a deleted manifest by digest

function pulImagebyDigest {
  tag="386"
  podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY}
  podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag
  podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
  podman push --tls-verify=false --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
  podman rmi ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:$tag
  podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag

  # pull image by digest

  # using API call
  curl -k -X GET -H "Authorization: Bearer ${QUAY_API_TOKEN}" \
  https://${DEST_REGISTRY}/api/v1/repository/${DEST_REPO}/${DEST_IMAGE}/tag/ |jq .

  # using podman pull
  podman pull --tls-verify=false --creds=${DEST_REG_USER_NAME}:${DEST_REG_PASSWORD} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
  podman images

  # Delete the image from Quay UI and try to pull the image by digest. It will fail with error
  # podman rmi ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
  # podman pull ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:$tag
}

# pulImagebyDigest

## This function deploys QuayRegistry with all managed components. ( OCP-42377, 42399, 42404 and 42375 )

function deployQuayregistrywithAllManagedComponents {

  # Create config.yaml
  cat >> ./config.yaml <<EOF
SERVER_HOSTNAME: ${DEST_REGISTRY}
PREFERRED_URL_SCHEME: https
FEATURE_UI_V2: true
FEATURE_UI_V2_REPO_SETTINGS: true
FEATURE_AUTO_PRUNE: true
ROBOTS_DISALLOW: false
BROWSER_API_CALLS_XHR_ONLY: false
SUPER_USERS:
  - quay
EOF

  # Create config-bundle-secret from config.yaml file
  oc create secret generic --from-file config.yaml=./config.yaml config-bundle-secret

  # Create quay-registry.yaml file with all managed components
  cat <<EOF | oc apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: quayreg$(date +%Y%m%d%H%M%S)
  namespace: quay-registry
spec:
  configBundleSecret: config-bundle-secret
  components:
  - kind: postgres
    managed: true
  - kind: objectstorage
    managed: true
  - kind: redis
    managed: true
  - kind: route
    managed: true
  - kind: monitoring
    managed: true
  - kind: tls
    managed: true
  - kind: quay
    managed: true
  - kind: clair
    managed: true
  - kind: clairpostgres
    managed: true
  - kind: horizontalpodautoscaler
    managed: true
  - kind: mirror
    managed: true
EOF

}

# deployQuayregistrywithAllManagedComponents

## OCP-22450: [Quay] Pull an image stored as manifest schema 2 via schema 1
function pullImageManifestFromSchema1 {

  # check and install python3.11
  if [ $(python3.11 -V | cut -d ' ' -f2) == 3.11.* ]; then
    echo "Python 3.11 is available"
  else
    echo "Installing python3.11.."
    yum install -y python3.11
    echo "Installed $(python3.11 -V)"
  fi

  # create an organization named 'v22test'    
  curl -k -X POST -H "Authorization: Bearer ${QUAY_API_TOKEN}" -H "Content-Type: application/json" \
  https://${DEST_REGISTRY}/api/v1/repository -d '{"name": "v22test"}'

  # Push image via manifest schema 2
  podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY}
  podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}
  sleep 20
  podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG} ${DEST_REGISTRY}/v22test/${DEST_IMAGE}:${DEST_TAG}
  podman login -u ${DEST_REG_USER_NAME} -p ${DEST_REG_PASSWORD} ${DEST_REGISTRY} --tls-verify=false
  podman push --tls-verify=false ${DEST_REGISTRY}/v22test/${DEST_IMAGE}:${DEST_TAG}
  sleep 30
  podman ps -a

  # Pull image via manifest schema 1
  curl -k -v -X GET -H "Accept: application/vnd.docker.distribution.manifest.v1+json" \
  "https://${DEST_REGISTRY}/v2/v22test/${DEST_IMAGE}/manifests/${DEST_TAG}" | python3.11 -m json.tool

}
