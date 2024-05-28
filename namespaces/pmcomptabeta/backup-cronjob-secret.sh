#!/bin/bash

ENV_FILE=$(realpath "/opt/k3s/.env")
NAMESPACE=pmcomptabeta

apply_secret() {
	# Load variables from the Env file
	source "$ENV_FILE"
	
	# Check if the Env file exists
	if [ ! -f "$ENV_FILE" ]; then
		echo "Error: Cannot find $ENV_FILE file."
		exit 1
	fi

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


	kubectl create secret generic backup-cronjob \
		--namespace=$NAMESPACE \
		--from-literal=POSTGRES_PASSWORD=$PMCOMPTA_POSTGRES_PASSWORD \
		--from-literal=HOST_PASSWORD=$PMCOMPTA_HOST_PASSWORD
}

apply_secret
