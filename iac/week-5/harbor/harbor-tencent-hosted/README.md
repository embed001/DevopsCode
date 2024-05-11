# 使用

1. 设置腾讯云 Secret ID 和 Secret KEY

```
export TF_VAR_secret_id=
export TF_VAR_secret_key=
```

2. 初始化
```
terraform init
terraform apply -auto-approve
```

3. 访问输出的 harbor_url，账号：admin，密码：Harbor12345

## 故障排查

1. 推送镜像提示 500 报错，这是由于 COS 一致性导致的

参考：https://cloud.tencent.com/developer/article/1855894

解决：提交工单，说明修改 COS 为强一致性即可。

## 清理

1. 清理全部资源

```
terraform destroy -auto-approve
```

2. 清理部分资源

```
terraform state list
# 可不执行
terraform destroy -target='module.k3s' -auto-approve
terraform destroy -target='module.helm' -auto-approve
# 销毁 cvm
terraform destroy -target='module.cvm' -auto-approve
terraform destroy -target='module.cloudflare' -auto-approve
terraform destroy -target='module.redis' -auto-approve
terraform destroy -target='module.postgresql' -auto-approve

# 提交了工单处理了强一致性的 COS 保留
terraform destroy -target='module.cos'
```