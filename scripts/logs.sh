#!/bin/bash

NS=$1
POD=$2
pod_count=0

# Récupérer la sortie standard de kubectl get pod et stocker les noms des pods dans un tableau
pod_names=()
while IFS= read -r line; do
    # Ignorer la première ligne (en-têtes)
    if [[ "$line" =~ ^NAME ]]; then
        continue
    fi
    # Récupérer le nom du pod à partir de chaque ligne et le stocker dans le tableau
    pod_name=$(echo "$line" | awk '{print $1}')
    if [[ "$pod_name" == "${POD}"* ]]; then
        ((pod_count++))
        pod_names+=("$pod_name")
    fi
done < <(kubectl -n ${NS} get pod --no-headers)

if (( pod_count == 0 )); then
    echo "Error : No pod found with the prefix: '$POD'."
    exit 1
elif (( pod_count > 1 )); then
    echo "Error : Several pod found with the prefix: '$POD'."
    exit 1
else
    kubectl -n $NS logs -f $pod_name
fi