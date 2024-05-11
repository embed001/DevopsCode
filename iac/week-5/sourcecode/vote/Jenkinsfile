pipeline {
    agent none
    stages {
        stage('Build result') {
            when {
                changeset "**/result/*.*"
            }
            agent {
                kubernetes {
                    defaultContainer 'kaniko'
                    //workspaceVolume persistentVolumeClaimWorkspaceVolume(claimName: "jenkins-workspace-pvc", readOnly: false)
                    yaml """
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.11.0-debug
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
      - name: jenkins-docker-cfg
        mountPath: /kaniko/.docker
  volumes:
  - name: jenkins-docker-cfg
    projected:
      sources:
      - secret:
          name: regcred
          items:
            - key: .dockerconfigjson
              path: config.json
"""
                }
            }

            environment {
                HARBOR_URL     = credentials('harbor-url')
                IMAGE_PUSH_DESTINATION="${HARBOR_URL}/vote/result"
                GIT_COMMIT="${checkout (scm).GIT_COMMIT}"
                IMAGE_TAG = "${BRANCH_NAME}-${GIT_COMMIT}"
                BUILD_IMAGE="${IMAGE_PUSH_DESTINATION}:${IMAGE_TAG}"
                BUILD_IMAGE_LATEST="${IMAGE_PUSH_DESTINATION}:latest"
            }

            steps {
                container(name: 'kaniko', shell: '/busybox/sh') {
                    withEnv(['PATH+EXTRA=/busybox']) {
                        sh '''#!/busybox/sh
                            cd result
                            /kaniko/executor --context `pwd` --destination $IMAGE_PUSH_DESTINATION --insecure
                        '''
                    }
                }
            }
        }

        stage('Build vote') {
            when {
                changeset "**/vote/*.*"
            }
            agent {
                kubernetes {
                    defaultContainer 'kaniko'
                    //workspaceVolume persistentVolumeClaimWorkspaceVolume(claimName: "jenkins-workspace-pvc", readOnly: false)
                    yaml """
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.11.0-debug
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
      - name: jenkins-docker-cfg
        mountPath: /kaniko/.docker
  volumes:
  - name: jenkins-docker-cfg
    projected:
      sources:
      - secret:
          name: regcred
          items:
            - key: .dockerconfigjson
              path: config.json
"""
                }
            }

            environment {
                HARBOR_URL     = credentials('harbor-url')
                IMAGE_PUSH_DESTINATION="${HARBOR_URL}/vote/vote"
                GIT_COMMIT="${checkout (scm).GIT_COMMIT}"
                IMAGE_TAG = "${BRANCH_NAME}-${GIT_COMMIT}"
                BUILD_IMAGE="${IMAGE_PUSH_DESTINATION}:${IMAGE_TAG}"
                BUILD_IMAGE_LATEST="${IMAGE_PUSH_DESTINATION}:latest"
            }

            steps {
                container(name: 'kaniko', shell: '/busybox/sh') {
                    withEnv(['PATH+EXTRA=/busybox']) {
                        sh '''#!/busybox/sh
                            cd vote
                            /kaniko/executor --context `pwd` --destination $IMAGE_PUSH_DESTINATION --insecure
                        '''
                    }
                }
            }
        }

        stage('Build worker') {
            when {
                changeset "**/worker/*.*"
            }
            agent {
                kubernetes {
                    defaultContainer 'kaniko'
                    //workspaceVolume persistentVolumeClaimWorkspaceVolume(claimName: "jenkins-workspace-pvc", readOnly: false)
                    yaml """
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.11.0-debug
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
      - name: jenkins-docker-cfg
        mountPath: /kaniko/.docker
  volumes:
  - name: jenkins-docker-cfg
    projected:
      sources:
      - secret:
          name: regcred
          items:
            - key: .dockerconfigjson
              path: config.json
"""
                }
            }

            environment {
                HARBOR_URL     = credentials('harbor-url')
                IMAGE_PUSH_DESTINATION="${HARBOR_URL}/vote/worker"
                GIT_COMMIT="${checkout (scm).GIT_COMMIT}"
                IMAGE_TAG = "${BRANCH_NAME}-${GIT_COMMIT}"
                BUILD_IMAGE="${IMAGE_PUSH_DESTINATION}:${IMAGE_TAG}"
                BUILD_IMAGE_LATEST="${IMAGE_PUSH_DESTINATION}:latest"
            }

            steps {
                container(name: 'kaniko', shell: '/busybox/sh') {
                    withEnv(['PATH+EXTRA=/busybox']) {
                        sh '''#!/busybox/sh
                            cd worker
                            /kaniko/executor --context `pwd` --destination $IMAGE_PUSH_DESTINATION --insecure --build-arg "TARGETPLATFORM='linux/amd64'" --build-arg "BUILDPLATFORM='linux/amd64'"
                        '''
                    }
                }
            }
        }
    }
}
