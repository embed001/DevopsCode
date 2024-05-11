grafana:
  ingress:
    enabled: true
    ingressClassName: gitlab-nginx
    hosts:
      - "grafana.${domain}"
  adminPassword: "${grafana_password}"
  sidecar:
    dashboards:
      provider:
        allowUiUpdates: true

prometheus:
  prometheusSpec:
    podMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
  ingress:
    enabled: true
    ingressClassName: gitlab-nginx
    hosts:
      - "prometheus.${domain}"