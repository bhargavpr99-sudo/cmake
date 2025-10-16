pipeline {
    agent { label 'linuxgit' }
    environment {
        GIT_REPO = 'https://github.com/bhargavpr99-sudo/cmake.git'
        BRANCH = 'main'
        VENV_DIR = 'venv' // Virtual environment directory
    }
    stages {
        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh '''
#!/bin/bash
set -e

# Update package list
sudo apt-get update -y || true

# Install required packages
sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential || true

# Create Python virtual environment for cmakelint if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi

# Activate venv and install cmakelint
source $VENV_DIR/bin/activate
pip install --quiet cmakelint
'''
            }
        }

        stage('Lint') {
            steps {
                echo 'Running lint checks on main.c...'
                sh '''
#!/bin/bash
set -e

if [ -f src/main.c ]; then
    source $VENV_DIR/bin/activate
    cmakelint src/main.c > lint_report.txt
    # Fail build if lint errors found (uncomment if strict)
    # grep -q "Total Errors: [1-9]" lint_report.txt && exit 1 || true
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
                echo 'Running build.sh...'
                sh '''
#!/bin/bash
set -e

if [ -f build.sh ]; then
    dos2unix build.sh
    chmod +x build.sh
    bash build.sh
else
    echo "build.sh not found!"
    exit 1
fi
'''
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Build and lint completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs.'
        }
    }
}
