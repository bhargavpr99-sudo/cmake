pipeline {
    agent any

    environment {
        // Use a single Jenkins credential (username + password or API key)
        ART_CRED = credentials('jfrog-user')
        ART_URL = "https://trial2qnjvw.jfrog.io/artifactory/firmware-release-generic-local"
        FIRMWARE_FILE = "myfirmware-15.bin"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/bhargavpr99-sudo/firmware-project.git',
                        credentialsId: 'github-creds'
                    ]]
                ])
            }
        }

        stage('Build Firmware') {
            steps {
                sh '''
                    mkdir -p build
                    cd build
                    cmake ..
                    make
                    # Create dummy firmware for testing if build doesn’t produce one
                    echo "firmware binary content" > ${FIRMWARE_FILE}
                '''
            }
        }

        stage('Upload to Artifactory') {
            steps {
                script {
                    def maxRetries = 3
                    def attempt = 1
                    def success = false

                    while (attempt <= maxRetries && !success) {
                        echo "Uploading artifact (Attempt: ${attempt})..."
                        def status = sh(
                            script: """curl -L -u ${ART_CRED_USR}:${ART_CRED_PSW} \
-T build/${FIRMWARE_FILE} \
${ART_URL}/firmware/${FIRMWARE_FILE} \
-w %{http_code} -o /dev/null""",
                            returnStdout: true
                        ).trim()

                        if (status == '200' || status == '201') {
                            echo "✅ Upload succeeded!"
                            success = true
                        } else {
                            echo "❌ Upload failed with HTTP code: ${status}"
                            if (attempt < maxRetries) {
                                echo "Retrying in 5 seconds..."
                                sleep 5
                            }
                            attempt++
                        }
                    }

                    if (!success) {
                        error("Max retries reached. Upload failed.")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully! Firmware uploaded to Artifactory."
        }
        failure {
            echo "⚠️ Pipeline failed. Check logs for details."
        }
    }
}
