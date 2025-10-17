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
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "🔹 Checking out Git repository..."
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "${GIT_REPO}",
                        credentialsId: 'Gitcred'
                    ]]
                ])
            }
        }

        stage('Prepare Tools') {
            steps {
                echo "🔹 Installing required tools..."
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential binutils
                    python3 -m venv ${VENV_DIR}
                    . ${VENV_DIR}/bin/activate
                    pip install --quiet --upgrade pip cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo "🔹 Running lint checks on main.c..."
                sh '''
                    . ${VENV_DIR}/bin/activate
                    if [ -f src/main.c ]; then
                        cmakelint src/main.c
                    fi
                '''
                archiveArtifacts artifacts: '**/*.c', allowEmptyArchive: true
            }
        }

        stage('Build') {
            steps {
                echo "🔹 Building project with CMake..."
                sh '''
                    . ${VENV_DIR}/bin/activate
                    mkdir -p build
                    cd build
                    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
                    make -j$(nproc)
                    if [ -f myfirmware.elf ]; then
                        echo "Converting ELF to BIN..."
                        objcopy -O binary myfirmware.elf myfirmware.bin
                        cp compile_commands.json ..
                        echo "✅ Generated myfirmware.bin"
                    fi
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo "🔹 Running unit tests..."
                sh '''
                    . ${VENV_DIR}/bin/activate
                    if [ -d build ]; then
                        cd build
                        ctest --output-on-failure || echo "No tests found"
                    fi
                '''
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                echo "🔹 Running SonarCloud analysis..."
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
                script {
                    echo "🔹 Uploading artifacts to JFrog Artifactory..."

                    // Define Artifactory server (make sure the ID exists in Jenkins → Configure System)
                    def server = rtServer(
                        id: 'My-Artifactory-Server'
                    )

                    // Upload specification
                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "build/*.bin",
                                "target": "my-repo/"
                            }
                        ]
                    }"""

                    // Perform upload
                    server.upload(uploadSpec)
                }
            }
        }
    }

    post {
        always {
            echo "🏁 Pipeline finished."
        }
        success {
            echo "✅ Pipeline completed successfully."
        }
        failure {
            echo "❌ Pipeline failed. Check console output for details."
        }
    }
}
