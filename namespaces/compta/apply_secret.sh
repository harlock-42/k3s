#!/bin/bash

ENV_FILE=$(realpath "/opt/k3s/.env")
NAMESPACE=compta

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

		echo "VAR = $COMPTA_JWT_SECRET"
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
				--from-literal=DATABASE_URL=$COMPTA_DATABASE_URL \
				--from-literal=JWT_SECRET=$COMPTA_JWT_SECRET \
				--from-literal=PASSPHRASE_REFRESH=$COMPTA_PASSPHRASE_REFRESH \
				--from-literal=PASSPHRASE_KEY=$COMPTA_PASSPHRASE_KEY
		else
			echo "secret/$NAMESPACE-secret unchanged"
		fi
	else
		echo "secret/docker-hub-secret unchanged"
		echo "secret/$NAMESPACE-secret unchanged"
    fi
}

apply_secret