
pipeline {
    agent any

    environment {
        PIPX_BIN_DIR = '/home/ubuntu/.local/bin'
        PATH = "${PIPX_BIN_DIR}:${env.PATH}"
    }

    stages {
        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh '''
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
    }

    post {
        always {
            echo 'Pipeline finished.'
        }

        success {
            echo 'Archiving artifacts...'
            archiveArtifacts artifacts: 'build/**', fingerprint: true
        }

        failure {
            echo 'Build failed — no artifacts to archive.'
        }
    }
}
