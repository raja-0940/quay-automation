#!/bin/bash

## define your build properties
COUNTRY="IE"
STATE="GALWAY"
LOCALITY="GALWAY"
ORG="QUAY"
ORG_UNIT="DOCS"
COMMON_NAME=""
BASTION_IP=""
REDHAT_USER=""
REDHAT_PASS=""
STANDALONE_QUAY_IMAGE="brew.registry.redhat.io/quay/quay-rhel8@sha256:bbbe36c1fd7981bd0ab2d6f863f85489f8a246f17371863036ffe50d7097fce9"

## define following environment varibles for to test quay registry with unmanaged object storage
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION=""
export AWS_S3_BUCKET_NAME=""
export SERVER_HOSTNAME=""
export AWS_HOST=""

