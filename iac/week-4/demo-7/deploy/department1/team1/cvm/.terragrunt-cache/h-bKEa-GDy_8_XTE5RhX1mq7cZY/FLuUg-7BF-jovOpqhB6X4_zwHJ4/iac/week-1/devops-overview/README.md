# 概述

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

自动创建以下云资源：

- VPC
- CVM
- Security Group
- Cloudflare DNS

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
// 在 devops-overview 目录下执行
terraform init
```

## 准备工作

1. 申请一个腾讯云账号，并获取账号的 SecretId 和 SecretKey
2. 修改 variables.tf 中的 prefix 的值

prefix 是环境域名的唯一标识，注意避免和他人冲突。

由于每一个 domain 签发的免费证书数量有限，如果在拉起环境的过程中，发现 GitLab 和 Harbor 的 SSL 证书一直无法申请成功，可以让老师发一个新的域名。

## 创建云资源
```
export TF_VAR_secret_id=
export TF_VAR_secret_key=
terraform apply -auto-approve
```

## 输出
```
pg_public_ip = "43.129.16.99"
public_ip = "43.128.55.159"
ssh_password = "password123"
```

其中，pg_public_ip 是 Postgres 数据库的公网 IP，public_ip 是 K3s 集群的公网 IP，ssh_password 是 K3s 集群的 SSH 密码。

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
http://grafana.${prefix}.gkdevopscamp.com
Username: admin
Password: password123
```

## Prometheus
```
http://prometheus.${prefix}.gkdevopscamp.com
```

## Jenkins
```
http://jenkins.${prefix}.gkdevopscamp.com
Username: admin
Password: password123
```

## GitLab
```
https://gitlab.${prefix}.gkdevopscamp.com
Username: root
Password: kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' -n gitlab | base64 --decode ; echo
```

## Argo CD
```
http://argocd.${prefix}.gkdevopscamp.com
Username: admin
Password: password123
```

## Harbor
```
https://harbor.${prefix}.gkdevopscamp.com
Username: admin
Password: Harbor12345
```

## SonarQube
```
http://sonarqube.${prefix}.gkdevopscamp.com
Username: admin
Password: password123
```

## 销毁
```
terraform destroy -auto-approve
```