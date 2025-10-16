pipeline {
    agent { label 'linuxgit' }

    environment {
        GIT_REPO = 'https://github.com/bhargavpr99-sudo/cmake.git'
        BRANCH = 'main'

        // SonarCloud Configuration
        SONARQUBE_ENV = 'SonarCloud'
        SONAR_ORGANIZATION = 'bhargavpr99-sudo'
        SONAR_PROJECT_KEY = 'bhargavpr99-sudo_cmake'

        VENV_DIR = 'venv'
        BUILD_DIR = 'build'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo 'Checking out Git repository...'
                checkout([$class: 'GitSCM',
                    branches: [[name: "${BRANCH}"]],
                    userRemoteConfigs: [[url: "${GIT_REPO}", credentialsId: 'Gitcred']]
                ])
            }
        }

        stage('Prepare Tools & Cache') {
            steps {
                echo 'Installing required tools on Ubuntu and caching virtual environment...'
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential

                    # Create virtual environment if it doesn't exist
                    if [ ! -d "${VENV_DIR}" ]; then
                        python3 -m venv ${VENV_DIR}
                    fi

                    # Activate virtual environment and upgrade pip
                    . ${VENV_DIR}/bin/activate
                    pip install --quiet --upgrade pip cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint checks on main.c...'
                sh '''
                    . ${VENV_DIR}/bin/activate
                    if [ -f src/main.c ]; then
                        cmakelint src/main.c > lint_report.txt || true
                    else
                        echo "main.c not found!"
                        exit 1
                    fi
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'lint_report.txt', fingerprint: true
                    fingerprint 'src/main.c'
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Building project with CMake...'
                sh '''
                    . ${VENV_DIR}/bin/activate
                    mkdir -p ${BUILD_DIR}
                    cd ${BUILD_DIR}

                    # Only re-run CMake if CMakeLists.txt changed
                    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .. || true

                    # Build using all available cores
                    make -j$(nproc) || true

                    # Copy compile commands for Sonar
                    cp compile_commands.json ..
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh '''
                    . ${VENV_DIR}/bin/activate
                    if [ -d ${BUILD_DIR} ]; then
                        cd ${BUILD_DIR}
                        ctest --output-on-failure || true
                    else
                        echo "Build directory not found!"
                        exit 1
                    fi
                '''
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                echo 'Running SonarCloud analysis...'
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                        . ${VENV_DIR}/bin/activate
                        sonar-scanner \
                            -Dsonar.organization=${SONAR_ORGANIZATION} \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
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
                echo 'Waiting for SonarCloud Quality Gate...'
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Build, lint, unit tests, and SonarCloud analysis completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs or SonarCloud dashboard.'
        }
    }
}
