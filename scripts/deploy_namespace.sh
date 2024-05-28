#!/bin/bash


NS=$1

if [ "$NS" = "default" ]; then
    echo "Namespace default cannot be deployed"
    exit 1
fi

deployments=()
# Récupérer les noms de tous les déploiements

readarray -t deployments < <(kubectl -n $1 get deployments --no-headers -o custom-columns=":metadata.name")

# Afficher les noms des déploiements
for deployment in "${deployments[@]}"; do
    ./scripts/deploy.sh $NS $deployment &
done

wait

echo "all pods are deployed"