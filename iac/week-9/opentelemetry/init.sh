#!/bin/bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
# install kube-prometheus-stack, include prometheus, alertmanager, grafana, loki
helm upgrade -i kube-prometheus-stack -n monitoring --create-namespace prometheus-community/kube-prometheus-stack -f /tmp/values.yaml

# install loki
helm upgrade --install loki grafana/loki-stack -n monitoring

# install tempo
helm upgrade --install tempo grafana/tempo -n monitoring

# deploy opentelemetry python app
kubectl apply -f /tmp/microservice.yaml

# deploy without opentelemetry python app
kubectl apply -f /tmp/microservice.raw.yaml
