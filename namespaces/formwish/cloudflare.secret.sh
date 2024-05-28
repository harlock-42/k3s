#!/bin/bash

ENV_FILE=$(realpath "/opt/k3s/.env")
NAMESPACE=formwish

apply_secret() {
	
	# Check if the Env file exists
	if [ ! -f "$ENV_FILE" ]; then
		echo "Error: Cannot find $ENV_FILE file."
		exit 1
	fi

	# Load variables from the Env file
	source "$ENV_FILE"

	# Create the NAMESPACE secret if it doesn't exist
	if ! kubectl get secret cloudflare-api-token-secret --namespace cert-manager >/dev/null 2>&1; then
		kubectl create secret generic cloudflare-api-token-secret \
			--namespace="cert-manager" \
			--from-literal=api-token=$FORMWISH_CLOUD_FLARE_API_TOKEN
	else
		echo "secret/cloudflare-api-token-secret unchanged"
	fi
}

apply_secret
