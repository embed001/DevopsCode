#!/bin/bash

setup_hosts() {
    echo "${public_ip} gitlab.${domain}" | sudo tee -a /etc/hosts
    echo "${public_ip} harbor.${domain}" | sudo tee -a /etc/hosts
    echo "${public_ip} jenkins.${domain}" | sudo tee -a /etc/hosts
    echo "${public_ip} sonar.${domain}" | sudo tee -a /etc/hosts
}

setup_cli() {
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    # pgsql
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get update -y
    sudo apt-get -y install -y postgresql-client
}

wait_pg() {
  until PGPASSWORD=${pg_password} psql -h ${pg_ip} -U k3s -d kubernetes -c '\q'; do
    echo "Waiting for PostgreSQL"
    sleep 1
  done
}

setup_k3s() {
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san ${public_ip}" sh -s - server --write-kubeconfig-mode 644 --disable=traefik --token=${pg_password} --datastore-endpoint="postgres://k3s:${pg_password}@${pg_ip}:5432/kubernetes"
    kubectl wait --for=condition=Ready pod --all -n kube-system --timeout=900s
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
}

setup_helm_repo() {
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add gitlab https://charts.gitlab.io/
    helm repo add harbor https://helm.goharbor.io
    helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
    helm repo add jenkins https://charts.jenkins.io
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update gitlab
}

setup_kube_prometheus_grafana_loki() {
    helm upgrade -i loki -n monitoring --create-namespace grafana/loki-stack --set loki.isDefault=false
    helm upgrade -i kube-prometheus-stack -n monitoring --create-namespace prometheus-community/kube-prometheus-stack -f /tmp/kube-prometheus-stack-values.yaml
}

