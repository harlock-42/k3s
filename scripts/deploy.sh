#!/bin/bash

source ./scripts/colors.sh

NS=$1
POD=$2
echo ""
check_path_exists() {
    local path="$1"
    if [ ! -e "$path" ]; then
        echo -e "${RED}Erreur${NC} : Le chemin $path n'existe pas."
        exit 1
    fi
}

docker_access_token() {
    local USERNAME=$1
    local PASSWORD=$2

    # URL de l'API Docker Hub pour la connexion
    URL="https://hub.docker.com/v2/users/login"

    local DATA='{"username": "'"$USERNAME"'", "password": "'"$PASSWORD"'"}'
    # Envoi de la requête POST avec curl
    RESPONSE=$(curl -X POST \
        -H "Content-Type: application/json" \
        -d "$DATA" \
        "$URL"
    )

    local TOKEN=$(echo "$RESPONSE" | jq -r '.token')

    echo "$TOKEN"
}

get_latest_tag() {
    local PSEUDO=$1
    local TOKEN=$2
    local IMAGE_NAME=$3
    
    local TAGS_LIST=()

    local PAGE_SIZE=100

    local page=1
    while true; do
        # Request tags
        local RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "https://hub.docker.com/v2/repositories/${PSEUDO}/${IMAGE_NAME}/tags/?page=$PAGE&page_size=$PAGE_SIZE")
        # Extraction des tags avec jq et stockage dans un tableau
        if [[ "$RESPONSE" == *"404: object not found"* ]]; then
            TAGS_LIST+=(0)
            break
        fi
        local TAGS=($(jq -r '.results[].name' <<< "$RESPONSE"))
        for tag in "${TAGS[@]}"; do
            TAGS_LIST+=($tag)
        done
        if [[ ${#TAGS[@]} -lt $PAGE_SIZE ]]; then
            break
        fi
        # Next page
        ((page++))
    done

    local INT_TAGS=()
    for tag in "${TAGS_LIST[@]}"; do
        # Check if the tag contains only digits
        if [[ "$tag" =~ ^[0-9]+$ ]]; then
            # Add the tags 
            INT_TAGS+=("$tag")
        fi
    done

    # If INT_TAGS is empty, return 0
    if [[ ${#INT_TAGS[@]} -eq 0 ]]; then
        echo "0"
    else
        # Get the biggest Tag
        local max_tag=$(printf '%s\n' "${INT_TAGS[@]}" | sort -V | tail -n 1)
        echo $max_tag
    fi

}

push_docker_image() {
    local DOCKER_PSEUDO=$1
    local DOCKER_TOKEN=$2
    local IMG_NAME=$3
    local NEW_TAG=$4

    # Authentification avec Docker Hub
    echo "$DOCKER_TOKEN" | docker login --username "$DOCKER_PSEUDO" --password-stdin

    # Push de l'image avec le nouveau tag
    docker push "$DOCKER_PSEUDO/$IMG_NAME:$NEW_TAG"
}

./scripts/check_pod.sh $NS $POD

if [ "$?" -eq 1 ]; then
    ./scripts/display_namespaces_and_pods.sh
    echo -e "${LIGHT_RED}Error:${NC} ${LIGHT_MAGENTA}${POD}${NC} doesn't exist in namespace ${LIGHT_MAGENTA}${NS}${NC}"
    exit 1
fi

echo "return $?"

source /opt/k3s/.env.docker
set -a
source /opt/environments/$NS/$POD/.env
if [ $? -ne 0 ]; then
    echo "Error: /opt/environments/$NS/$POD/.env file not found"
    exit 1
fi
set +a
export NS
export POD
IMG_NAME="$NS-$POD"
export IMG_NAME

git clone $GIT_URL /opt/gits/$NS-$POD
cd /opt/gits/$NS-$POD
git checkout $GIT_BRANCH
git pull
cp /opt/environments/$NS/$POD/.env .

DOCKER_ACCESS_TOKEN=$(docker_access_token $DOCKER_PSEUDO $DOCKER_TOKEN)
NEW_TAG=$(get_latest_tag $DOCKER_PSEUDO $DOCKER_ACCESS_TOKEN $IMG_NAME)
get_latest_tag $DOCKER_PSEUDO $DOCKER_ACCESS_TOKEN $IMG_NAME
((NEW_TAG++))

docker compose -f docker-compose.prod.yml build $POD
if [ $? -ne 0 ]; then
    echo "Error: docker-compose.prod.yml file not found"
    exit 1
fi
echo "TAG= $NEW_TAG"
docker tag $IMG_NAME $DOCKER_PSEUDO/$IMG_NAME:$NEW_TAG
push_docker_image "$DOCKER_PSEUDO" "$DOCKER_TOKEN" "$IMG_NAME" "$NEW_TAG"
kubectl set image deployment/$POD $POD=$DOCKER_PSEUDO/$NS-$POD:$NEW_TAG --namespace=$NS