#!/bin/bash

ENV_FILE="/opt/k3s/.env"
NAMESPACE=media

# Check if the Env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Cannot find $ENV_FILE file."
    exit 1
fi

# Load variables from the Env file
source "$ENV_FILE"

# create docker secret if it doesn't exist
if ! kubectl get secret docker-hub-secret --namespace $NAMESPACE >/dev/null 2>&1; then
    kubectl create secret docker-registry docker-hub-secret \
        --docker-username=$DOCKER_HUB_USERNAME \
        --docker-password=$DOCKER_HUB_PASSWORD \
        --docker-email=$DOCKER_HUB_EMAIL \
        --docker-server=https://index.docker.io/v1/ \
        --namespace=$NAMESPACE
else
    echo "secret/docker-hub-secret unchanged"
fi