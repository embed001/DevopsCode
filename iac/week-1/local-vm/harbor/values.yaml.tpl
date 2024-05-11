externalURL: https://harbor.${domain}
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    additionalLabels:
      release: kube-prometheus-stack
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: "harbor-secret-tls"
      notarySecretName: "notary-secret-tls"
  ingress:
    hosts:
      core: harbor.${domain}
      notary: notary.${domain}
    className: gitlab-nginx
    annotations:
      kubernetes.io/tls-acme: "true"
      cert-manager.io/issuer: "harbor-issuer"