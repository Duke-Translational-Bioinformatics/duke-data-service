def notifyBuildFixed(buildStatus, subject) {
  // only report if it the build failed before and is now fixed
  if (!buildStatus) {
    mail to: 'darin.london@duke.edu',
         subject: subject,
         body: "Good Job!"
  }
}

pipeline {
  parameters {
      string(defaultValue: 'jenkins-bot-head', description: 'Branch that needs to be synchronized', name: 'SYNC_BRANCH')
  }
  agent any
  stages {
    stage('BranchSync') {
      when {
        when { expression { return ( env.BRANCH_NAME == params.SYNC_BRANCH ) } }
      }
      steps {
        script {
          openshift.withCluster() { // Use "default" cluster or fallback to OpenShift cluster detection
            def isSelector = openshift.selector([ "is/duke-data-service" ])
            if ( isSelector.count() != 1 ) {
              error("duke-data-service has not been initialized in the project!")
            }
            def is = isSelector.narrow('is')
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
                  "name": "MERGE_FROM",
                  "value": "${env.BRANCH_NAME}"
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

            def job = openshift.create(syncJob)
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
