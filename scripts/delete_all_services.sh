# /bin/bash

kubectl delete -f nestjs-deployment.yaml --ignore-not-found=true
kubectl delete -f front-admin-deployment.yaml --ignore-not-found=true
kubectl delete -f front-deployment.yaml --ignore-not-found=true
kubectl delete -f postgres-statefulset.yaml --ignore-not-found=true
kubectl delete -f postgres-storage-class.yaml --ignore-not-found=true
kubectl delete pvc --all -n formwish
kubectl delete -f postgres-pv.yaml --ignore-not-found=true
kubectl delete -f configmap.yaml --ignore-not-found=true
kubectl delete -f secret.yaml --ignore-not-found=true
kubectl delete secret docker-hub-secret --ignore-not-found=true
kubectl delete -f formwish-namespace.yaml --ignore-not-found=true
# install cert-manager first
# if kubectl get secret cloudflare-secret --namespace  >/dev/null 2>&1; then
# 	kubectl delete -f cloudflare-secret.yaml
# fi