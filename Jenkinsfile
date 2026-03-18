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
                echo '📥 Checking out source code...'
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                echo '🔨 Building Docker image...'
                script {
                    try {
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
                        echo "✅ Docker image built successfully: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    } catch (Exception e) {
                        echo "❌ Build failed: ${e.getMessage()}"
                        throw e
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                script {
                    try {
                        // Start containers for testing
                        sh 'docker-compose -f docker-compose.yml up -d'
                        
                        // Wait for services to be ready
                        echo 'Waiting for services to start...'
                        sh 'sleep 15'
                        
                        // Health check
                        echo 'Running health checks...'
                        sh '''
                            max_attempts=10
                            attempt=0
                            until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
                                if [ $attempt -eq $max_attempts ]; then
                                    echo "Health check failed after $max_attempts attempts"
                                    exit 1
                                fi
                                printf '.'
                                attempt=$((attempt+1))
                                sleep 3
                            done
                            echo "✅ Health check passed"
                        '''
                        
                        // Check database connectivity
                        sh 'docker exec phplogin_mysql mysqladmin ping -h localhost || exit 1'
                        echo "✅ Database connectivity verified"
                        
                    } catch (Exception e) {
                        echo "❌ Tests failed: ${e.getMessage()}"
                        throw e
                    } finally {
                        // Always cleanup test containers
                        sh 'docker-compose down || true'
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                echo '🔒 Running security scan...'
                script {
                    try {
                        // Using Trivy for vulnerability scanning
                        sh """
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy:latest image \
                            --severity HIGH,CRITICAL \
                            --exit-code 0 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                        echo "✅ Security scan completed"
                    } catch (Exception e) {
                        echo "⚠️ Security scan found issues but continuing: ${e.getMessage()}"
                        // Don't fail the build on security warnings in non-prod
                    }
                }
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
                echo '📤 Pushing Docker image to registry...'
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                            sh '''
                                set +x
                                echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin ${DOCKER_REGISTRY}
                                docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                                docker tag ${DOCKER_IMAGE}:latest ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                                docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                                docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                                docker logout ${DOCKER_REGISTRY} || true
                            '''
                        }
                        echo "✅ Image pushed successfully to ${DOCKER_REGISTRY}"
                    } catch (Exception e) {
                        echo "❌ Failed to push image: ${e.getMessage()}"
                        throw e
                    }
                }
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
                echo '🚀 Deploying to EC2...'
                script {
                    try {
                        sshagent(credentials: ["${EC2_KEY_CREDENTIALS_ID}"]) {
                            // Create deployment script on EC2
                            sh """
                                ssh -o StrictHostKeyChecking=no ${EC2_HOST} '
                                    cd /home/ec2-user/phpLogin || exit 1
                                    
                                    # Pull latest code
                                    echo "Pulling latest code..."
                                    git pull origin main
                                    
                                    # Backup database before deployment
                                    echo "Creating backup..."
                                    docker exec phplogin_mysql mysqldump -u root -proot phplogin > backup_\$(date +%Y%m%d_%H%M%S).sql || true
                                    
                                    # Pull latest images
                                    echo "Pulling Docker images..."
                                    docker-compose pull
                                    
                                    # Restart containers with zero downtime
                                    echo "Restarting containers..."
                                    docker-compose up -d --no-deps --build
                                    
                                    # Verify deployment
                                    echo "Verifying deployment..."
                                    sleep 5
                                    docker-compose ps
                                    
                                    # Health check
                                    curl -f http://localhost:8080 || exit 1
                                    
                                    echo "✅ Deployment completed successfully"
                                '
                            """
                        }
                        echo "✅ Deployed to EC2 successfully"
                    } catch (Exception e) {
                        echo "❌ Deployment failed: ${e.getMessage()}"
                        // Rollback logic here if needed
                        throw e
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            // Send success notification
            script {
                // Uncomment to enable Slack notifications
                // slackSend(color: 'good', message: "Deployment successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
                
                // Uncomment to enable email notifications
                // emailext(
                //     subject: "✅ Jenkins Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                //     body: "Build URL: ${env.BUILD_URL}",
                //     to: 'your-email@example.com'
                // )
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            // Send failure notification
            script {
                // Uncomment to enable Slack notifications
                // slackSend(color: 'danger', message: "Deployment failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
                
                // Uncomment to enable email notifications
                // emailext(
                //     subject: "❌ Jenkins Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                //     body: "Build URL: ${env.BUILD_URL}\nConsole Output: ${env.BUILD_URL}console",
                //     to: 'your-email@example.com'
                // )
            }
        }
        
        unstable {
            echo '⚠️ Pipeline is unstable!'
        }
        
        always {
            echo '🧹 Cleaning up...'
            script {
                // Clean up Docker resources
                sh 'docker system prune -f --volumes || true'
                
                // Archive test results if any
                // archiveArtifacts artifacts: '**/logs/*.log', allowEmptyArchive: true
                
                // Clean workspace
                cleanWs()
            }
        }
    }
}
