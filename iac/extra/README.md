# 安装
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.2/install.yaml

kubectl patch deployment argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "server",
  "--auth-mode=server"
]}]'

给 default serviceaccount 绑定管理员（仅供测试）：kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=default:default



kubectl -n argo port-forward deployment/argo-server 2746:2746



# 安装 Argo Events
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-events argo/argo-events -n argo-events --create-namespace
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml

## 创建 eventsource
> 注意 Secret
kubectl apply -f iac/extra/argo-event

修改 github-eventsource-svc 为 NodePort 类型，方便测试

```
kubectl patch svc github-eventsource-svc -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 30000, "port": 12000, "protocol": "TCP"}]}}' -n argo-events
```

为 default serviceaccount 绑定权限，否则 sensor 无法创建 workflow：

kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=argo-events:default -n argo-events