#!/bin/bash

NS=$1
POD=$2

apply_yml_files() {
    local base_path="$1"
	local filename="$2"

    # Find all files filename in the sub-directory of base_path and execute kubectl apply for every files
    find "$base_path" -type f -name "$filename" -exec echo "Applying configuration from {}" \; -exec kubectl apply -f {} \;
}

main() {
    if [[ -n "$2" ]]; then
        kubectl apply -f namespaces/$1/${POD}.deployment.yaml
    else
        apply_yml_files namespaces/$1 "*.deployment.yaml"
    fi
}

main $NS $POD