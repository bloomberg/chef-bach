node {
    stage('Lint') {
        checkout scm
        withDockerContainer(image: 'chef/chefdk:1') {
            sh script: 'chef exec rake style', returnStatus: true
            echo 'BACH: rubocop preview'
            sh 'tail rubocop.log'
            echo 'BACH: foodcritic preview'
            sh 'tail foodcritic.log'
        }
        warnings parserConfigurations: [
            [pattern: 'rubocop.log', parserName: 'Rubocop'],
            [pattern: 'foodcritic.log', parserName: 'Foodcritic']
            ]
        if (currentBuild.rawBuild.project.name =~ /^PR-/) {
            echo 'BACH: Comparing PR with master'
            def masterBuild = currentBuild.rawBuild.project.parent.getItem('master').lastBuild.getAction(hudson.plugins.warnings.AggregatedWarningsResultAction).result
            def prBuild =  currentBuild.rawBuild.getAction(hudson.plugins.warnings.AggregatedWarningsResultAction).result
            echo "This PR has ${prBuild.numberOfWarnings}"
            echo "Master has ${masterBuild.numberOfWarnings}"
            if (masterBuild.numberOfWarnings <= prBuild.numberOfWarnings) {
                echo 'BACH: Master has less Lint Warnings'
                currentBuild.result = 'FAILURE'
            }
        }
  }
}
