
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                script {
                    try {
                        checkout scm
                    } catch (Exception e) {
                        echo "Error during Checkout: ${e.getMessage()}"
                        error("Checkout failed")
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    try {
                        sh 'pip install -r requirements.txt'
                    } catch (Exception e) {
                        echo "Error installing dependencies: ${e.getMessage()}"
                        error("Dependency installation failed")
                    }
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                    try {
                        sh 'pytest tests/unit'
                    } catch (Exception e) {
                        echo "Error running unit tests: ${e.getMessage()}"
                        error("Unit tests failed")
                    }
                }
            }
        }

        stage('Run Integration Tests') {
            steps {
                script {
                    try {
                        sh 'pytest tests/integration'
                    } catch (Exception e) {
                        echo "Error running integration tests: ${e.getMessage()}"
                        error("Integration tests failed")
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        docker.build("vknysh79/hello-world-app:latest")
                    } catch (Exception e) {
                        echo "Error building Docker image: ${e.getMessage()}"
                        error("Docker build failed")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                            sh 'docker push vknysh79/hello-world-app:latest'
                        }
                    } catch (Exception e) {
                        echo "Error pushing Docker image: ${e.getMessage()}"
                        error("Docker push failed")
                    }
                }
            }
        }
    }
}

