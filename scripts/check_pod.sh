#!/bin/bash

NS=$1
POD=$2

main() {
    NAMESPACE=$1
    POD=$2
    local pod_found

    pod_found=0

    depl_count=0
    depl_names=()
    local deployment=$(kubectl -n $NAMESPACE get deployments -o=jsonpath='{.items[*].metadata.name}')
    if [ -z "$deployment" ]; then
        exit 1
    fi

    for d in $deployment; do
        if [ "$d" == "$POD" ]; then
            pod_found=1
        fi
    done
    
    if [ "$pod_found" -eq 0 ]; then
        exit 1
    fi
}

main $NS $POD