setup_gitlab() {
    helm upgrade --install gitlab gitlab/gitlab \
    --timeout 600s \
    --set global.hosts.domain=${domain} \
    --set global.hosts.externalIP=${public_ip} \
    --set certmanager-issuer.email=wangwei@gmail.com \
    --set postgresql.image.tag="13.6.0" \
    --set global.edition=ce \
    --set global.shell.port=2222 \
    --set nginx-ingress.controller.scope.enabled=false \
    --version "7.0.4" \
    --set gitlab-runner.gitlabUrl=http://gitlab-webservice-default:8181 \
    -n gitlab --create-namespace

    # Apply cert-manager-secret and issuer
    kubectl apply -f /tmp/cert-manager-cloudflare-secret.yaml -n gitlab
    kubectl apply -f /tmp/issuer.yaml

    kubectl wait --for=condition=Available deployment/gitlab-webservice-default -n gitlab --timeout=900s
    echo "Waiting for gitlab ready"
    until $(curl --output /dev/null --silent --insecure --head --fail ${gitlab_host}); do
        sleep 2
    done

    gitlab_root_password=$(kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' -n gitlab | base64 --decode ; echo)
    echo "GitLab password: "$gitlab_root_password

    echo "Begin to create GitLab PAT and Project"
    # Create GitLab PAT
    gitlab_user="root"

    # 1. curl for the login page to get a session cookie and the sources with the auth tokens
    body_header=$(curl -c cookies.txt -i "${gitlab_host}/users/sign_in" -s --insecure)
    # grep the auth token for the user login for
    #   not sure whether another token on the page will work, too - there are 3 of them
    csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
    # 2. send login credentials with curl, using cookies and token from previous request
    curl -L -b cookies.txt -c cookies.txt -i "${gitlab_host}/users/sign_in" \
    --data-raw "user%5Blogin%5D=$gitlab_user&user%5Bpassword%5D=$gitlab_root_password" \
    --data-urlencode "authenticity_token=$csrf_token" \
    --compressed \
    --insecure 2>&1 > /dev/null

    # 3. send curl GET request to personal access token page to get auth token
    body_header=$(curl -H 'user-agent: curl' -b cookies.txt -i "${gitlab_host}/-/profile/personal_access_tokens" -s --insecure)

    csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /csrf-token"[[:blank:]]content="(.+?)"/' | sed -n 1p)
    # 4. curl POST request to send the "generate personal access token form"
    #      the response will be a redirect, so we have to follow using `-L`
    body_header=$(curl --insecure -L -b cookies.txt "${gitlab_host}/-/profile/personal_access_tokens" \
        --data-urlencode "authenticity_token=$csrf_token" \
        --data 'personal_access_token[name]=golab-generated&personal_access_token[expires_at]=&personal_access_token[scopes][]=api&personal_access_token[scopes][]=read_repository&personal_access_token[scopes][]=write_repository&personal_access_token[scopes][]=sudo' --insecure)
    # 5. Scrape the personal access token from the response json
    personal_access_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_token":"(.+?)"/' | sed -n 1p)
    echo "GitLab personal access token: "$personal_access_token

    if [ -z "$personal_access_token" ]; then
      echo "GitLab personal access token is empty, exit."
      exit 1
    fi
}

setup_gitlab_project() {
    ################################ create camp-go-exmaple project and push source code from github ############################
    project_response=$(curl -s -I --request GET --header "PRIVATE-TOKEN: $personal_access_token" "https://gitlab.${domain}/api/v4/projects/1" --insecure)
    echo "Project response: "$project_response

    if echo "$project_response" | grep -q "HTTP/2 404"; then
        echo "Project not found, create."
        # Create GitLab Project
        curl --request POST --header "PRIVATE-TOKEN: $personal_access_token" \
        --header "Content-Type: application/json" --data '{
        "name": "${example_project_name}", "description": "GeekTime Cloud Native DevOps Camp", "path": "${example_project_name}", "initialize_with_readme": "false", "only_allow_merge_if_pipeline_succeeds": "true"}' \
        --url "https://gitlab.${domain}/api/v4/projects/" --insecure
        
        git clone https://github.com/lyzhang1999/${example_project_name}.git
        cd ${example_project_name}
        git remote set-url origin https://root:$personal_access_token@gitlab.${domain}/root/${example_project_name}.git
        git add .
        git commit -a -m 'Initial'
        # push main and dev branch
        GIT_SSL_NO_VERIFY=true git push -uf origin main && GIT_SSL_NO_VERIFY=true git push -uf origin main:dev
        # Delete branch protection
        curl --insecure --request DELETE --header "PRIVATE-TOKEN: $personal_access_token" "https://gitlab.${domain}/api/v4/projects/1/protected_branches/main"
    fi

    ############################ create camp-go-exmaple-helm project and push source code from github ################################
    project_response=$(curl -s -I --request GET --header "PRIVATE-TOKEN: $personal_access_token" "https://gitlab.${domain}/api/v4/projects/2" --insecure)
    echo "Project response: "$project_response

    if echo "$project_response" | grep -q "HTTP/2 404"; then
        echo "Project not found, create."
        # Create GitLab Project
        curl --request POST --header "PRIVATE-TOKEN: $personal_access_token" \
        --header "Content-Type: application/json" --data '{
        "name": "${example_project_name}-helm", "description": "GeekTime Cloud Native DevOps Camp", "path": "${example_project_name}-helm", "initialize_with_readme": "false"}' \
        --url "https://gitlab.${domain}/api/v4/projects/" --insecure
        
        git clone https://github.com/lyzhang1999/${example_project_name}-helm.git
        cd ${example_project_name}-helm

        yq -i '.image.repository = "harbor.${domain}/${harbor_registry}/${example_project_name}"' charts/env/dev/values.yaml
        yq -i '.image.repository = "harbor.${domain}/${harbor_registry}/${example_project_name}"' charts/env/main/values.yaml

        # generate regcred.yaml in charts/templates/image-pull-secret.yaml for pull image from harbor
        kubectl create secret docker-registry regcred --docker-server=harbor.${domain} --docker-username=admin --docker-password=${harbor_password} -o yaml --dry-run=client > charts/templates/image-pull-secret.yaml

        git remote set-url origin https://root:$personal_access_token@gitlab.${domain}/root/${example_project_name}-helm.git
        git add .
        git commit -a -m 'Initial'
        GIT_SSL_NO_VERIFY=true git push -uf origin main
        # Delete branch protection
        curl --insecure --request DELETE --header "PRIVATE-TOKEN: $personal_access_token" "https://gitlab.${domain}/api/v4/projects/2/protected_branches/main"
    fi
}

