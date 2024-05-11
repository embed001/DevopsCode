apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
  namespace: argocd
  annotations:
    app.kubernetes.io/part-of: argocd
stringData:
  github_token: "${github_personal_token}"
type: Opaque
