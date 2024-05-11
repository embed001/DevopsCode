1. 先转发 vault 服务到本地，以便 vault cli 访问：kubectl port-forward svc/vault -n vault 8200:8200
1. export VAULT_ADDR='http://127.0.0.1:8200'
1. 初始化：vault operator init
1. vault operator unseal <1,2,3> 用 3 个 token 解锁
1. 登录 vault UI：127.0.0.1:8200，使用输出的 token 登录
1. 创建 Policies，名称为 example，内容为
```
path "*" {
  capabilities = ["read", "list"]
}
```
1. 进入 Access 模块，点击”Enable new method“，选择 username/password 类型，点击”enable Method“
1. 进入新创建的 method，点击 create user 创建用户，用户名 example，密码 example，在 Generated Token's Policies 一栏，输入 example（刚才创建的 policy）
1. 选择右侧的 Secrets engines，在界面里创建新的 Secrets Engines，选择 KV，path 命名为: k8s
1. 在刚才创建的 secret engine 里创建新的 Secret，Path：example, key: PASSWORD, value: password123
1. 然后切换刚才创建的用户登录 vault ui，example: exmaple, 点击头像，复制 token
1. 创建 secret：kubectl create secret -n external-secrets  generic vault-token \ 
    --from-literal=token='<token>'
1. kubectl apply -f secretstore.yaml 配置集群级级 secret store
1. 创建 external secret：kubectl apply -f externalsecrets.yaml
1. 查看创建的 secret 对象：kubectl get secret -n external-secrets，可见 external secret 创建了对应的 Secret 对象


策略：https://developer.hashicorp.com/vault/tutorials/getting-started-ui/getting-started-policies-ui
创建用户和授权策略：https://developer.hashicorp.com/vault/tutorials/getting-started-ui/getting-started-auth-ui