# Webhook admission
演示当创建的 Pod 没有配置 owner labels 时，创建会被拒绝。

# 安装和初始化
1. kubectl create ns webhook-demo
1. kubectl apply -f k8s-manifests/ca-secret.yaml
1. kubectl apply -f k8s-manifests/webhook-deployment-service.yaml

1. (可选，可以直接使用仓库生成好的证书)
```
./generate-certs.sh
kubectl create ns webhook-demo
kubectl create secret generic webhook-certs --from-file=key.pem=webhook-server-tls.key --from-file=cert.pem=webhook-server-tls.crt -n webhook-demo
export WEBHOOKCA=$(cat certs/ca.crt | openssl base64 -A)
sed -i.bak "s/CHANGE_THIS_CA/$WEBHOOKCA/g" k8s-manifests/ValidatingWebhookConfiguration.yaml
```
1. kubectl apply -f k8s-manifests/ValidatingWebhookConfiguration.yaml

# 测试
1. kubectl create ns webhook-test-ns
1. kubectl annotate ns webhook-test-ns example.com/validate=true
1. kubectl apply -f k8s-manifests/pod-denied.yaml -n webhook-test-ns  # 没有配置 labels，会被拒绝
1. kubectl apply -f k8s-manifests/pod-allow.yaml -n webhook-test-ns  # 配置了 labels，会被允许
1. deployment：kubectl apply -f k8s-manifests/deployment-denied.yaml -n webhook-test-ns # 虽然 deployment 能创建，但是 Pod 无法被调度