#!/bin/bash

export NS=$1

source ./scripts/colors.sh
get_subdirectories() {
    local path="$1"
    # Utilise find pour obtenir la liste des sous-répertoires et exclut les fichiers
    # Utilise sed pour supprimer le chemin parent
    # Utilise sort pour trier les résultats
    find "$path" -mindepth 1 -maxdepth 1 -type d | sed "s|^$path/||"
}

# Utilisation de la fonction pour récupérer les sous-répertoires
directory="./namespaces"
subdirectories=$(get_subdirectories "$directory")

# Vérifier si NS est inclus dans le tableau des sous-répertoires
ns_found=false
for subdir in $subdirectories; do
    if [ "$subdir" = "$NS" ]; then
        ns_found=true
        break
    fi
done

if [ "$ns_found" = false ]; then
    ./scripts/display_namespaces_and_pods.sh
    echo ""
    echo -e "${LIGHT_RED}Error${NC}: \"${LIGHT_MAGENTA}$NS${NC}\" namespace does not exists"
    exit 1
else
    exit 0
fi