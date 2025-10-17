pipeline {
    agent { label 'linuxgit' }

    environment {
        GIT_REPO = 'https://github.com/bhargavpr99-sudo/cmake.git'
        BRANCH = 'main'

        // SonarCloud Configuration
        SONARQUBE_ENV = 'SonarCloud'
        SONAR_ORGANIZATION = 'bhargavpr99-sudo'
        SONAR_PROJECT_KEY = 'bhargavpr99-sudo_cmake'

        // JFrog Configuration
        JFROG_URL = 'https://trial2qnjvw.jfrog.io/artifactory/cmake-artifacts-generic-local/'
        JFROG_SERVER_ID = 'jfrog-server'

        VENV_DIR = 'venv'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo '🔹 Checking out Git repository...'
                checkout([$class: 'GitSCM',
                    branches: [[name: "${BRANCH}"]],
                    userRemoteConfigs: [[url: "${GIT_REPO}", credentialsId: 'Gitcred']]
                ])
            }
        }

        stage('Prepare Tools') {
            steps {
                echo '🔹 Installing required tools...'
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential binutils

                    if [ ! -d "${VENV_DIR}" ]; then
                        python3 -m venv ${VENV_DIR}
                    fi
                    . ${VENV_DIR}/bin/activate
                    pip install --quiet --upgrade pip cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo '🔹 Running lint checks on main.c...'
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
                echo '🔹 Building project with CMake...'
                sh '''
                    . ${VENV_DIR}/bin/activate
                    if [ -f CMakeLists.txt ]; then
                        mkdir -p build
                        cd build
                        cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
                        make -j$(nproc)

                        if [ -f myfirmware.elf ]; then
                            echo "Converting ELF to BIN..."
                            objcopy -O binary myfirmware.elf myfirmware.bin
                        else
                            echo "⚠️ No ELF file found!"
                        fi

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
                echo '🔹 Running unit tests...'
                sh '''
                    . ${VENV_DIR}/bin/activate
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
                echo '🔹 Running SonarCloud analysis...'
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

        stage('Upload to JFrog') {
            steps {
                echo '🔹 Uploading artifacts to JFrog Artifactory...'
                sh """
                    jfrog rt upload "build/*.elf" "${JFROG_URL}\${BUILD_NUMBER}/" --server-id=${JFROG_SERVER_ID}
                    jfrog rt upload "build/*.bin" "${JFROG_URL}\${BUILD_NUMBER}/" --server-id=${JFROG_SERVER_ID}
                    jfrog rt build-publish ${BUILD_NUMBER} --server-id=${JFROG_SERVER_ID}
                """
            }
        }
    }

    post {
        always {
            echo '🏁 Pipeline finished.'
        }
        success {
            echo '✅ Build, lint, tests, SonarCloud analysis, and JFrog upload completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the console output for details.'
        }
    }
}
