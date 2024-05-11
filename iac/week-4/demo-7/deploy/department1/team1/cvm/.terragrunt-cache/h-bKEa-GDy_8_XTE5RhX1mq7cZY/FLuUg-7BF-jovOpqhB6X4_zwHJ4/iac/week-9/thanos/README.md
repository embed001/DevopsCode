# How to use it

1. Init

```
terraform init
```

2. Set env

```
export TF_VAR_secret_id=
export TF_VAR_secret_key=
```

3. Apply

```
terraform apply -auto-approve
```

4. 打开 Cluster-2 Grafana: Kubernetes / Compute Resources / Namespace (Pods)，配置 Dashboard，将 cluster 修改为可见。

# What it does

## Cluster-1

- 安装 Prometheus Operator
  - 配置 Thanos sidecar
- NodePort 方式暴露 Thanos sidecar

## Cluster-2

- 安装 Prometheus Operator
  - 配置 Thanos sidecar
- Grafana 添加 Thanos 数据源
- 配置 Thanos Store
  - Cluster-1 sidecar
  - Cluster-2 self sidecar

## COS

- 创建 COS Bucket

# Destroy

1. 必须先删除 k3s state

```
terraform state rm 'module.k3s_2'
terraform state rm 'module.k3s_1'
```

2. 执行 terraform destroy

```
terraform destroy -auto-approve
```

# TODO
