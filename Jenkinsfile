pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh 'pytest tests/unit'
            }
        }

        stage('Run Integration Tests') {
            steps {
                sh 'pytest tests/integration'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("vknysh79/hello-world-app:latest")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    sh 'docker push vknysh79/hello-world-app:latest'
                }
            }
        }
    }
}