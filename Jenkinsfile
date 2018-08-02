def runBot(image, bot, buildNumber, mergeFrom, mergeTo) {
  def botName = "${bot.replaceAll('_','-').take(bot.lastIndexOf('.'))}-bot"
  def botCommand = "bundle exec bots/${bot}"
  def botEnvironmentName = "${botName}-environment"
  def botEnvironmentSelector = openshift.selector(["secret/${botEnvironmentName}"])

  def botEnvironment = []
  if ( botEnvironmentSelector.count() == 1 ) {
    botEnvironment[0] = [
      "secretRef": [
        "name": "${botEnvironmentName}"
      ]
    ]
  }

  def container = [
    "name": "${botName}-${buildNumber}",
    "image": image,
    "workingDir": "/opt/app-root/src",
    "command": [
        "bash",
        "-c",
        "${botCommand}"
    ],
    "envFrom": botEnvironment,
    "env": [
      [
        "name": "MERGE_FROM",
        "value": "${mergeFrom}"
      ],
      [
        "name": "MERGE_TO",
        "value": "${mergeTo}"
      ]
    ]
  ]

  def syncJob = [
    "apiVersion": "batch/v1",
    "kind": "Job",
    "metadata": [
      "name": "${botName}-${buildNumber}"
    ],
    "spec": [
      "backoffLimit": "1",
      "parallelism": "1",
      "completions": "1",
      "template": [
        "metadata": [
          "name": "${botName}-${buildNumber}"
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
    error "${botName}-${buildNumber} Job Failed! Leaving Openshift Job!"
  } else {
    job.delete()
  }
}//runBot

pipeline {
  parameters {
    string(defaultValue: '#empty#', description: 'branch to sync (create Pull Request) from. By default, only ua_test and production branches are synced to the sync_to branch', name: 'sync_from')
    string(defaultValue: 'develop', description: 'branch to sync (create Pull Request) to. Defaults to develop', name: 'sync_to')
  }
  agent any
  stages {
    stage('BranchSync') {
      when {
        anyOf {
          expression {
            if ( params.sync_from && env.BRANCH_NAME == params.sync_from ) {
              return params.sync_from
            }
            return null
          }
          branch 'ua_test'
          branch 'production'
        }
      }
      steps {
        script {
          openshift.withCluster() { // Use "default" cluster or fallback to OpenShift cluster detection
            def isSelector = openshift.selector([ "is/duke-data-service" ])
            if ( isSelector.count() != 1 ) {
              error("duke-data-service has not been initialized in the project!")
            }
            def imageStream = imageStreamS.narrow('is').object()

            def bot_manifest = readJSON file: 'bots/manifest.json'
            //this job responds to changes to a branch
            for (bot in bot_manifest['branch']) {
              runBot("${imageStream['metadata']['name']}:latest", bot, env.BUILD_NUMBER, env.BRANCH_NAME, params.sync_to)
            }
          } //openshift.withCluster
        }//BranchSync.steps.script
      }//BranchSync.steps
    } //BranchSync
  } //stages
} //pipeline
