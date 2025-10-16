pipeline {
    agent { label 'linuxgit' }
    environment {
        GIT_REPO = 'https://gitlab.com/sandeep160/pipeline-e2e.git'
        BRANCH = 'main'
        VENV_DIR = 'venv' // Virtual environment directory
    }
    stages {
        stage('Prepare Tools') {
            steps {
                echo 'Installing required tools...'
                sh(script: '''
set -e
sudo apt-get update -y || true
sudo apt-get install -y python3 python3-venv python3-pip dos2unix cmake build-essential || true

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi

# Activate venv and install cmakelint using bash
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
                echo 'Running build.sh...'
                sh(script: '''
bash -c "
set -e
if [ -f build.sh ]; then
    dos2unix build.sh
    chmod +x build.sh
    bash build.sh
else
    echo 'build.sh not found!'
    exit 1
fi
"
''')
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
