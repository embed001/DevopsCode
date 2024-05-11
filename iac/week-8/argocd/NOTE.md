1. 调试 notifcation template：argocd admin notifications template notify app-sync-succeeded vote-pull-request-dev-6 -n argocd
2. 触发 notifcation：argocd admin notifications template notify app-sync-succeeded vote-pull-request-dev-6 -n argocd --recipient github-webhook

## list generated
```
apiVersion: ...
kind: ApplicationSet
metadata:
  name: ...
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      # If the mapping is one-to-one, you could even have only the folder attribute 
      - cluster: dev1
        folder: dev1
      - cluster: dev2
        folder: dev2
      - ...
  template:
    metadata:
      name: '{{cluster}}-myapp'
    spec:
      project: "my-project"
      source:
        repoURL: https://www.test-gitlab.com/repo1/
        targetRevision: HEAD
        path: '{{folder}}'
      destination:
        name: '{{cluster}}'
        namespace: ...
```