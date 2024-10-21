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
STANDALONE_QUAY_IMAGE=""

## define following environment varibles for to test quay registry with unmanaged object storage
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION=""
export AWS_S3_BUCKET_NAME=""
export SERVER_HOSTNAME=""
export AWS_HOST=""

