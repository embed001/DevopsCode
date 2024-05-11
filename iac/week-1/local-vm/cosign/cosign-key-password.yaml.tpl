apiVersion: v1
kind: Secret
metadata:
  name: cosign-key-password
  labels:
    "jenkins.io/credentials-type": "secretText"
  annotations:
    "jenkins.io/credentials-description" : "secret text credential from Kubernetes for cosign key password"
type: Opaque
stringData:
  text: ${cosign_password}