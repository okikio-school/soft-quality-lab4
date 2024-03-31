#!/bin/bash

# Default credentials, replace these with your default Docker Hub credentials
DEFAULT_DOCKER_USERNAME="default-docker-username"
DEFAULT_DOCKER_PASSWORD="default-docker-password"

# Prompt for Docker credentials with defaults
read -p "Enter Docker Username [${DEFAULT_DOCKER_USERNAME}]: " DOCKER_USERNAME
DOCKER_USERNAME=${DOCKER_USERNAME:-$DEFAULT_DOCKER_USERNAME}

read -sp "Enter Docker Password [default is hidden]: " DOCKER_PASSWORD
echo
DOCKER_PASSWORD=${DOCKER_PASSWORD:-$DEFAULT_DOCKER_PASSWORD}

# Secret name and namespace for Kubernetes
SECRET_NAME="kaniko-secret" # or change to your preferred secret name
NAMESPACE="default" # Adjust to your target namespace
AUTHS_URL="https://index.docker.io/v1/"

# Generate Docker config.json
DOCKER_CONFIG_DIR=$(mktemp -d)
CONFIG_JSON="${DOCKER_CONFIG_DIR}/config.json"

cat <<EOF > ${CONFIG_JSON}
{
  "auths": {
    "${AUTHS_URL}": {
      "username": "${DOCKER_USERNAME}",
      "password": "${DOCKER_PASSWORD}",
      "auth": "$(echo -n ${DOCKER_USERNAME}:${DOCKER_PASSWORD} | base64)"
    }
  }
}
EOF

# Create the Kubernetes secret
kubectl create secret generic ${SECRET_NAME} \
  --from-file=.dockerconfigjson=${CONFIG_JSON} \
  --type=kubernetes.io/dockerconfigjson \
  --namespace=${NAMESPACE}

# Cleanup
rm -rf ${DOCKER_CONFIG_DIR}

echo "Secret '${SECRET_NAME}' created in namespace '${NAMESPACE}'."
