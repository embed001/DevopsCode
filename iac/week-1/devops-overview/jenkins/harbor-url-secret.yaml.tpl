apiVersion: v1
kind: Secret
metadata:
  name: harbor-url
  labels:
    "jenkins.io/credentials-type": "secretText"
  annotations:
    "jenkins.io/credentials-description" : "secret text credential from Kubernetes"
type: Opaque
stringData:
  text: harbor.${domain}