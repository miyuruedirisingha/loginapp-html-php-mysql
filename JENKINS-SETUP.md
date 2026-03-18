# Jenkins Configuration Guide

## 🔧 Jenkins Setup & Configuration

### Prerequisites

1. **Jenkins Installation**
   - Jenkins 2.x or higher
   - Java 11 or higher

2. **Required Jenkins Plugins**
   ```
   - Docker Pipeline Plugin
   - Docker Plugin
   - Git Plugin
   - SSH Agent Plugin
   - Pipeline Plugin
   - Workspace Cleanup Plugin
   - Email Extension Plugin (optional)
   - Slack Notification Plugin (optional)
   ```

3. **Install Plugins**
   - Go to: `Manage Jenkins` → `Manage Plugins` → `Available`
   - Search and install the plugins listed above
   - Restart Jenkins after installation

## 🔐 Credentials Setup

### 1. Docker Registry Credentials

**For Docker Hub:**
```
1. Go to: Manage Jenkins → Manage Credentials → Global → Add Credentials
2. Kind: Username with password
3. Username: your-dockerhub-username
4. Password: your-dockerhub-password (or access token)
5. ID: docker-hub-credentials
6. Description: Docker Hub Credentials
7. Click 'OK'
```

**For Private Registry:**
```
Same as above, but use your private registry credentials
```

### 2. EC2 SSH Key Credentials

```
1. Go to: Manage Jenkins → Manage Credentials → Global → Add Credentials
2. Kind: SSH Username with private key
3. Username: ec2-user (or ubuntu for Ubuntu instances)
4. Private Key: Enter directly → Paste your .pem file content
5. ID: ec2-ssh-key
6. Description: EC2 SSH Key
7. Click 'OK'
```

### 3. Git Credentials (if private repo)

```
1. Go to: Manage Jenkins → Manage Credentials → Global → Add Credentials
2. Kind: Username with password (or SSH key)
3. Username: your-git-username
4. Password: your-personal-access-token
5. ID: git-credentials
6. Click 'OK'
```

## 📋 Jenkinsfile Configuration

Update these values in the Jenkinsfile:

```groovy
environment {
    DOCKER_IMAGE = 'phplogin'                              // Your image name
    DOCKER_REGISTRY = 'docker.io/yourusername'            // Your registry URL
    DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'       // Credentials ID from Jenkins
    EC2_HOST = 'ec2-user@your-ec2-public-ip'              // Your EC2 instance
    EC2_KEY_CREDENTIALS_ID = 'ec2-ssh-key'                // SSH key credentials ID
}
```

### Example Configurations:

**Docker Hub:**
```groovy
DOCKER_REGISTRY = 'docker.io'
DOCKER_IMAGE = 'username/phplogin'
```

**Amazon ECR:**
```groovy
DOCKER_REGISTRY = '123456789.dkr.ecr.us-east-1.amazonaws.com'
DOCKER_IMAGE = 'phplogin'
```

**Google Container Registry:**
```groovy
DOCKER_REGISTRY = 'gcr.io/your-project-id'
DOCKER_IMAGE = 'phplogin'
```

## 🚀 Creating a Jenkins Pipeline Job

### Method 1: Pipeline from SCM (Recommended)

```
1. New Item → Pipeline → Enter name → OK
2. Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/yourusername/phpLogin.git
   - Credentials: Select your Git credentials (if private)
   - Branch: */main
   - Script Path: Jenkinsfile
3. Build Triggers (optional):
   - ☑ GitHub hook trigger for GITScm polling (for auto-build on push)
   - ☑ Poll SCM: H/5 * * * * (check every 5 minutes)
4. Save
```

### Method 2: Pipeline Script (Direct)

```
1. New Item → Pipeline → Enter name → OK
2. Pipeline section:
   - Definition: Pipeline script
   - Script: Copy entire Jenkinsfile content here
3. Save
```

## 🔔 Configure Notifications (Optional)

### Email Notifications

1. **Configure Email Server:**
   ```
   Manage Jenkins → Configure System → Extended E-mail Notification
   - SMTP server: smtp.gmail.com (for Gmail)
   - Default user e-mail suffix: @gmail.com
   - Use SMTP Authentication
   - User Name: your-email@gmail.com
   - Password: your-app-password
   - Use SSL: ☑
   - SMTP Port: 465
   ```

2. **Enable in Jenkinsfile:**
   Uncomment the email sections in the `post` block

### Slack Notifications

