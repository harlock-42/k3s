INGRESS_PATH=$(realpath "./namespaces/pmcompta/ingress.yaml")

kubectl apply -f ${INGRESS_PATH}