#!/bin/bash

source ./scripts/colors.sh

path=namespaces/

get_namespaces() {
    local path="$1"
    # Utilise find pour obtenir la liste des sous-répertoires et basename pour supprimer le chemin parent
    find "$path" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do basename "$dir"; done
}

get_pods() {
    local path="$1"
    find "$path" -type f \( -name "*.statefulset.yaml" -o -name "*.deployment.yaml" \) | while read -r file; do basename "$file" | sed -e 's/.statefulset.yaml$//' -e 's/.deployment.yaml$//'; done
}

subdirectories=$(get_namespaces "$path")
for subdir in $subdirectories; do
    echo -e "${LIGHT_GREEN}$subdir${NC}"
    pods=$(get_pods "./namespaces/$subdir")
    for pod in $pods; do
        echo -e "    |__ $pod"
    done
done
