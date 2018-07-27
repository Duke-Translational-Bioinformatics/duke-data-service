def notifyBuildFixed(buildStatus, subject) {
  // only report if it the build failed before and is now fixed
  if (!buildStatus) {
    mail to: 'darin.london@duke.edu',
         subject: subject,
         body: "Good Job!"
  }
}

pipeline {
  agent any
  stages {
    stage('Base') {
      when {
        branch 'jenkins-bot-base'
      }
      steps {
        script {
          echo "jenkins-bot-base ENVIRONMENT:"
          env.getEnvironment().each { name, value -> echo "Name: $name -> Value $value" }
        }//Base.steps.script
      }//Base.steps
    } //Base
    stage('BranchSync') {
      when {
        branch 'jenkins-bot-head'
      }
      steps {
        script {
          openshift.withCluster() { // Use "default" cluster or fallback to OpenShift cluster detection
            def allSelector = openshift.selector([ "is/duke-data-service" ])
            if ( allSelector.count() != 1 ) {
              error("duke-data-service has not been initialized in the project!")
            }
            def is = allSelector.narrow('is')
            def iso = is.object()

            def container = [
              "name": "branch-sync-${env.BUILD_NUMBER}",
              "image": "${iso['metadata']['name']}:latest",
              "workingDir": "/opt/app-root/src",
              "command": [
                  "bash",
                  "-c",
                  "bundle exec bots/merge_commit_pr.rb"
              ],
              "envFrom": [
                [
                  "secretRef": [
                    "name": "sync-bot-environment"
                  ]
                ]
              ],
              "env": [
                [
                  "name": "HEAD",
                  "value": "${env.GIT_BRANCH}"
                ]
              ]
            ]

            def syncJob = [
              "apiVersion": "batch/v1",
              "kind": "Job",
              "metadata": [
                "name": "branch-sync-${env.BUILD_NUMBER}-job"
              ],
              "spec": [
                "backoffLimit": "1",
                "parallelism": "1",
                "completions": "1",
                "template": [
                  "metadata": [
                    "name": "test-${params.APPLICATION}-${env.BUILD_NUMBER}-job"
                  ],
                  "spec": [
                    "containers": [
                      container
                    ],
                    "restartPolicy": "Never"
                  ]
                ]
              ]
            ]

            def job = openshift.create(testJob)
            def hasError = false
            timeout(20) { // die after 20 minutes
              job.related("pods").watch {
                if ( it.count() == 0 ) return false
                def allDone = true

                it.withEach {
                  def podModel = it.object()
                  def phase = podModel.status.phase
                  switch(phase) {
                    case "New":
                      allDone = false
                      break
                    case "Pending":
                      allDone = false
                      break
                    case "Running":
                      allDone = false
                      break
                    case "Failed":
                      echo "status Failed"
                      hasError = true
                      break
                    case "Error":
                      echo "status Error"
                      hasError = true
                      break
                    case "Cancelled":
                      hasError = true
                      echo "The job was cancelled! Check the logs."
                      break
                    case "Complete":
                      echo "Job Complete:"
                      break
                  }
                }
                return allDone;
              }
            }
            job.logs()
            if (hasError) {
              error "Job Failed! Rolling back to previous build and leaving Openshift Job"
            } else {
              echo "Cleaning Up Job"
              job.delete()
            }
          } //openshift.withCluster
        }//BranchSync.steps.script
      }//BranchSync.steps
    } //BranchSync
  } //stages
} //pipeline
