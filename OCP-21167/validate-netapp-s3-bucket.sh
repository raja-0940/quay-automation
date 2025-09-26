#!/bin/bash

# Source build properties
source ../build-properties.sh

# verify valid aws cli utility and create NETAPP_S3_BUCKET_NAME s3 bucket
if [ $(aws --version | cut -d '/' -f1) == "aws-cli" ]; then
  echo "aws cli tool is availble"
  echo "$(aws --version)"
  aws configure set aws_access_key_id ${NETAPP_TENANT_ACCESS_KEY} --profile tenant-s3
  aws configure set aws_secret_access_key ${NETAPP_TENANT_SECRET_KEY} --profile tenant-s3
  aws configure set region ${NETAPP_TENANT_REGION} --profile tenant-s3
  aws configure set output json --profile tenant-s3
  echo "Enter Netapp Tenant Secret Key and Access Key"
  ## aws configure --profile tenant-s3
  ## NETAPP_S3_BUCKET_NAME_LIST="aws s3 ls  --endpoint-url ${NETAPP_S3_ENDPOINT}  --profile tenant-s3"
  if [ $(aws s3 ls  --endpoint-url ${NETAPP_S3_ENDPOINT}  --profile tenant-s3 | grep redhat-quay1 | cut -d ' ' -f3) == "${NETAPP_S3_BUCKET_NAME}" ]; then
  aws s3 ls  --endpoint-url ${NETAPP_S3_ENDPOINT}  --profile tenant-s3
    echo "${NETAPP_S3_BUCKET_NAME} s3 bucket is available"
    echo "clear data from the ${NETAPP_S3_BUCKET_NAME} s3 bucket"
    ##aws s3 ls s3://${NETAPP_S3_BUCKET_NAME} --recursive --human-readable --summarize
    ##aws s3 rm s3://${NETAPP_S3_BUCKET_NAME} --recursive
  else
    echo "NetApp Bucket is not available"
    exit 1
  fi
else
  echo "Install python3"
  yum install -y python3.11
  curl -O https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py --user
  export PATH=~/.local/bin:$PATH
  source ~/.bash_profile
  pip3 install awscli --upgrade --user
  echo "$(aws --version)"
  echo "Enter Netapp Tenant Secret Key and Access Key"
  aws configure set aws_access_key_id ${NETAPP_TENANT_ACCESS_KEY} --profile tenant-s3
  aws configure set aws_secret_access_key ${NETAPP_TENANT_SECRET_KEY} --profile tenant-s3
  aws configure set region ${NETAPP_TENANT_REGION} --profile tenant-s3
  aws configure set output json --profile tenant-s3
  ##  echo "Enter Netapp Tenant Secret Key and Access Key"
  ##  aws configure --profile tenant-s3
  NETAPP_S3_BUCKET_NAME_LIST=aws s3 ls \
  --endpoint-url "$(NETAPP_S3_ENDPOINT)" \
  --profile tenant-s3
  aws configure set output json
  if [ $(NETAPP_S3_BUCKET_NAME_LIST | grep redhat-quay1 | cut -d ' ' -f3) == "${NETAPP_S3_BUCKET_NAME}" ]; then
    echo "${NETAPP_S3_BUCKET_NAME} s3 bucket is available"
    echo "clear data from the ${NETAPP_S3_BUCKET_NAME} s3 bucket"
    ##aws s3 ls s3://${NETAPP_S3_BUCKET_NAME} --recursive --human-readable --summarize
    ##aws s3 rm s3://${NETAPP_S3_BUCKET_NAME} --recursive
  else
    echo "NetApp Bucket is not available"
    exit 1
  fi
fi
