#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add kedacore https://kedacore.github.io/charts

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

helm upgrade -i kube-prometheus-stack -n monitoring --create-namespace prometheus-community/kube-prometheus-stack -f /tmp/values.yaml

helm upgrade -i blackbox-exporter prometheus-community/prometheus-blackbox-exporter -n monitoring --create-namespace

helm upgrade -i prometheus-adapter prometheus-community/prometheus-adapter -n monitoring --create-namespace -f /tmp/adapter-values.yaml

helm upgrade -i keda kedacore/keda --namespace keda --create-namespace

mv /tmp/manifest/prometheusAlert.yaml /tmp/prometheusAlert.yaml

kubectl apply -f /tmp/prometheusAlert.yaml -n monitoring

kubectl create ns app

kubectl apply -f /tmp/manifest -n app

kubectl wait deployment -n app --for condition=Available=True --all --timeout=900s
