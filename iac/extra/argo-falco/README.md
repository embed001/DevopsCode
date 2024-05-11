# 安装 Falco
kubectl create ns falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm upgrade --install falco falcosecurity/falco \
  --namespace falco \
  --set falcosidekick.enabled=true \
  --set driver.kind=ebpf \
  --set falcosidekick.webui.enabled=true \
  --set falcosidekick.config.webhook.address=http://webhook-falco-eventsource-svc.argo-events.svc.cluster.local:12000/falco

# 测试
kubectl create deployment alpine --image=alpine -- sh -c "sleep 6000"
kubectl get pods
// 进入终端，产生安全事件
kubectl exec -it alpine /bin/sh

查看安全事件：kubectl port-forward svc/falco-falcosidekick-ui 2802:2802 -n falco
admin/admin