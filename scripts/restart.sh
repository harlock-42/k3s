#!/bin/bash

NS=$1
POD=$2

main() {
    if [[ -n "$2" ]]; then
        kubectl -n $1 rollout restart deployment/$2
    else
        kubectl -n $1 rollout restart deployment
    fi
}

main $NS $POD