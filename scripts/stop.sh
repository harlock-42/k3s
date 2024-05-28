#!/bin/bash

NS=$1
POD=$2

delete_yml_files() {
    local base_path="$1"
	local filename="$2"

    # Find all files filename in the sub-directory of base_path and execute kubectl delete for every files
    find "$base_path" -type f -name "$filename" -exec echo "Deleting configuration from {}" \; -exec kubectl delete -f {} \;
}

main() {
    if [[ -n "$2" ]]; then
        kubectl delete -f namespaces/$1/$2.deployment.yaml
    else
        delete_yml_files namespaces/$1 "*.deployment.yaml"
    fi
}

main $NS $POD

