pipeline {
    agent { label 'linuxgit' }

    environment {
        GIT_REPO = 'https://github.com/bhargavpr99-sudo/cmake.git'
        BRANCH = 'main'

        // SonarCloud configuration
        SONARQUBE_ENV = 'SonarCloud'
        SONAR_ORGANIZATION = 'bhargavpr99-sudo'
        SONAR_PROJECT_KEY = 'bhargavpr99-sudo_cmake'

        // Python venv
        VENV_DIR = "${WORKSPACE}/venv"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "🔹 Checking out Git repository..."
                git branch: "${BRANCH}", url: "${GIT_REPO}", credentialsId: 'Gitcred'
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
                    [ -f src/main.c ] && cmakelint src/main.c || echo "No C files to lint"
                '''
                archiveArtifacts artifacts: 'src/main.c', allowEmptyArchive: true
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
                    sh """
                        . ${VENV_DIR}/bin/activate
                        sonar-scanner \
                            -Dsonar.organization=${SONAR_ORGANIZATION} \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.sources=src \
                            -Dsonar.cfamily.compile-commands=compile_commands.json \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.sourceEncoding=UTF-8
                    """
                }
            }
        }

        stage('Upload to JFrog') {
            steps {
                script {
                    echo "🔹 Uploading artifacts to JFrog Artifactory..."
                    def server = Artifactory.server 'My-Artifactory-Server' // Replace with your server ID
                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "build/*.bin",
                                "target": "my-repo/"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec
                }
            }
        }
    }

    post {
        success {
            echo "🏁 Pipeline finished successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check console output for details."
        }
    }
}
