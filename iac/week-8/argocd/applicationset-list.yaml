apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: vote-applicationset
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - cluster: dev
            folder: dev
          - cluster: main
            folder: main
          - cluster: staging
            folder: staging
  template:
    metadata:
      name: "vote-{{cluster}}"
      annotations:
        # result microservice
        argocd-image-updater.argoproj.io/result.allow-tags: regexp:^{{cluster}}
        argocd-image-updater.argoproj.io/result.helm.image-name: RESULT.IMAGE
        argocd-image-updater.argoproj.io/result.helm.image-tag: RESULT.TAG
        argocd-image-updater.argoproj.io/result.pull-secret: pullsecret:argocd/harbor-pull-secret
        # vote microservice
        argocd-image-updater.argoproj.io/vote.allow-tags: regexp:^{{cluster}}
        argocd-image-updater.argoproj.io/vote.helm.image-name: VOTE.IMAGE
        argocd-image-updater.argoproj.io/vote.helm.image-tag: VOTE.TAG
        argocd-image-updater.argoproj.io/vote.pull-secret: pullsecret:argocd/harbor-pull-secret
        # worker microservice
        argocd-image-updater.argoproj.io/worker.allow-tags: regexp:^{{cluster}}
        argocd-image-updater.argoproj.io/worker.helm.image-name: WORKER.IMAGE
        argocd-image-updater.argoproj.io/worker.helm.image-tag: WORKER.TAG
        argocd-image-updater.argoproj.io/worker.pull-secret: pullsecret:argocd/harbor-pull-secret
        # image list
        argocd-image-updater.argoproj.io/image-list: result=harbor.${prefix}.${domain}/vote/result, vote=harbor.${prefix}.${domain}/vote/vote, worker=harbor.${prefix}.${domain}/vote/worker
        argocd-image-updater.argoproj.io/update-strategy: latest
        argocd-image-updater.argoproj.io/write-back-method: git
        argocd-image-updater.argoproj.io/git-branch: main
    spec:
      project: default
      source:
        repoURL: "https://github.com/devops-advanced-camp/vote-helm.git"
        targetRevision: HEAD
        path: "week-8"
        helm:
          valueFiles:
            - "env/{{folder}}/values.yaml"
      destination:
        name: "{{cluster}}"
        namespace: "{{cluster}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
