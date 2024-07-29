#!/bin/bash

# creating and signing ssl certificate
source ./creating_ssl_certs_quay.sh

# check for config.yaml, ssl.cert nd ssl.key
if [ -f ./config.yaml ]; then
	echo "config.yaml is available"
else
	echo "Please create config.yaml file"
	exit 1
fi

# Create a config bundle secret
if [ $(oc project | cut -d ' ' -f3 | tr -d '"') == "quay-registry" ]; then
	echo "We are working under quay-registry namespace"
	oc create secret generic --from-file config.yaml=./config.yaml --from-file ssl.cert=./ssl.cert --from-file ssl.key=./ssl.key test-config-bundle
else
	echo "Create or switch to quay-registry project and create config-bundle-secret"
	oc project quay-registry
	oc create secret generic --from-file config.yaml=./config.yaml --from-file ssl.cert=./ssl.cert --from-file ssl.key=./ssl.key test-config-bundle
fi

# Create quay-registry.yaml file with unmanaged tls component
cat <<EOF | oc apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: quayreg3
  namespace: quay-registry
spec:
  configBundleSecret: test-config-bundle
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
    managed: false
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


