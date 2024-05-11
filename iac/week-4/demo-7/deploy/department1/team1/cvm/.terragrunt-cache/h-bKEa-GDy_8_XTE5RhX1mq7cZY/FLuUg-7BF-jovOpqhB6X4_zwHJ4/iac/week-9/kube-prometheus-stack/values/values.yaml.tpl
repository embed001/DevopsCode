grafana:
  adminPassword: "password123"
  sidecar:
    dashboards:
      provider:
        allowUiUpdates: true
  service:
    type: NodePort
    nodePort: 30080

prometheus:
  prometheusSpec:
    podMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    externalLabels:
      cluster: k3s-hongkong-1
  service:
    type: NodePort

alertmanager:
  enabled: true
  service:
    type: NodePort
    nodePort: 30092
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['...']
      group_wait: 10s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'prometheusalert'
      routes:
      - receiver: 'null'
        matchers:
          - alertname =~ "InfoInhibitor|Watchdog"
    receivers:
    - name: 'null'
    - name: 'prometheusalert'
      webhook_configs:
        - url: 'http://prometheus-alert-center.monitoring:8080/prometheusalert?type=fs&tpl=prometheus-fs&fsurl=${feishu_url}'
    templates:
    - '/etc/alertmanager/config/*.tmpl'

# setup alertmanagerConfiguration name, and then need to deploy alertmanagerConfig
# alertmanager:
#   alertmanagerSpec:
#     alertmanagerConfiguration:
#       name: alertmanager-config

# for k3s only
kubeControllerManager:
  endpoints:
  - ${private_ip}

kubeScheduler:
  endpoints:
  - ${private_ip}

kubeProxy:
  endpoints:
  - ${private_ip}