pipeline {
    agent any

    tools {
        sonarQubeScanner 'SonarScanner'
    }

    environment {
        PIPX_BIN_DIR = '/home/ubuntu/.local/bin'
        PATH = "${PIPX_BIN_DIR}:${env.PATH}"
    }

    stages {
        stage('Prepare Tools') {
            steps {
                sh '''
                    sudo apt update
                    sudo apt install -y pipx python3-venv cmake make g++ sonar-scanner
                    pipx ensurepath
                    pipx install cmakelint || true
                '''
            }
        }

        stage('Lint') {
            steps {
                sh 'cmakelint CMakeLists.txt || true'
            }
        }

        stage('Build') {
            steps {
                sh '''
                    mkdir -p build
                    cd build
                    cmake ..
                    make
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=cmake-sonar \
                          -Dsonar.sources=.
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }

        success {
            archiveArtifacts artifacts: 'build/*.bin', fingerprint: true
        }
    }
}
