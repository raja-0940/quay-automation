#!/bin/bash

## Required properties for quay regsitry validation

# Source registry variables
SRC_REGISTRY="quay.io" # example source registry
SRC_REPO="quay-qetest" # example source repository
SRC_IMAGE="alpine" # example source image name
SRC_TAG="latest" # example source image tag
SRC_REG_USER_NAME="<src-reg-user>"
SRC_REG_PASSWORD="<src-reg-password>"



# Destination registry variables.
DEST_REGISTRY="<quayregistry-end-point>"
DEST_REPO="<dest-repo>"
DEST_IMAGE="<dest-image>"
DEST_TAG="<dest-tag>"
DEST_REG_USER_NAME="<dest-reg-user>"
DEST_REG_PASSWORD="<dest-reg-password>"
QUAY_API_TOKEN="<dest-reg-api-token>"

#Client variable.
CLIENT_PASSWORD="<>" 
CLIENT_HOSTNAME="<>"  #hostname of client machine

