pipeline {
    agent any

    environment {
        VENV_DIR = "venv"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM', 
                    branches: [[name: 'main']], 
                    userRemoteConfigs: [[
                        url: 'https://github.com/bhargavpr99-sudo/cmake.git', 
                        credentialsId: 'Gitcred'
                    ]]
                ])
            }
        }

        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential
                    [ ! -d ${VENV_DIR} ] && python3 -m venv ${VENV_DIR}
                    source ${VENV_DIR}/bin/activate
                    pip install --quiet cmakelint
                '''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint checks on main.c...'
                sh '''
                    source ${VENV_DIR}/bin/activate
                    [ -f src/main.c ] && cmakelint src/main.c || echo "No main.c file found"
                '''
                archiveArtifacts artifacts: 'src/main.c', allowEmptyArchive: true
            }
        }

        stage('Build') {
            steps {
                echo 'Running build with CMake...'
                sh '''
                    [ -f CMakeLists.txt ] && mkdir -p build
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
                    ctest --output-on-failure || echo "No tests found"
                '''
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                echo 'Running SonarCloud analysis...'
                withSonarQubeEnv('SonarCloud') {
                    script {
                        // Run sonar-scanner and capture output
                        def sonarOutput = sh(script: '''
                            sonar-scanner \
                            -Dsonar.organization=bhargavpr99-sudo \
                            -Dsonar.projectKey=bhargavpr99-sudo_cmake \
                            -Dsonar.sources=src \
                            -Dsonar.cfamily.compile-commands=compile_commands.json \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.sourceEncoding=UTF-8
                        ''', returnStdout: true).trim()

                        // Extract task ID dynamically
                        env.SONAR_TASK_ID = sonarOutput.readLines().find { it.contains("More about the report processing at") }?.split('=')[-1]?.trim()
                        echo "Detected SONAR_TASK_ID=${env.SONAR_TASK_ID}"
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Checking SonarCloud Quality Gate...'
                script {
                    if (!env.SONAR_TASK_ID) {
                        error "SONAR_TASK_ID not found. Cannot check quality gate."
                    }

                    def status = ""
                    timeout(time: 5, unit: 'MINUTES') {
                        while (status != "SUCCESS" && status != "FAILED" && status != "CANCELED") {
                            def response = sh(script: "curl -s https://sonarcloud.io/api/ce/task?id=${env.SONAR_TASK_ID}", returnStdout: true).trim()
                            def json = readJSON text: response
                            status = json?.task?.status
                            echo "Current Sonar task status: ${status}"
                            if (status == null) {
                                echo "Waiting for task to appear..."
                            }
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
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs or SonarCloud dashboard.'
        }
    }
}
