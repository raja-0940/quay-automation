#!/bin/bash

# deploy build properties
source ../build-properties.sh

## creating certificate ##

# Generate the rootCA private key
openssl genrsa -out rootCA.key 2048

# Generate the root CA certificate
openssl req -new -nodes -x509 -days 1024 -key rootCA.key -sha256 -out rootCA.pem \
	-subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORG/OU=$ORG_UNIT/CN=$COMMON_NAME"

## signing certificate ##

# Generate the server key
openssl genrsa -out ssl.key 2048

# Generate a signing request
openssl req -new -key ssl.key -out ssl.csr \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORG/OU=$ORG_UNIT/CN=$COMMON_NAME"

# create openssl.cnf configuration file
cat > openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $COMMON_NAME
IP.1 = $BASTION_IP
EOF

# Use the configuration file to generate the certificate ssl.cert
openssl x509 -req -in ssl.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ssl.cert -days 356 -extensions v3_req -extfile openssl.cnf

