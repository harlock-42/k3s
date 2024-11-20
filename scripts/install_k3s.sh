#!/bin/bash

function check_virtualization() {
	output=$(grep -E 'vmx|svm' /proc/cpuinfo)
	if [ -z "$output" ]; then
		echo "The virtualization on your os seems to be not activate. Check your BIOS to activiate the virtualization"
		exit 1
	fi
}

function install_kubectl() {
	if command -v kubectl >/dev/null 2>&1; then
		echo "kubectl is already installed."
	else
		curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
		chmod +x ./kubectl
		sudo mv ./kubectl /usr/local/bin/kubectl
		kubectl version --client
	fi
}

function install_and_setup_firewall() {
	# install ufw
	sudo apt-get update && sudo apt-get install ufw
	# setup firewall
	sudo ufw allow ssh
	sudo ufw allow 6443/tcp
	sudo ufw allow 10250/tcp
	sudo ufw allow 8080/tcp
	sudo ufw allow from 10.42.0.0/16
	sudo ufw allow from 10.43.0.0/16
	sudo ufw enable
}

function install_curl() {
	if which curl >/dev/null; then
		echo "curl is already installed"
	else
		sudo apt install -y curl
	fi
}

function install_k3s() {
	if systemctl is-active --quiet k3s; then
        echo "k3s is already installed."
    else
		curl -sfL https://get.k3s.io | sh -
    fi
}

function install_helm() {
	if ! helm version --short &> /dev/null; then
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
	else
		echo "Helm is already installed."
	fi
}

function main() {
	install_and_setup_firewall
	install_curl
	install_k3s
	install_helm

	
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

	if ! helm repo list | grep -q ingress-nginx; then
		helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
		helm repo update
	fi
	# TODO Add a condition to check if the file ~/.kube/config doesn't exist
	mkdir -p ~/.kube
	sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
	
	if ! helm list | grep -q quickstart; then
		helm install quickstart ingress-nginx/ingress-nginx
		helm repo add jetstack https://charts.jetstack.io
		helm repo update
		# helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.5.4 --set installCRDs=true
	fi
}

main

