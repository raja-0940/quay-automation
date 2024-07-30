#!/bin/bash

# Source build properties
source ../build-properties.sh

# verify valid aws cli utility and create AWS_S3_BUCKET_NAME s3 bucket
if [ $(aws --version | cut -d '/' -f1) == "aws-cli" ]; then
  echo "aws cli tool is availble"
  echo "$(aws --version)"
  aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
  aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
  aws configure set region ${AWS_REGION}
  aws configure set output json
  echo "aws cli is now configured with region ${AWS_REGION}"
  if [ $(aws s3 ls | grep quay0940 | cut -d ' ' -f3) == "${AWS_S3_BUCKET_NAME}" ]; then
    echo "${AWS_S3_BUCKET_NAME} s3 bucket is available"
    echo "clear data from the ${AWS_S3_BUCKET_NAME} s3 bucket"
    aws s3 ls s3://${AWS_S3_BUCKET_NAME} --recursive --human-readable --summarize
    aws s3 rm s3://${AWS_S3_BUCKET_NAME} --recursive
  else
    echo "Create ${AWS_S3_BUCKET_NAME} aws s3 bucket"
    aws s3api create-bucket --bucket ${AWS_S3_BUCKET_NAME} --region ${AWS_REGION}
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
  aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
  aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
  aws configure set region ${AWS_REGION}
  aws configure set output json
  echo "aws cli is now configured with region ${AWS_REGION}"
  if [ $(aws s3 ls | grep quay0940 | cut -d ' ' -f3) == "${AWS_S3_BUCKET_NAME}" ]; then
    echo "${AWS_S3_BUCKET_NAME} s3 bucket is available"
    echo "clear data from the ${AWS_S3_BUCKET_NAME} s3 bucket"
    aws s3 ls s3://${AWS_S3_BUCKET_NAME} --recursive --human-readable --summarize
    aws s3 rm s3://${AWS_S3_BUCKET_NAME} --recursive
  else
    echo "Create ${AWS_S3_BUCKET_NAME} aws s3 bucket"
    aws s3api create-bucket --bucket ${AWS_S3_BUCKET_NAME} --region ${AWS_REGION}
  fi
fi

