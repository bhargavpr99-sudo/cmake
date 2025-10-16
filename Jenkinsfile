pipeline {
    agent { label 'linuxgit' }

    environment {
        GIT_REPO = 'https://github.com/bhargavpr99-sudo/cmake.git'
        BRANCH = 'main'

        // SonarCloud Configuration
        SONARQUBE_ENV = 'SonarCloud'
        SONAR_ORGANIZATION = 'bhargavpr99-sudo'
        SONAR_PROJECT_KEY = 'bhargavpr99-sudo_cmake'
    }

    stages {
        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh '''
                    set -e
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential

                    # Setup Python virtual environment
                    if [ ! -d venv ]; then
                        python3 -m venv venv
                    fi
                    # Activate venv and install cmakelint
                    . venv/bin/activate
                    pip install --quiet cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint checks on main.c...'
                sh '''
                    . venv/bin/activate
                    if [ -f src/main.c ]; then
                        cmakelint src/main.c > lint_report.txt
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
                echo 'Running build with CMake...'
                sh '''
                    set -e
                    if [ -f CMakeLists.txt ]; then
                        mkdir -p build
                        cd build
                        cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
                        make -j$(nproc)
                        cp compile_commands.json ..
                    else
                        echo "CMakeLists.txt not found!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh '''
                    set -e
                    if [ -d build ]; then
                        cd build
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
                        set -e
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
                echo 'Checking SonarCloud Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
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
            echo 'Build, lint, and SonarCloud analysis completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs or SonarCloud dashboard.'
        }
    }
}
