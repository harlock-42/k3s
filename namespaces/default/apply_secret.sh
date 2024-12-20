#!/bin/bash

ENV_FILE=$(realpath "./.env")
NAMESPACE=default

apply_secret() {
	
	# Attempt to get the secret for docker-secret and NAMESPACE-secret, and if one don't exist, create them
    if ! kubectl get secret $NAMESPACE-secret --namespace $NAMESPACE >/dev/null 2>&1 || ! kubectl get secret docker-hub-secret --namespace $NAMESPACE >/dev/null 2>&1; then

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

		# Create the NAMESPACE secret if it doesn't exist
		if ! kubectl get secret $NAMESPACE-secret --namespace $NAMESPACE >/dev/null 2>&1; then
			kubectl create secret generic $NAMESPACE-secret \
				--namespace=$NAMESPACE \
				--from-literal=POSTGRES_USER=$DEFAULT_POSTGRES_USER \
				--from-literal=POSTGRES_PASSWORD=$DEFAULT_POSTGRES_PASSWORD
		else
			echo "secret/$NAMESPACE-secret unchanged"
		fi
	else
		echo "secret/docker-hub-secret unchanged"
		echo "secret/$NAMESPACE-secret unchanged"
    fi
}

apply_secret
