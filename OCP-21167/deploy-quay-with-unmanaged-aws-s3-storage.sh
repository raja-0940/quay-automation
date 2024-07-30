#!/bin/bash

# creating s3 bucket for to configure unmanaged quay storage
source ./create-aws-s3-bucket.sh

# check for config.yaml, ssl.cert nd ssl.key
cd ./config/
if [ -f ./config.yaml ]; then
	echo "config.yaml is available"
else
	echo "Please create config.yaml file"
	exit 1
fi

# Create a config bundle secret
if [ $(oc project | cut -d ' ' -f3 | tr -d '"') == "quay-registry" ]; then
	echo "We are working under quay-registry namespace"
	oc create secret generic --from-file config.yaml=./config.yaml test-config-bundle
else
	echo "Create or switch to quay-registry project and create config-bundle-secret"
	oc project quay-registry
	oc create secret generic --from-file config.yaml=./config.yaml test-config-bundle
fi

# Create quay-registry.yaml file with unmanaged tls component
cat <<EOF | oc apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: quayreg$(date +%Y%m%d%H%M%S)
  namespace: quay-registry
spec:
  configBundleSecret: test-config-bundle
  components:
  - kind: postgres
    managed: true
  - kind: objectstorage
    managed: false 
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
    managed: false
  - kind: clairpostgres
    managed: false
  - kind: horizontalpodautoscaler
    managed: false
  - kind: mirror
    managed: false
EOF

