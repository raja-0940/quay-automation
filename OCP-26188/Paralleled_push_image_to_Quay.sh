#!/bin/bash

source ../validation-properties.sh
source ../login.sh

function parallel_push_pull() {
	podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}
	podman 	tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
	podman push --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}
	echo "Check sshpass"
	if [ -x "$(command -v sshpass -V)" ]; then
    		echo "sshpass has been installed already."
	else
    		yum install sshpass -y
	fi
	sshpass -p ${CLIENT_PASSWORD} ssh root@${CLIENT_HOSTNAME} "podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY}" || exit 1
	sshpass -p ${CLIENT_PASSWORD} ssh root@${CLIENT_HOSTNAME} "podman pull ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG}" || exit 1
	sshpass -p ${CLIENT_PASSWORD} ssh root@${CLIENT_HOSTNAME} "podman tag ${SRC_REGISTRY}/${SRC_REPO}/${SRC_IMAGE}:${SRC_TAG} ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}" || exit 1
	sshpass -p ${CLIENT_PASSWORD} ssh root@${CLIENT_HOSTNAME} "podman login -u ${DEST_REG_USER_NAME} -p ${DEST_REG_PASSWORD} ${DEST_REGISTRY} --tls-verify=false" || exit 1
	sshpass -p ${CLIENT_PASSWORD} ssh root@${CLIENT_HOSTNAME} "podman push --tls-verify=false ${DEST_REGISTRY}/${DEST_REPO}/${DEST_IMAGE}:${DEST_TAG}" || exit 1
}

parallel_push_pull
