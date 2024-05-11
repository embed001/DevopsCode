apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: Harbor
      prefix: harbor.${domain}
      api_url: https://harbor.${domain}
      credentials: pullsecret:argocd/regcred