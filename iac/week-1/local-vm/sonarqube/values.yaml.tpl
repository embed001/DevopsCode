account:
  adminPassword: "${sonar_password}"
  currentAdminPassword: admin

ingress:
  enabled: true
  hosts:
    - name: "sonar.${domain}"
  ingressClassName: gitlab-nginx

prometheusMonitoring:
  podMonitor:
    enabled: true
    namespace: monitoring

prometheusExporter:
  enabled: true