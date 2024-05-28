#!/bin/bash

get_subdirectories() {
    local base_path="$1"
    local subdirs=()

    # Trouver tous les sous-répertoires (à un niveau de profondeur) dans le répertoire donné
    while IFS= read -r -d $'\0' dir; do
        # Extraire le nom du sous-répertoire
        local subdir_name=$(basename "$dir")
        subdirs+=("$subdir_name")
    done < <(find "$base_path" -mindepth 1 -maxdepth 1 -type d -print0)

    echo "${subdirs[@]}"
}

subdirectories=$(get_subdirectories "./namespaces")

# Convert string to array
IFS=' ' read -r -a subdirectory_array <<< "$subdirectories"

# Itérer sur le tableau des sous-répertoires
echo "Iterating over subdirectories:"
for  in "${subdirectory_array[@]}"; do
    echo "$subdir"
    if ! kubectl get secret docker-hub-secret --namespace $subdir >/dev/null 2>&1; then
        kubectl create secret docker-registry docker-hub-secret \
        --docker-username=$DOCKER_USERNAME \
        --docker-password=$DOCKER_PASSWORD \
        --docker-email=$DOCKER_EMAIL \
        --namespace=$subdir
    fi
done



exit 0

ENV_FILE=".env"

# Check if the Env file exist
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Cannot found $ENV_FILE file."
    exit 1
fi

# Load variables of the Env file
source "$ENV_FILE"

# Env file's variable
required_vars=( \
	NAMESPACE \
	DOCKER_USERNAME \
	DOCKER_PASSWORD \
	DOCKER_EMAIL \
)

# Check every variable if they are not empty and they exist in the Env file
for var in "${required_vars[@]}"; do
    if [[ -z ${!var} ]]; then
        echo "Erreur: Env variable '$var' is not set or emtpy."
        exit 1
    fi
done


if ! kubectl get secret docker-hub-secret --namespace $NAMESPACE >/dev/null 2>&1; then
    kubectl create secret docker-registry docker-hub-secret \
    --docker-username=$DOCKER_USERNAME \
    --docker-password=$DOCKER_PASSWORD \
    --docker-email=$DOCKER_EMAIL \
    --namespace=$NAMESPACE
fi