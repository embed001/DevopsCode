#!/bin/bash  

# helm

setup_hosts() {
    echo "${public_ip} sonar.${prefix}.${domain}" | sudo tee -a /etc/hosts
}

setup_sonarqube() {
    # this will take about 5 minutes
    kubectl wait --for=condition=Ready pod/sonarqube-postgresql-0 -n sonarqube --timeout=900s
    kubectl wait --for=condition=Ready pod/sonarqube-sonarqube-0 -n sonarqube --timeout=900s

    echo "Waiting for sonar ready"
    until $(curl --output /dev/null --silent --head --insecure --fail http://sonar.${prefix}.${domain}); do
        sleep 2
    done

    # create project
    curl --location 'http://sonar.${prefix}.${domain}/api/projects/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=vote' \
    --data-urlencode 'project=vote' --insecure

    curl --location 'http://sonar.${prefix}.${domain}/api/projects/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=result' \
    --data-urlencode 'project=result' --insecure

    curl --location 'http://sonar.${prefix}.${domain}/api/projects/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=worker' \
    --data-urlencode 'project=worker' --insecure

    # revoke token first
    curl --location 'http://sonar.${prefix}.${domain}/api/user_tokens/revoke' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=jenkins' --insecure

    # generate token again
    sonar_token=$(curl --location 'http://sonar.${prefix}.${domain}/api/user_tokens/generate' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=jenkins' --insecure | yq .token -r)

    sonar_token=$(echo $sonar_token | tr -d '\n')

    # if sonar_token is empty, exit
    if [ -z "$sonar_token" ]; then
        echo "sonar_token craete fail, exit."
        exit 1
    fi

    # create secret for jenkins credential to get the sonar token
    cat > sonar-token.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: "sonarqube-token"
  namespace: jenkins
  labels:
    "jenkins.io/credentials-type": "secretText"
  annotations:
    "jenkins.io/credentials-description" : "credentials from Kubernetes of Sonarqube"
type: Opaque
stringData:
  text: $sonar_token
EOF
    # apply secret
    kubectl apply -f sonar-token.yaml -n jenkins

    # create sonar jenkins webhooks for enabled quality gate
    curl --location 'http://sonar.${prefix}.${domain}/api/webhooks/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=vote' \
    --data-urlencode 'url=http://jenkins.${prefix}.${domain}/sonarqube-webhook/' \
    --data-urlencode 'project=vote' --insecure

    curl --location 'http://sonar.${prefix}.${domain}/api/webhooks/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=result' \
    --data-urlencode 'url=http://jenkins.${prefix}.${domain}/sonarqube-webhook/' \
    --data-urlencode 'project=result' --insecure

    curl --location 'http://sonar.${prefix}.${domain}/api/webhooks/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=worker' \
    --data-urlencode 'url=http://jenkins.${prefix}.${domain}/sonarqube-webhook/' \
    --data-urlencode 'project=worker' --insecure
}

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# install ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait --version "4.7.2"

# install jenkins
helm repo add jenkins https://charts.jenkins.io
helm repo update

# create ns
kubectl create ns jenkins

# service account for kubernetes secret provider
kubectl apply -f /tmp/jenkins-service-account.yaml -n jenkins

# harbor image pull secret
kubectl create secret docker-registry regcred --docker-server=harbor.${prefix}.${domain} --docker-username=admin --docker-password=${harbor_password} -n jenkins

# harbor url secret
kubectl apply -f /tmp/harbor-url-secret.yaml -n jenkins

# jenkins github personal access token
kubectl apply -f /tmp/github-personal-token.yaml -n jenkins

# jenkins github server(system) pat secret
kubectl apply -f /tmp/github-pat-secret-text.yaml -n jenkins

# install jenkins helm
helm upgrade -i jenkins jenkins/jenkins -n jenkins --create-namespace -f /tmp/jenkins-values.yaml --version "4.6.1"

# install sonarqube
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm upgrade --install -n sonarqube sonarqube sonarqube/sonarqube --create-namespace --version 10.1.0+628 -f /tmp/sonar-values.yaml

# install argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f /tmp/argocd-values.yaml

# github PAT secret, for PR check
kubectl create secret generic github-token \
  --from-literal=token=${github_personal_token} -n argocd

# add argocd github repositry
kubectl apply -f /tmp/argocd-repository.yaml -n argocd

# add argocd notification secret(for create PR comment)
kubectl apply -f /tmp/argocd-notifications-secret.yaml -n argocd

# applicationset for PR preview environment, and notification configmap(for create PR preview URL comment)
kubectl apply -f /tmp/applicationset-pr.yaml -n argocd
kubectl apply -f /tmp/argocd-notifications-cm.yaml -n argocd
kubectl apply -f /tmp/applicationset-list.yaml -n argocd

setup_argo_image_updater() {
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
    kubectl create secret docker-registry harbor-pull-secret --docker-server=harbor.${prefix}.${domain} --docker-username=admin --docker-password=${harbor_password} -n argocd
    kubectl patch deployment/argocd-image-updater \
    -n argocd \
    --type=json \
    -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["/usr/local/bin/argocd-image-updater", "run", "--interval", "20s"]}]'
}

setup_sonarqube
setup_argo_image_updater