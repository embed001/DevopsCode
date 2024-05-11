agent:
  resources:
    requests:
      cpu: "512m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "2048Mi"
controller:
  containerEnv:
    - name: HARBOR_URL
      value: "harbor.${domain}"
  ingress:
    enabled: true
    hostName: jenkins.${domain}
    ingressClassName: gitlab-nginx
  adminPassword: "${jenkins_password}"
  prometheus:
    enabled: true
    serviceMonitorNamespace: "monitoring"
  installPlugins:
    - kubernetes:4029.v5712230ccb_f8
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.1.0
    - configuration-as-code:1670.v564dc8b_982d0
  additionalPlugins:
    - prometheus:2.2.3
    - kubernetes-credentials-provider:1.211.vc236a_f5a_2f3c
    - job-dsl:1.84
    - github:1.37.1
    - github-branch-source:1725.vd391eef681a_e
    - gitlab-branch-source:660.vd45c0f4c0042
    - gitlab-kubernetes-credentials:132.v23fd732822dc
    - pipeline-stage-view:2.33
    - sonar:2.15
#    - gitlab-plugin:1.7.14
#    - gitlab-api:5.2.0-86.v1ed41a_9cf486
  JCasC:
    defaultConfig: true
    configScripts:
      welcome-message: |
       jenkins:
         systemMessage: Welcome to GeekBang Cloud Native Camp!
      jenkins-casc-configs: |
        unclassified:
          sonarglobalconfiguration:
            buildWrapperEnabled: true
            installations:
              - name: "camp-go-example"
                credentialsId: "sonarqube-token"
                serverUrl: "http://sonar.${domain}"
          gitLabServers:
            servers:
              - credentialsId: "gitlab-token"
                manageWebHooks: true
                manageSystemHooks: true
                name: "gitlab-server"
                serverUrl: "https://gitlab.${domain}"
                hooksRootUrl: ""
      example-job: |
        jobs:
          - script: >
              multibranchPipelineJob('build-go-example') {
                branchSources {
                  branchSource {
                    source {
                      gitlab {
                        serverName('gitlab-server')
                        projectOwner('root')
                        projectPath('root/camp-go-example')
                        credentialsId('gitlab-pull-secret')
                        id('build-go-example')
                        //projectId(long value)
                        traits {
                          gitLabBranchDiscovery {
                            strategyId(3)  // discover all branches
                          }
                          originMergeRequestDiscoveryTrait {
                            strategyId(1)  // discover MRs and merge them with target branch
                          }
                          gitLabTagDiscovery() // discover tags
                        }
                      }
                    }
                  }
                }
                triggers {
                  periodicFolderTrigger {
                    interval("1")
                  }
                }
                orphanedItemStrategy {
                  discardOldItems()
                }
              }