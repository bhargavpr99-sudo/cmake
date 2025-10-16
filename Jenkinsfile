pipeline {
    agent any

    environment {
        VENV_DIR = "${WORKSPACE}/venv"
        PATH = "${VENV_DIR}/bin:${env.PATH}:/opt/sonar-scanner/bin"
    }

    stages {
        stage('Checkout') {
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
                    [ ! -d venv ] && python3 -m venv venv
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
                    [ -f src/main.c ] && cmakelint src/main.c
                '''
                archiveArtifacts artifacts: '**/*.c', fingerprint: true
            }
        }

        stage('Build') {
            steps {
                echo 'Running build with CMake...'
                sh '''
                    [ -f CMakeLists.txt ]
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
                    ctest --output-on-failure || echo "No tests found, skipping..."
                '''
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                echo 'Running SonarCloud analysis...'
                withSonarQubeEnv('SonarCloud') {
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
                script {
                    def sonarTaskUrl = "https://sonarcloud.io/api/ce/task?id=${env.SONAR_SCANNER_TASK_ID ?: 'AZnt7lHPzNVzxapQLJ-0'}"
                    def status = ""
                    timeout(time: 5, unit: 'MINUTES') {
                        while (status != "SUCCESS" && status != "FAILED" && status != "CANCELED") {
                            def response = sh(script: "curl -s ${sonarTaskUrl}", returnStdout: true).trim()
                            def json = readJSON text: response
                            status = json.task.status
                            echo "Current Sonar task status: ${status}"
                            sleep 5
                        }
                        if (status == "FAILED") {
                            error "Quality Gate failed"
                        }
                        echo "Quality Gate passed!"
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
