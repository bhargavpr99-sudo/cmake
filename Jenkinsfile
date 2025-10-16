pipeline {
    agent { label 'linuxgit' }

    environment {
        GIT_REPO = 'https://gitlab.com/sandeep160/pipeline-e2e.git'
        BRANCH = 'main'

        // SonarCloud Configuration
        SONARQUBE_ENV = 'SonarCloud'
        SONAR_ORGANIZATION = 'sandeep160'
        SONAR_PROJECT_KEY = 'sandeep160_pipeline-e2e'
        VENV_DIR = 'venv' // Python virtual environment
    }

    stages {
        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh(script: '''
set -e
sudo apt-get update -y || true
sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential || true

# Create virtual environment for cmakelint
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi

# Activate venv and install cmakelint
bash -c "source $VENV_DIR/bin/activate && pip install --quiet cmakelint"
''')
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint checks on main.c...'
                sh(script: '''
bash -c "
set -e
if [ -f src/main.c ]; then
    source $VENV_DIR/bin/activate
    cmakelint src/main.c > lint_report.txt
else
    echo 'main.c not found!'
    exit 1
fi
"
''')
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
                sh(script: '''
bash -c "
set -e
if [ -f CMakeLists.txt ]; then
    mkdir -p build
    cd build
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
    make -j$(nproc)
    cp compile_commands.json ..
else
    echo 'CMakeLists.txt not found!'
    exit 1
fi
"
''')
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh(script: '''
bash -c "
set -e
if [ -d build ]; then
    cd build
    ctest --output-on-failure
else
    echo 'Build directory not found!'
    exit 1
fi
"
''')
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                echo 'Running SonarCloud analysis...'
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh(script: '''
bash -c "
set -e
sonar-scanner \
  -Dsonar.organization=${SONAR_ORGANIZATION} \
  -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
  -Dsonar.sources=src \
  -Dsonar.cfamily.compile-commands=compile_commands.json \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.sourceEncoding=UTF-8
"
''')
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
