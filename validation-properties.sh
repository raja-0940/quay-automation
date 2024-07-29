#!/bin/bash

## Required properties for quay regsitry validation

# Source registry variables
SRC_REGISTRY="quay.io" # example source registry
SRC_REPO="quay-qetest" # example source repository
SRC_IMAGE="ubuntu" # example source image name
SRC_TAG="latest" # example source image tag
SRC_REG_USER_NAME="src-reg-usr-name"
SRC_REG_PASSWORD="src-reg-password"


# Destination registry variables.
DEST_REGISTRY="<quay-registry-end-point>"
DEST_REPO="<dest-repository>"
DEST_IMAGE="<dest-image-name>"
DEST_TAG="<destination-image-tag>"
DEST_REG_USER_NAME="<dest-reg-usr-name>"
DEST_REG_PASSWORD="<dest-reg-password>"