setup_harbor() {
    kubectl create ns harbor
    kubectl apply -f /tmp/harbor-issuer.yaml -n harbor
    
    # create cloudflare secret
    kubectl apply -f /tmp/cert-manager-cloudflare-secret.yaml -n harbor
    # deploy harbor
    helm upgrade --install harbor harbor/harbor -f /tmp/harbor-values.yaml --namespace harbor --create-namespace

    # deploy harbor dashboard
    kubectl apply -f /tmp/harbor-dashboard.yaml -n harbor

    # wait until harbor pod ready
    kubectl wait deployment -n harbor --for condition=Available=True --all --timeout=900s

    # wait harbor server ready
    echo "Waiting for harbor ready"
    until $(curl --output /dev/null --silent --insecure --head --fail https://harbor.${domain}); do
        sleep 1
    done

    # wait until default project ready
    echo "Waiting for harbor default project ready"
    until $(curl -u admin:${harbor_password} --output /dev/null --silent --insecure --fail https://harbor.${domain}/api/v2.0/projects/1); do
        sleep 1
    done

    # Add new project
    # Got 503 Service Temporarily Unavailable after "waiting for harbor ready" success, why?
    curl 'https://harbor.${domain}/api/v2.0/projects' \
    -H 'content-type: application/json' \
    -u admin:${harbor_password} \
    --data-raw '{"project_name":"${harbor_registry}","metadata":{"public":"false"},"storage_limit":-1,"registry_id":null}' \
    --compressed --insecure

    # Setting libary project auto_scan and cosign: enable_content_trust_cosign need to set true
    curl 'https://harbor.${domain}/api/v2.0/projects/2' \
    -X 'PUT' \
    -H 'content-type: application/json' \
    -u admin:${harbor_password} \
    --data-raw '{"metadata":{"public":"false","enable_content_trust":"false","enable_content_trust_cosign":"true","prevent_vul":"true","severity":"critical","auto_scan":"true","reuse_sys_cve_allowlist":"true"},"cve_allowlist":{"creation_time":"0001-01-01T00:00:00.000Z","id":2,"items":[],"project_id":2,"update_time":"0001-01-01T00:00:00.000Z","expires_at":null}}' \
    --compressed --insecure --fail
}

setup_sonarqube() {
    helm upgrade --install -n sonarqube sonarqube sonarqube/sonarqube --create-namespace --version 10.1.0+628 -f /tmp/sonarqube-values.yaml

    # this will take about 5 minutes
    kubectl wait --for=condition=Ready pod/sonarqube-postgresql-0 -n sonarqube --timeout=900s
    kubectl wait --for=condition=Ready pod/sonarqube-sonarqube-0 -n sonarqube --timeout=900s

    echo "Waiting for sonar ready"
    until $(curl --output /dev/null --silent --head --insecure --fail http://sonar.${domain}); do
        sleep 2
    done

    # create project
    curl --location 'http://sonar.${domain}/api/projects/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=${example_project_name}' \
    --data-urlencode 'project=${example_project_name}' --insecure

    # revoke token first
    curl --location 'http://sonar.${domain}/api/user_tokens/revoke' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=${example_project_name}' --insecure

    # generate token again
    sonar_token=$(curl --location 'http://sonar.${domain}/api/user_tokens/generate' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=${example_project_name}' --insecure | yq .token -r)

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
    # apply jenkins ns
    kubectl create ns jenkins
    # apply secret
    kubectl apply -f sonar-token.yaml -n jenkins

    # create sonar dashboard
    kubectl apply -f /tmp/sonar-dashboard.yaml

    # create sonar jenkins webhooks for enabled quality gate
    curl --location 'http://sonar.${domain}/api/webhooks/create' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -u admin:${sonar_password} \
    --data-urlencode 'name=${example_project_name}' \
    --data-urlencode 'url=http://jenkins.${domain}/sonarqube-webhook/' \
    --data-urlencode 'project=${example_project_name}' --insecure
}

setup_jenkins() {
    kubectl create ns jenkins
    # as gitlab api secret
    cat > gitlab-token.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: "gitlab-token"
  labels:
    "jenkins.io/credentials-type": "gitlabToken"
  annotations:
    "jenkins.io/credentials-description" : "credentials from Kubernetes of GitLab"
type: Opaque
stringData:
  text: $personal_access_token
EOF

    cat > jenkins-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-workspace-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

    # as gitlab pull secret
    cat > gitlab-username-password-secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: "gitlab-pull-secret"
  labels:
    "jenkins.io/credentials-type": "usernamePassword"
  annotations:
    "jenkins.io/credentials-description" : "credentials from Kubernetes"
type: Opaque
stringData:
  username: root
  password: $personal_access_token
EOF

    setup_cosign

    kubectl apply -f gitlab-token.yaml -n jenkins
    kubectl apply -f gitlab-username-password-secret.yaml -n jenkins

    # apply jenkins pvc for workspace
    kubectl apply -f jenkins-pvc.yaml -n jenkins

    # set harbor url and repository secret, so Jenkinsfile can get it by env
    kubectl apply -f /tmp/jenkins-harbor-url-secret.yaml -n jenkins
    kubectl apply -f /tmp/harbor-repository-secret.yaml -n jenkins

    # plugin need id(url of plugin)
    helm upgrade -i jenkins jenkins/jenkins -n jenkins --create-namespace -f /tmp/jenkins-values.yaml --version 4.6.1
    kubectl apply -f /tmp/jenkins-service-account.yaml -n jenkins

    # apply jenkins dashboard
    kubectl apply -f /tmp/jenkins-dashboard.yaml -n jenkins
    # apply jenkins github pull secret
    kubectl apply -f /tmp/github-pull-secret.yaml -n jenkins
    # apply harbor image pull secret
    kubectl create secret docker-registry regcred --docker-server=harbor.${domain} --docker-username=admin --docker-password=${harbor_password} -n jenkins
}

# TODO change file
setup_cosign() {
    kubectl apply -f /tmp/cosign-key-password.yaml -n jenkins
    kubectl apply -f /tmp/cosign-key-file-secret.yaml -n jenkins
}

setup_argocd() {
    helm upgrade --install -n argocd argocd argo/argo-cd --version 5.36.6 -f /tmp/argocd-vaules.yaml --create-namespace

    # Create repository pull secret
    GITLAB_PERSONAL_TOKEN="$personal_access_token" yq -i '.stringData.url = "https://gitlab.${domain}/root/${example_project_name}-helm.git" | .stringData.password = strenv(GITLAB_PERSONAL_TOKEN)' /tmp/repo-secret.yaml
    kubectl apply -f /tmp/repo-secret.yaml

    # Create Argo CD ApplicationSet
    yq -i '.spec.generators[0].git.repoURL = "https://gitlab.${domain}/root/${example_project_name}-helm.git" | .spec.template.spec.source.repoURL = "https://gitlab.${domain}/root/${example_project_name}-helm.git" | .spec.template.metadata.annotations."argocd-image-updater.argoproj.io/image-list"="${example_project_name}=harbor.${domain}/${harbor_registry}/${example_project_name}"' /tmp/applicationset.yaml
    kubectl apply -f /tmp/applicationset.yaml

    # setup dashboard
    kubectl apply -f /tmp/argocd-servicemonitor.yaml -n argocd
    kubectl apply -f /tmp/argocd-dashboard.yaml -n argocd
}

setup_argo_image_updater() {
    # install image updater
    kubectl apply -n argocd -f https://ghproxy.com/https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
    # harbor image pull secret, if you modify the harbor password, you need to update this secret
    kubectl create secret docker-registry regcred --docker-server=harbor.${domain} --docker-username=admin --docker-password=${harbor_password} -n argocd
    # harbor does not need custom registry
    # kubectl apply -f /tmp/argocd-image-updater-config.yaml -n argocd

    # patch argocd image updater command, set interval to 20s instead of 2min
    kubectl patch deployment/argocd-image-updater \
    -n argocd \
    --type=json \
    -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["/usr/local/bin/argocd-image-updater", "run", "--interval", "20s"]}]'
}

output() {
    echo "##################################### Access Infrastruct ########################################\n"
    echo "Access Grafana: http://grafana.${domain}, admin, ${grafana_password}\n"
    echo "Access Prometheus: http://prometheus.${domain}\n"
    echo "Access GitLab: https://gitlab.${domain}, root, "$gitlab_root_password", Access Token: $personal_access_token\n"
    echo "Access Jenkins: http://jenkins.${domain}, admin, ${jenkins_password}\n"
    echo "Access Argo CD: http://argocd.${domain}, admin, ${argocd_password}\n"
    echo "Access Harbor: https://harbor.${domain}, admin, ${harbor_password}\n"
    echo "Access SonarQube: http://sonar.${domain}, admin, ${sonar_password}\n"
    echo "Example Application Dev Environment: dev.podinfo.local, Add hosts: ${public_ip} dev.podinfo.local\n"
    echo "Example Application Prod Environment: prod.podinfo.local, Add hosts: ${public_ip} main.podinfo.local\n"
}

main() {
    setup_hosts
    setup_cli
    wait_pg
    setup_k3s
    setup_helm_repo
    setup_kube_prometheus_grafana_loki
    setup_gitlab
    setup_gitlab_project
    setup_harbor
    setup_sonarqube
    setup_jenkins
    setup_argocd
    setup_argo_image_updater
    output
}

main