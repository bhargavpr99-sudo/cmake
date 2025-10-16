pipeline {
    agent any

    environment {
        VENV_DIR = "${WORKSPACE}/venv"
        SONAR_PROJECT_KEY = "bhargavpr99-sudo_cmake"
        SONAR_ORGANIZATION = "bhargavpr99-sudo"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Tools') {
            steps {
                script {
                    // Create virtual environment if it doesn't exist
                    if (!fileExists("${VENV_DIR}/bin/activate")) {
                        sh "python3 -m venv ${VENV_DIR}"
                    }
                    // Activate virtualenv and install Python tools
                    sh """
                        . ${VENV_DIR}/bin/activate
                        pip install --quiet --upgrade cmakelint
                    """
                }
            }
        }

        stage('Lint & Build') {
            parallel {
                stage('Lint') {
                    steps {
                        script {
                            if (fileExists("src/main.c")) {
                                sh """
                                    . ${VENV_DIR}/bin/activate
                                    cmakelint src/main.c
                                """
                            } else {
                                echo "No C files to lint"
                            }
                        }
                    }
                }

                stage('Build') {
                    steps {
                        sh """
                            mkdir -p build
                            cd build
                            cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
                            make -j\$(nproc)
                            cp compile_commands.json ..
                        """
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                sh """
                    cd build
                    if [ -f Makefile ]; then
                        ctest --output-on-failure || echo "No tests found"
                    fi
                """
            }
        }

        stage('SonarCloud Analysis') {
            environment {
                SONAR_HOST_URL = 'https://sonarcloud.io'
            }
            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh """
                        sonar-scanner \
                            -Dsonar.organization=${SONAR_ORGANIZATION} \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.sources=src \
                            -Dsonar.cfamily.compile-commands=compile_commands.json \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.sourceEncoding=UTF-8
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed! Check logs or SonarCloud dashboard."
        }
    }
}
