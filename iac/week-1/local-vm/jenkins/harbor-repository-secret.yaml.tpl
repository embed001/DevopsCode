apiVersion: v1
kind: Secret
metadata:
  name: harbor-repository
  labels:
    "jenkins.io/credentials-type": "secretText"
  annotations:
    "jenkins.io/credentials-description" : "secret text credential from Kubernetes"
type: Opaque
stringData:
  text: ${harbor_registry}