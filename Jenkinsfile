pipeline {
    agent any

    environment {
        PIPX_BIN_DIR = '/home/ubuntu/.local/bin'
        PATH = "${PIPX_BIN_DIR}:${env.PATH}:/usr/local/bin"
    }

    stages {
        stage('Prepare Tools') {
            steps {
                echo '[INFO] Installing tools...'
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

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=cmake-sonar \
                          -Dsonar.projectName=cmake-sonar \
                          -Dsonar.sources=. \
                          -Dsonar.cfamily.compile-commands=build/compile_commands.json || true
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
            echo 'Archiving artifacts...'
            archiveArtifacts artifacts: 'build/*.bin, build/*.elf', fingerprint: true
        }
    }
}
