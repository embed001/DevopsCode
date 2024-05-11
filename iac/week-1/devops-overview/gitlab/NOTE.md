helm repo add gitlab https://charts.gitlab.io/
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
 --timeout 600s \
 --set global.hosts.domain=gkdevopscamp.com \
 --set global.hosts.externalIP=43.154.145.228 \
 --set certmanager-issuer.email=wangwei27494731@gmail.com \
--set postgresql.image.tag=13.6.0 \
 --set global.edition=ce \
 --version 7.0.4 \
 -n gitlab --create-namespace

username: root
password: kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' -n gitlab | base64 --decode ; echo

设置 token：toolbox 容器：

sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: ['read_user', 'read_repository','api','read_api','write_repository','read_registry','write_registry','sudo'], name: 'Automation token'); token.set_token('token-string-here123'); token.save!"

创建项目：

curl --request POST --header "PRIVATE-TOKEN: glpat-HAAWeTR5gy7m4FVtHKG\_" \
 --header "Content-Type: application/json" --data '{
"name": "camp-go-example", "description": "New Project", "path": "new_project", "initialize_with_readme": "true"}' \
 --url 'https://gitlab.devopscamp.com/api/v4/projects/' --insecure
