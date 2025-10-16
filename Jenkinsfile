pipeline {
    agent any

    environment {
        PIPX_BIN_DIR = '/home/ubuntu/.local/bin'
        PATH = "${PIPX_BIN_DIR}:${env.PATH}"
    }

    stages {

        stage('Prepare Tools') {
            steps {
                sh '''
                    echo "[INFO] Installing tools..."
                    sudo apt update
                    sudo apt install -y pipx python3-venv cmake make g++

                    pipx ensurepath
                    pipx install cmakelint || true
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
                echo 'Building the project...'
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
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=cmake-sonar \
                          -Dsonar.sources=. \
                          -Dsonar.cfamily.build-wrapper-output=build \
                          -Dsonar.projectName="cmake-sonar"
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

        failure {
            echo 'Build failed. Check logs.'
        }
    }
}
