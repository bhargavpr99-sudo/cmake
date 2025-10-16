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
                    # Install pipx and python3-venv if not installed
                    sudo apt update
                    sudo apt install -y pipx python3-venv

                    # Ensure pipx is initialized (required in some distros)
                    pipx ensurepath

                    # Install cmakelint with pipx
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
                echo 'Build step would go here.'
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
    }
}
