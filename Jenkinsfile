node {
  stage('Lint') {
      checkout scm
      withDockerContainer(image: 'chef/chefdk:1') {
          sh script: 'chef exec rubocop -D --out rubocop.log', returnStatus: true
          sh 'tail rubocop.log'
          warnings parserConfigurations: [[pattern: 'rubocop.log', parserName: 'Rubocop']]
      }
    def master = currentBuild.rawBuild.project.parent.getItem('jenkins').lastBuild
    def masterBuild = master.getAction(hudson.plugins.warnings.WarningsResultAction).result
    def currentRun = currentBuild.rawBuild.getAction(hudson.plugins.warnings.WarningsResultAction).result
    if(masterBuild.numberOfWarnings < currentRun.numberOfWarnings) {
        echo 'a lot of warnings than master'
        currentBuild.status = 'FAILURE'
    }
  }
}
