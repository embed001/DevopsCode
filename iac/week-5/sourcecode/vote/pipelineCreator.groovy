// get all DSL config http://jenkins.wangwei.devopscamp.us/plugin/job-dsl/api-viewer/index.html
multibranchPipelineJob("${Name}") {
    branchSources {
        branchSource {
            source {
                github {
                    id('github')
                    repoOwner("devops-advanced-camp")
                    configuredByUrl(false)
                    repository("vote")
                    repositoryUrl("https://github.com/devops-advanced-camp/vote.git")
                    credentialsId('github-pull-secret')

                    traits {
                        gitHubBranchDiscovery {
                            strategyId(1)
                        }
                        gitHubPullRequestDiscovery {
                            strategyId(2)
                        }
                    }
                }
            }
        }
        factory {
            workflowBranchProjectFactory {
                scriptPath("${jenkinsfile}")
            }
        }
    }
}