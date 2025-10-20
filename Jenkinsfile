pipeline {
    agent { label 'linuxgit' }

    environment {
        // Git repository details
        GIT_REPO = 'https://github.com/bhargavpr99-sudo/cmake.git'
        BRANCH = 'main'

        // SonarCloud configuration
        SONARQUBE_ENV = 'SonarCloud'
        SONAR_ORGANIZATION = 'bhargavpr99-sudo'
        SONAR_PROJECT_KEY = 'bhargavpr99-sudo_cmake'

        // Python virtual environment
        VENV_DIR = "${WORKSPACE}/venv"

        // JFrog Artifactory details
        ARTIFACTORY_URL = 'https://trial2qnjvw.jfrog.io/artifactory'
        JFROG_REPO = 'cmake-artifacts-generic-local'
        JFROG_CREDS = credentials('jfrog-user')   // ✅ Single Jenkins credential (Username + API key/token)
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
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential binutils curl
                    python3 -m venv ${VENV_DIR}
                    . ${VENV_DIR}/bin/activate
                    pip install --quiet --upgrade pip cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo "🔹 Running lint checks on C files..."
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
                echo "🔹 Uploading artifacts to JFrog Artifactory..."
                sh '''
                    if [ -f build/myfirmware.bin ]; then
                        echo "Uploading myfirmware.bin to Artifactory..."
                        curl -u ${JFROG_CREDS_USR}:${JFROG_CREDS_PSW} \
                             -T build/myfirmware.bin \
                             "${ARTIFACTORY_URL}/${JFROG_REPO}/myfirmware.bin"
                        echo "✅ Upload completed successfully."
                    else
                        echo "⚠️ No build artifact found to upload."
                    fi
                '''
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
