#!/bin/bash

apply_yml_files() {
    # Définir le chemin de base à partir duquel chercher les fichiers
    local base_path="$1"
	local filename="$2"

    # Trouver tous les fichiers .pv.yml dans les sous-répertoires et exécuter kubectl apply pour chaque fichier
    find "$base_path" -type f -name "$filename" -exec echo "Applying configuration from {}" \; -exec kubectl apply -f {} \;
}

execute_files() {
    # Définir le chemin de base à partir duquel chercher les fichiers
    local base_path="$1"
    local filename="$2"

    # Trouver tous les fichiers correspondant au nom dans les sous-répertoires et les exécuter
    find "$base_path" -type f -name "$filename" -exec echo "Executing script from {}" \; -exec bash {} \;
}

apply_yml_files namespaces "namespace.yaml"
execute_files namespaces "apply_secret.sh"
apply_yml_files namespaces "configmap.yaml"
apply_yml_files namespaces "*.storage-class.yaml"
apply_yml_files namespaces "*.pv.yaml"
apply_yml_files namespaces "*.statefulset.yaml"
apply_yml_files namespaces "*.deployment.yaml"