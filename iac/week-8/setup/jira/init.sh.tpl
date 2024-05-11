#!/bin/bash

setup_cli() {
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

install_chart() {
    helm repo add atlassian-data-center https://atlassian.github.io/data-center-helm-charts && helm repo update
    helm upgrade --install jira atlassian-data-center/jira --namespace jira --version 1.16.1 --values /tmp/jira-values.yaml --create-namespace
    # install ingress-nginx
    helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace --wait --version "4.7.2"
}

main() {
    setup_cli
    install_chart
}

main