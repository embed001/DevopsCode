apiVersion: v1
kind: Secret
metadata:
  name: vote-helm-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: https://github.com/devops-advanced-camp/vote-helm.git
  password: "${github_personal_token}"
  username: "${github_username}"