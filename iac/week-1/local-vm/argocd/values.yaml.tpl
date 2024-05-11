configs:
  secret:
    argocdServerAdminPassword: $2a$10$.NeEDuo4qmMNzuwHBLMvDuIpvqT52TdzW.1Zg9/dDssaiSRN.xa3u  #password123
  cm:
    timeout.reconciliation: 20s
  params:
    server.insecure: true

server:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: kube-prometheus-stack
  ingress:
    enabled: true
    ingressClassName: gitlab-nginx
    hosts:
      - "argocd.${domain}"

controller:  
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: kube-prometheus-stack

repoServer:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: kube-prometheus-stack

applicationSet:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: kube-prometheus-stack