1. **Install Slack App:**
   - Add Jenkins CI app to your Slack workspace
   - Get the webhook URL and token

2. **Configure in Jenkins:**
   ```
   Manage Jenkins → Configure System → Slack
   - Workspace: your-workspace
   - Credential: Add Slack token
   - Default channel: #deployments
   ```

3. **Enable in Jenkinsfile:**
   Uncomment the Slack sections in the `post` block

## 🧪 Testing the Pipeline

### 1. Manual Trigger
```
1. Go to your Jenkins job
2. Click "Build Now"
3. Monitor "Console Output"
```

### 2. Test Individual Stages

Create a test Jenkinsfile:
```groovy
pipeline {
    agent any
    stages {
        stage('Test Docker') {
            steps {
                sh 'docker --version'
                sh 'docker-compose --version'
            }
        }
        stage('Test SSH') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh 'ssh -o StrictHostKeyChecking=no ec2-user@YOUR_EC2_IP "echo Connected"'
                }
            }
        }
    }
}
```

## 🔍 Troubleshooting

### Issue: Docker command not found
**Solution:**
```bash
# On Jenkins server
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: SSH connection refused
**Solution:**
```
1. Check Security Group allows Jenkins IP on port 22
2. Verify EC2 instance is running
3. Test SSH manually: ssh -i key.pem ec2-user@ec2-ip
4. Check credentials ID matches in Jenkinsfile
```

### Issue: Permission denied on docker-compose
**Solution:**
```bash
# On EC2 instance
sudo usermod -aG docker ec2-user
# Re-login or restart SSH session
```

### Issue: Health check fails
**Solution:**
```
1. Check if port 8080 is accessible
2. Increase sleep time in health check
3. Check docker-compose logs
4. Verify application starts correctly
```

### Issue: Push to registry fails
**Solution:**
```
1. Verify credentials are correct
2. Login manually: docker login
3. Check registry URL format
4. Ensure proper permissions for the repository
```

## 📊 Monitoring & Logs

### View Build Logs
```
1. Go to build number
2. Click "Console Output"
3. Or use Blue Ocean for better visualization
```

### View Container Logs on EC2
```bash
ssh -i key.pem ec2-user@ec2-ip
cd /home/ec2-user/phpLogin
docker-compose logs -f
```

### View Jenkins Logs
```bash
# On Jenkins server
tail -f /var/log/jenkins/jenkins.log
```

## 🎯 Best Practices

1. **Use Branches for Testing:**
   - `develop` branch for testing
   - `main` branch for production
   - Create separate pipelines for each

2. **Backup Before Deploy:**
   - Always backup database before deployment
   - Keep last 5-10 backups
   - Test restore process

3. **Implement Rollback:**
   - Tag Docker images with version
   - Keep previous version running
   - Quick rollback procedure documented

4. **Security:**
   - Never commit credentials
   - Use Jenkins credentials management
   - Rotate passwords regularly
   - Enable HTTPS for Jenkins

5. **Monitoring:**
   - Set up CloudWatch alarms
   - Monitor Docker container health
   - Track deployment success rate

## 📝 Quick Reference Commands

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
journalctl -u jenkins -f

# Test Docker access from Jenkins
sudo -u jenkins docker ps

# Trigger build via CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build phplogin-pipeline

# Clean Jenkins workspace
rm -rf /var/lib/jenkins/workspace/*
```

## 🆘 Emergency Rollback

If deployment fails:

```bash
# On EC2
cd /home/ec2-user/phpLogin

# Stop current containers
docker-compose down

# Restore database from backup
docker exec -i phplogin_mysql mysql -u root -proot phplogin < backup_YYYYMMDD_HHMMSS.sql

# Revert to previous version
git checkout <previous-commit-hash>
docker-compose up -d

# Or use previous Docker image
docker-compose pull <previous-tag>
docker-compose up -d
```

## ✅ Deployment Checklist

Before running the pipeline:

- [ ] Jenkins plugins installed
- [ ] Docker credentials configured
- [ ] EC2 SSH credentials configured
- [ ] EC2 Security Group allows Jenkins IP
- [ ] Docker and docker-compose installed on EC2
- [ ] Application repository accessible
- [ ] Jenkinsfile updated with correct values
- [ ] Test pipeline on develop branch first
- [ ] Backup procedures in place
- [ ] Rollback procedure documented
- [ ] Monitoring and alerts configured

---

**Your Jenkins pipeline is now configured!** 🎉

Start with a test build on a develop branch before deploying to production.
