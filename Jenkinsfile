pipeline {
    agent any

    stages {
        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh '''
                    command -v python3 || sudo apt update && sudo apt install -y python3
                    command -v pip3 || sudo apt install -y python3-pip
                    pip3 install --quiet cmakelint || true
                '''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running cmakelint...'
                sh 'cmakelint CMakeLists.txt || true'
            }
        }

        stage('Build') {
            steps {
                echo 'Build step would go here.'
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        failure {
            echo 'Pipeline failed. Check logs.'
        }
    }
}
