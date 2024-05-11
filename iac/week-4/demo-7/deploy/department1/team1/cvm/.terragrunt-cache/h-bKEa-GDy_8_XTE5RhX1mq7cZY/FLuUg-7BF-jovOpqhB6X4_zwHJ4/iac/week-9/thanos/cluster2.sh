#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create ns thanos

# secret for thanos query
kubectl create secret generic thanos-objectstorage --from-file=thanos.yaml=/tmp/object-store.yaml -n thanos --dry-run=client -o yaml | kubectl apply -f -

# secret for prometheus sidecar
kubectl create ns monitoring
kubectl create secret generic thanos-objectstorage --from-file=thanos.yaml=/tmp/object-store.yaml -n monitoring --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update

helm upgrade -i kube-prometheus-stack -n monitoring --create-namespace prometheus-community/kube-prometheus-stack -f /tmp/values.yaml

kubectl apply -f /tmp/kube-thanos -n thanos
kubectl apply -f /tmp/thanos-query-deployment.yaml -n thanos
