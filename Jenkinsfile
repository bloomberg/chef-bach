node {
    stage('Lint') {
        checkout scm
        withDockerContainer(image: 'chef/chefdk:1') {
            sh script: 'chef exec rubocop -D --out rubocop.log', returnStatus: true
            sh 'tail rubocop.log'
        }
        warnings parserConfigurations: [[pattern: 'rubocop.log', parserName: 'Rubocop']]
        if (currentBuild.rawBuild.project.name =~ /^PR-/) {
            echo 'BACH: Comparing PR with master'
            def masterBuild = currentBuild.rawBuild.project.parent.getItem('master').lastBuild.getAction(hudson.plugins.warnings.WarningsResultAction).result
            def prBuild =  currentBuild.rawBuild.getAction(hudson.plugins.warnings.WarningsResultAction).result
            echo "This PR has ${prBuild.numberOfWarnings}"
            echo "Master has ${masterBuild.numberOfWarnings}"
            if (masterBuild.numberOfWarnings <= prBuild.numberOfWarnings) {
                echo 'BACH: Master has less Lint Warnings'
                currentBuild.result = 'FAILURE'
            }
        }
  }
}
