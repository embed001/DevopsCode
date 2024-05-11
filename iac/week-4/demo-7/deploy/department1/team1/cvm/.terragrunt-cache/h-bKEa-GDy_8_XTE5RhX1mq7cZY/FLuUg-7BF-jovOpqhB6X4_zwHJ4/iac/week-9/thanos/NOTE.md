# How

1. install k3s

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san ${public_ip}" sh -s - server --write-kubeconfig-mode 644 --disable=traefik
```

1. init
```
terraform init
```

1. set env
```
export TF_VAR_secret_id=
export TF_VAR_secret_key=
```

1. apply

```
terraform apply -auto-approve
```

1. create cos secret
```
kubectl create ns monitoring

kubectl create secret generic thanos-objectstorage --from-file=thanos.yaml=./kube-prometheus-stack/object-store.yaml -n monitoring --dry-run=client -o yaml | kubectl apply -f -
```

1. install kube-prometheus-stack for cluster1
```
helm upgrade -i kube-prometheus-stack -n monitoring --create-namespace prometheus-community/kube-prometheus-stack -f ./kube-prometheus-stack/cluster1-values.yaml
```

## Observe cluster
1. install kube-prometheus-stack for cluster2
```
helm upgrade -i kube-prometheus-stack -n monitoring --create-namespace prometheus-community/kube-prometheus-stack -f ./kube-prometheus-stack/cluster-observe.yaml
```

1. deploy thanos

```
kubectl create ns thanos
```

1. edit thanos-query-deployment.yaml add remote cluster sidecar endpoint

```
# add remote cluster
- --endpoint=119.28.189.152:30901
```


# 注意

1. 生产：将 Thanos Service GRPC 端口配置安全组访问限制，只能通过内网 VPC 内网访问
1. 采集集群可以只部署 Prometheus，不需要部署 Grafana
1. 观测集群部署 Grafana、Prometheus、Thanos Query、Thanos Sidecar、Thanos Receiver


# 参考

https://medium.com/hiredscore-engineering/using-thanos-to-store-prometheus-on-many-kubernetes-clusters-fd24b63873d8

https://www.infracloud.io/blogs/prometheus-ha-thanos-sidecar-receiver/

https://huisebug.github.io/2023/06/28/kube-prometheus-thanos/

youtube 演讲视频

TSDB: https://ganeshvernekar.com/blog/prometheus-tsdb-the-head-block/

https://p8s.io/docs/thanos/query-frontend/