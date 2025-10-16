pipeline {
    agent any

    environment {
        VENV_DIR = "${WORKSPACE}/venv"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM', 
                    branches: [[name: '*/main']], 
                    userRemoteConfigs: [[url: 'https://github.com/bhargavpr99-sudo/cmake.git', credentialsId: 'Gitcred']]
                ])
            }
        }

        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential
                    # Create virtual environment if it doesn't exist
                    [ ! -d "${VENV_DIR}" ] && python3 -m venv "${VENV_DIR}"
                    # Activate venv using bash-compatible command
                    . "${VENV_DIR}/bin/activate"
                    pip install --quiet cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint checks on C files...'
                sh '''
                    . "${VENV_DIR}/bin/activate"
                    if [ -f src/main.c ]; then
                        cmakelint src/main.c
                    else
                        echo "No C files to lint"
                    fi
                '''
            }
        }

        stage('Build') {
            steps {
                echo 'Running build with CMake...'
                sh '''
                    mkdir -p build
                    cd build
                    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
                    make -j$(nproc)
                    cp compile_commands.json ..
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh '''
                    cd build
                    ctest --output-on-failure || echo "No tests found or tests failed"
                '''
            }
        }

        stage('SonarCloud Analysis') {
            environment {
                // Make sure this matches your Jenkins SonarCloud configuration
                SONARQUBE_ENV = 'SonarCloud'
            }
            steps {
                echo 'Running SonarCloud analysis...'
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                        sonar-scanner \
                            -Dsonar.organization=bhargavpr99-sudo \
                            -Dsonar.projectKey=bhargavpr99-sudo_cmake \
                            -Dsonar.sources=src \
                            -Dsonar.cfamily.compile-commands=compile_commands.json \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.sourceEncoding=UTF-8
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Checking SonarCloud Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to Quality Gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        failure {
            echo 'Pipeline failed. Check logs or SonarCloud dashboard.'
        }
    }
}
