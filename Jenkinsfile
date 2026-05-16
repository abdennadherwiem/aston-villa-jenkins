pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'wiemabdennadher/aston-villa-app'
        DOCKER_TAG   = getVersion()
        CONTAINER_NAME = 'aston-villa-app'
    }

    stages {

        stage('Clone') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/abdennadherwiem/aston-villa-jenkins.git'
                sh 'echo ✅ Cloned. Tag: $DOCKER_TAG'
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
                    docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest
                    echo "✅ Built: $DOCKER_IMAGE:$DOCKER_TAG"
                '''
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $DOCKER_IMAGE:$DOCKER_TAG
                        docker push $DOCKER_IMAGE:latest
                        echo "✅ Pushed to DockerHub"
                    '''
                }
            }
        }

    stage('Deploy via SSH') {
    steps {
        sshagent(credentials: ['Vagrant_ssh']) {
            sh """
                ssh -o StrictHostKeyChecking=no master@192.168.1.13 '
                    docker pull wiemabdennadher/aston-villa-app:$DOCKER_TAG &&
                    docker stop aston-villa-app || true &&
                    docker rm aston-villa-app || true &&
                    docker run -d -p 4200:80 --name aston-villa-app wiemabdennadher/aston-villa-app:$DOCKER_TAG
                '
            """
        }
    }
}
}
    post {
        success { echo '🎉 Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed. Check logs above.' }
        always  { sh 'docker logout || true' }
    }
}

def getVersion() {
    return sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
}
