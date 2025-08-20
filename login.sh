#!/bin/bash
 
source ./validation-properties.sh
podman logout ${SRC_REGISTRY} 
echo "Logging into ${SRC_REGISTRY}"
podman login -u ${SRC_REG_USER_NAME} -p ${SRC_REG_PASSWORD} ${SRC_REGISTRY} --tls-verify=false
if ! grep -q `echo "$SRC_REGISTRY" | sed -e 's|^[^/]*//||' -e 's|/.*$||'` "${XDG_RUNTIME_DIR}/containers/auth.json"; then
     echo "Login was not successful $SRC_REGISTRY"
     exit 1
else
     echo "Login is successful to $SRC_REGISTRY"
fi
	 
podman logout ${DEST_REGISTRY}
echo "Logging into ${DEST_REGISTRY}"
podman login -u ${DEST_REG_USER_NAME} -p ${DEST_REG_PASSWORD} ${DEST_REGISTRY} --tls-verify=false
if ! grep -q `echo "$DEST_REGISTRY" | sed -e 's|^[^/]*//||' -e 's|/.*$||'` "${XDG_RUNTIME_DIR}/containers/auth.json"; then
     echo "Login was not successful $DEST_REGISTRY"
     exit 1
else
     echo "Login is successful to $DEST_REGISTRY"
fi
