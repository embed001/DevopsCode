## 初始化配置

1. 创建 example 项目
2. 右上角设置，进入“应用程序”
3. 进入左侧“Dvcs account”
4. 点击“链接账户”，选择 github
5. 在 github 上创建 oauth 应用，点击头像“Setting”，“Developer settings”，选择“OAuth APP”，创建应用，注意 URL（影响到跳转），获取 client id 和 client secret
6. 输入 client id 和 client secret，账户输入 devops-advanced-camp，点击“链接账户”，注意在弹出的授权页要选择给 devops-advanced-camp 授权
7. JIRA 将自动给仓库创建 webhook
8. 提交 commit：git commit -a -m 'EX-2 #in-progress #comment in progress now'

## 创建 release
1. 创建发布版本，并将 issue 移动到 release 中

## 演示
1. 提交 commit 时，自动更新 jira issue 状态和评论
1. 将 jira issues 添加到 jira release 中
1. jenkins 发布时，自动更新 jira release 状态