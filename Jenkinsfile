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
          echo "jenkins-bot-head ENVIRONMENT:"
          env.getEnvironment().each { name, value -> echo "Name: $name -> Value $value" }
        }//BranchSync.steps.script
      }//BranchSync.steps
    } //BranchSync
  } //stages
} //pipeline
