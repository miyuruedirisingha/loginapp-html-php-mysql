#!/bin/bash
# EC2 Deployment Script for PHP Login System

set -e

echo "================================================"
echo "PHP Login System - EC2 Deployment"
echo "================================================"

# Update system
echo "Updating system packages..."
sudo yum update -y || sudo apt-get update -y

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # For Amazon Linux 2
    sudo yum install -y docker || sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

# Install Docker Compose
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Git (if not present)
echo "Installing Git..."
sudo yum install -y git || sudo apt-get install -y git

# Create application directory
APP_DIR="/home/ec2-user/phpLogin"
echo "Creating application directory at $APP_DIR..."
mkdir -p $APP_DIR
cd $APP_DIR

# Clone or update repository
if [ -d ".git" ]; then
    echo "Updating existing repository..."
    git pull origin main
else
    echo "Cloning repository..."
    # Replace with your actual repository URL
    # git clone https://github.com/yourusername/phpLogin.git .
    echo "Please clone your repository manually or set the GIT_REPO variable"
fi

# Set proper permissions
echo "Setting permissions..."
sudo chown -R $USER:$USER $APP_DIR
chmod +x deploy.sh

# Configure environment
echo "Configuring environment..."
if [ ! -f ".env" ]; then
    cat > .env <<EOF
DB_HOST=database
DB_NAME=phplogin
DB_USER=phplogin_user
DB_PASS=phplogin_pass_$(openssl rand -hex 8)
MYSQL_ROOT_PASSWORD=root_pass_$(openssl rand -hex 8)
EOF
    echo "Environment file created with random passwords"
fi

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down || true

# Build and start containers
echo "Building and starting Docker containers..."
docker-compose up -d --build

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 15

# Check if containers are running
echo "Checking container status..."
docker-compose ps

# Display access information
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo ""
echo "================================================"
echo "✅ Deployment Complete!"
echo "================================================"
echo "Application URL: http://$PUBLIC_IP:8080"
echo "phpMyAdmin URL: http://$PUBLIC_IP:8081"
echo ""
echo "⚠️  Important Security Notes:"
echo "1. Configure Security Group to allow ports 8080, 8081"
echo "2. Set up SSL/HTTPS for production"
echo "3. Change default database passwords"
echo "4. Restrict phpMyAdmin access"
echo ""
echo "View logs: docker-compose logs -f"
echo "Stop services: docker-compose down"
echo "================================================"
