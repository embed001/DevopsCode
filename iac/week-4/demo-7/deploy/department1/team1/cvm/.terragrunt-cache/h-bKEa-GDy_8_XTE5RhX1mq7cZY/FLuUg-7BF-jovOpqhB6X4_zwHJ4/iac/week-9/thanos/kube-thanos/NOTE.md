1. create ns
```
kubectl create ns thanos
```

1. thanos-query-deployment.yaml add
```
- --endpoint=dnssrv+_grpc._tcp.119.28.189.152:30901
```

1. create tencent cos config secret:

```
kubectl create secret generic thanos-objectstorage --from-file=thanos.yaml=./kube-prometheus-stack/object-store.yaml -n thanos --dry-run=client -o yaml | kubectl apply -f -
```

1. apply thanos deployment:

```
kubectl apply -f kube-thanos/manifest -n thanos
```