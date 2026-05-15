pipeline {
    agent any

    environment {
        DOCKER_IMAGE   = 'wiemabdennadher/aston-villa-app'
        CONTAINER_NAME = 'aston-villa-app'
    }

    stages {

        stage('Clone') {
            steps {
                checkout scm
                script {
                    env.DOCKER_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                }
                sh 'echo Cloned. Tag: $DOCKER_TAG'
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
                    docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest
                    echo "Built: $DOCKER_IMAGE:$DOCKER_TAG"
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
                        echo "Pushed to DockerHub"
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker stop $CONTAINER_NAME  || true
                    docker rm   $CONTAINER_NAME  || true
                    docker run -d \
                        --name $CONTAINER_NAME \
                        -p 4200:80 \
                        --restart unless-stopped \
                        $DOCKER_IMAGE:$DOCKER_TAG
                    echo "App running at http://$(hostname -I | awk '{print $1}'):4200"
                '''
            }
        }
    }

    post {
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed. Check logs above.' }
        always  { sh 'docker logout || true' }
    }
}