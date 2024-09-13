#!/bin/bash

# Source build properties
source ../build-properties.sh

# install podman if not available
if [ $(podman --version | cut -d ' ' -f1) == "podman" ]; then
  echo "using $(podman --version)"
  # login to registry.redhat.io and brew.registry.redhat.io registries
  podman login -u ${REDHAT_USER} -p ${REDHAT_PASS} registry.redhat.io
  podman login -u ${REDHAT_USER} -p ${REDHAT_PASS} brew.registry.redhat.io
else
  yum install -y podman
  echo "using $(podman --version)"
  # login to registry.redhat.io and brew.registry.redhat.io registries
  podman login -u ${REDHAT_USER} -p ${REDHAT_PASS} registry.redhat.io
  podman login -u ${REDHAT_USER} -p ${REDHAT_PASS} brew.registry.redhat.io
fi

# create quay root directory
mkdir quay
export QUAY=/root/quay

# create directory for quay-db and provide required permissions
mkdir -p $QUAY/postgres-quay
setfacl -m u:26:-wx $QUAY/postgres-quay

# create a config directory for to store config files
mkdir $QUAY/config
mv ./config.yaml $QUAY/config

# create a directory for the storage and provide required permissions
mkdir $QUAY/storage
setfacl -m u:1001:-wx $QUAY/storage

# run quay db container using postgresql image
podman run -d --rm --name postgresql-quay \
  -e POSTGRESQL_USER=quayuser \
  -e POSTGRESQL_PASSWORD=quaypass \
  -e POSTGRESQL_DATABASE=quay \
  -e POSTGRESQL_ADMIN_PASSWORD=adminpass \
  -p 5432:5432 \
  -v $QUAY/postgres-quay:/var/lib/pgsql/data:Z \
  registry.redhat.io/rhel8/postgresql-13:1-109
podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U postgres'

# run redis container
podman run -d --rm --name redis \
    -p 6379:6379 \
    -e REDIS_PASSWORD=strongpassword \
    registry.redhat.io/rhel8/redis-6:1-110

# run quay app container by mounting config and storage volumes
podman run -d --rm -p 80:8080 -p 443:8443 --name=quay \
  -v /root/quay/config:/conf/stack:Z \
  -v /root/quay/storage:/datastorage:Z \
  ${STANDALONE_QUAY_IMAGE}

sleep 60
podman ps -a

