# Get Start

```
terraform init
export TF_VAR_secret_id=
export TF_VAR_secret_key=
# (可选)设置飞书机器人 URL，例如：https://open.feishu.cn/open-apis/bot/v2/hook/xxx
export TF_VAR_feishu_url=
terraform apply -auto-approve
```

# KEDA

```
# 删除旧的 HPA
kubectl delete hpa week9-app-hpa -n app
# 创建 KEDA ScaledObject
kubectl apply -f keda/keda-scaled-object-prometheus.yaml -n app
```

# Destroy

```
# 先删除 k3s state
terraform state rm 'module.k3s'
terraform destroy -auto-approve
```
