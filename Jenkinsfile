pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'phplogin'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'your-registry.com' // Update with your registry
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials' // Update with your Jenkins credentials ID
        EC2_HOST = 'ec2-user@your-ec2-ip' // Update with your EC2 details
        EC2_KEY_CREDENTIALS_ID = 'ec2-ssh-key' // Update with your Jenkins SSH credentials ID
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
                echo "Docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'docker-compose -f docker-compose.yml up -d'
                sh 'sleep 15'
                sh '''
                    max_attempts=10
                    attempt=0
                    until curl --output /dev/null --silent --head --fail http://localhost:8080; do
                        if [ "$attempt" -ge "$max_attempts" ]; then
                            echo "Health check failed after $max_attempts attempts"
                            exit 1
                        fi
                        printf '.'
                        attempt=$((attempt + 1))
                        sleep 3
                    done
                    echo "Health check passed"
                '''
                sh 'docker exec phplogin_mysql mysqladmin ping -h localhost'
                echo 'Database connectivity verified'
            }
            post {
                always {
                    sh 'docker-compose down || true'
                }
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running security scan...'
                sh '''
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
                echo 'Security scan completed'
            }
        }

        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        set +x
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin "${DOCKER_REGISTRY}"
                        docker tag "${DOCKER_IMAGE}:${DOCKER_TAG}" "${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                        docker tag "${DOCKER_IMAGE}:latest" "${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest"
                        docker push "${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                        docker push "${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest"
                        docker logout "${DOCKER_REGISTRY}" || true
                    '''
                }
                echo "Image pushed to ${DOCKER_REGISTRY}"
            }
        }

        stage('Deploy to EC2') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo 'Deploying to EC2...'
                sshagent(credentials: [EC2_KEY_CREDENTIALS_ID]) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no "${EC2_HOST}" '
                            cd /home/ec2-user/phpLogin || exit 1

                            echo "Pulling latest code..."
                            git pull origin main

                            echo "Creating backup..."
                            docker exec phplogin_mysql mysqldump -u root -proot phplogin > backup_$(date +%Y%m%d_%H%M%S).sql || true

                            echo "Pulling Docker images..."
                            docker-compose pull

                            echo "Restarting containers..."
                            docker-compose up -d --no-deps --build

                            echo "Verifying deployment..."
                            sleep 5
                            docker-compose ps
                            curl -f http://localhost:8080

                            echo "Deployment completed successfully"
                        '
                    '''
                }
                echo 'Deployed to EC2 successfully'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }

        failure {
            echo 'Pipeline failed'
        }

        unstable {
            echo 'Pipeline is unstable'
        }

        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f --volumes || true'
            cleanWs()
        }
    }
}
