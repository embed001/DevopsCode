#!/bin/bash  

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# PG client
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update -y
sudo apt-get -y install -y postgresql-client

# PostgreSQL 用户名，密码和主机名  
PGUSER="root123"
PGPASSWORD="Root123$"
PGHOST="${pg_private_ip}"
  
# 数据库名  
DB1="registry"

# 连接到PostgreSQL服务器并创建数据库  
create_db(){
    PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$1'" | grep -q 1 || PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d postgres -c "CREATE DATABASE $1"
}

# 创建数据库
create_db $DB1

echo "Databases created successfully"

# install ingress-nginx
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

kubectl create namespace harbor
kubectl apply -f /tmp/cloudflare-token.yaml
kubectl apply -f /tmp/issuer.yaml

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait --version "4.7.2"