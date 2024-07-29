#!/bin/bash

# creating and signing ssl certificate
source ./creating_ssl_certs_quay.sh

# check for config.yaml, ssl.cert nd ssl.key
if [ -f ./config.yaml ]; then
	echo "config.yaml is available"
	if [ -d ./openssl/ ]; then
		echo "openssl directory is created"
		ls -l ./openssl/
		mv ./openssl/ssl.cert .
		mv ./openssl/ssl.key .
	else
		echo "Create openssl certificates"
	fi
else
	echo "Create config.yaml file"
	cat > config.yaml <<EOF
SERVER_HOSTNAME: rajakumar.apps.quay3113.cp.fyre.ibm.com
PREFERRED_URL_SCHEME: https
FEATURE_UI_V2: true
FEATURE_UI_V2_REPO_SETTINGS: true
FEATURE_AUTO_PRUNE: true
ROBOTS_DISALLOW: false
BROWSER_API_CALLS_XHR_ONLY: false
SUPER_USERS:
  - quay
EOF
        if [ -d ./openssl/ ]; then
                echo "openssl directory is created"
                ls -l ./openssl/
                mv ./openssl/ssl.cert .
                mv ./openssl/ssl.key .
        else
                echo "Create openssl certificates"
        fi
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
cat > quay-registry.yaml <<EOF
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: quayreg39
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

oc create -f quay-registry.yaml

