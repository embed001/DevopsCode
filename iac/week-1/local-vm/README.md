# 概述

## 准备工作

1. 准备两台ubuntu虚拟机，并进行初始化，我这里准备的机器系统为ubuntu22.04，一台16C32G 800G 用来跑K3S，一台2C2G 20G用来跑pg。
   - 部署节点不需要 SSH 密码即可登入。
     ssh-keygen -q -f ~/.ssh/id_rsa -N "" 
     ssh-copy-id 'You VM IP'
   - 所有节点都拥有 Sudoer 权限，并且不需要输入密码。
     sudo sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL) NOPASSWD:ALL/g'
  ps.这里有个注意事项，用普通用户sudo改一下root密码，否则root无法远程ssh。
     还有虚拟机要有魔法，要有魔法，要有魔法！否则很多步骤中会出现很多玄学问题。

2. 修改 variables.tf cloudflare.tf中的 变量,还有sonarqube目录中的变量，注意这里有老师的token和代码示例，小心不要泄露。sbom目录下的json。请认真检查每个目录下的代码，有非常多的地方需要修改。
   - domain,修改成你在cloudflare管理的域名地址，并修改cloudflare的api key。
   - 修改本地vm的ip地址和root密码。（这里我尝试使用variables.tf中的变量"private_ip"替换，报了奇怪的错误，写死ip后一切正常，并没有深挖原因，如有知道的同学，请联系我dailinaspire@gmail.com，不胜感谢。）
  我这里使用本地工作站，配置为内网ip。

3. 本地部署的知识点在于管控本地vm，网上所有教程均为云上教程，这里可以参考pg目录下的逻辑，以init.tf为例
  connection {
    host     = "192.168.31.177"
    type     = "ssh"
    user     = "root"
    password = var.password
  }
  以上代码配置了连接服务器的信息，还记得最初准备的两台虚拟机吗，这台为低配的2C2G的ubuntu，用来安装pg的这台。

  provisioner "file" {
    source      = "${path.module}/init.sh"
    destination = "/tmp/init.sh"
  }
  上面这段表示拷贝init.sh到虚拟机指定目录/tmp。

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
  这里就是远程执行脚本，怎么样，简单吧。

  这里分享一个terraform的文档，供学习使用https://lonegunmanb.github.io/introduction-terraform/


## 演示

- [ ] PR 触发流水线
- [ ] 多环境管理和环境晋升
  - [ ] Dev
  - [ ] Prod
- [ ] Grafana 面板
  - [ ] K8s Dashboard
  - [ ] Jenkins Dashboard
  - [ ] Argo CD Dashboard
  - [ ] Harbor Dashboard
  - [ ] SonarQube Dashboard
- [ ] 应用 CPU 指标伸缩
- [ ] Trigger on Image Update
- [ ] 开启签名校验，阻止未经签名的镜像部署
  - [ ] 本地构建未签名
- [ ] 开启漏洞校验，阻止包含漏洞的镜像部署
  - [ ] Golang 漏洞例子
- [ ] Sonarqube 代码质量门禁
  - [ ] 重复代码

## IaC

### 基础设施

部署并**自动配置**以下基础设施：

- [x] K3s
  - [x] 高可用部署
- [x] Prometheus
- [x] Grafana
- [x] Jenkins
- [x] Loki
- [x] Cloudflare
  - [x] 自动域名解析
- [x] Argo CD
- [x] Harbor
- [x] SonarQube
- [x] GitLab
  - [x] Cert-manager

### Grafana

- [x] Prometheus 数据源
- [x] Loki 数据源
- [x] K8s Dashboard
- [x] Jenkins Dashboard
- [x] Argo CD Dashboard
- [x] Harbor Dashboard
- [x] SonarQube Dashboard

### Jenkins

- [x] Metrics
- [x] JCasC 初始化流水线
- [x] 安装必要的插件
- [x] JCasC 凭据
- [x] 多分支流水线
- [x] 流水线 Git 凭据
- [x] Docker Image 凭据
- [x] 示例应用和 Jenkinsfile Pipeline
- [x] Kaniko 构建镜像，推送至私有镜像仓库
- [x] 使用自托管 GitLab 作为代码仓库
- [x] 推送至 Harbor 镜像仓库
- [x] 对不同的 Branch 用差异化的镜像 Tag
- [x] 单元测试
- [ ] E2E 测试
- [x] 代码质量检查(SonarQube)
- [x] 质量门禁
- [x] Cosign 签名
- [x] SBOM 镜像扫描
- [ ] SBOM 生成

### Harbor

- [x] Metrics
- [x] 镜像漏洞扫描
- [x] Cosign
  - [x] 阻止未签名的镜像部署
- [x] 漏洞扫描
  - [x] 阻止有漏洞的镜像部署

### Argo CD

- [x] Metrics
- [x] Git 凭据
- [x] GitOps
- [x] 多环境部署
- [x] Image Updater
  - [x] 监听 Harbor 镜像仓库变更自动更新

# 快速开始

## 安装 Terraform

查看官网安装步骤：https://developer.hashicorp.com/terraform/downloads?product_intent=terraform

## 初始化

```
// 在 local-vm 目录下执行
terraform init
terraform plan
terraform apply -auto-approve
```

## 输出
```
pg_public_ip = "192.168.31.177"
public_ip = "192.168.31.176"
ssh_password = "password123"
```
其中，pg_public_ip 是 Postgres 数据库的公网 IP，public_ip 是 K3s 集群的公网 IP，ssh_password 是 K3s 集群的 SSH 密码。
我这里是本地vm，做的内网穿透，所以显示均为内网IP。

# 访问应用

添加 Hosts：
```
${public_ip} dev.podinfo.local
${public_ip} main.podinfo.local
```
## 开发环境
URL: dev.podinfo.local

## 生产环境
URL: main.podinfo.local

# 访问基础设施

## Grafana

```
http://grafana.xxx.xxx
Username: admin
Password: password123
```

## Prometheus
```
http://prometheus.xxx.xxx
```

## Jenkins
```
http://jenkins.xxx.xxx
Username: admin
Password: password123
```

## GitLab
```
https://gitlab.xxx.xxx
Username: root
Password: kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' -n gitlab | base64 --decode ; echo
```

## Argo CD
```
http://argocd.xxx.xxx
Username: admin
Password: password123
```

## Harbor
```
https://harbor.xxx.xxx
Username: admin
Password: Harbor12345
```

## SonarQube
```
http://sonar.xxx.xxx
Username: admin
Password: password123
```

## 销毁
```
terraform destroy -auto-approve
```
