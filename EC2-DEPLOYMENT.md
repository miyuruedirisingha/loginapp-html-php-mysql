# PHP Login System - EC2 Deployment Guide

## 📋 Prerequisites

- AWS Account
- EC2 instance (t2.micro or higher)
- Amazon Linux 2 or Ubuntu 20.04+
- Security Group configured
- SSH key pair

## 🚀 Quick Deployment

### Step 1: Launch EC2 Instance

1. **Go to EC2 Dashboard** in AWS Console
2. **Launch Instance** with these settings:
   - **AMI**: Amazon Linux 2 or Ubuntu 20.04
   - **Instance Type**: t2.micro (free tier) or t2.small
   - **Storage**: 8-20 GB
   - **Key Pair**: Create or select existing

3. **Configure Security Group**:
   ```
   Type            Port    Source          Description
   SSH             22      Your IP         SSH access
   Custom TCP      8080    0.0.0.0/0       Application
   Custom TCP      8081    Your IP         phpMyAdmin (restrict!)
   HTTP            80      0.0.0.0/0       Optional (for reverse proxy)
   HTTPS           443     0.0.0.0/0       Optional (for SSL)
   ```

### Step 2: Connect to EC2

```bash
# SSH into your instance
ssh -i "your-key.pem" ec2-user@your-ec2-public-ip

# Or for Ubuntu
ssh -i "your-key.pem" ubuntu@your-ec2-public-ip
```

### Step 3: Deploy Application

**Option A: Automated Deployment (Recommended)**

```bash
# Upload deployment script
scp -i "your-key.pem" deploy.sh ec2-user@your-ec2-ip:/home/ec2-user/

# SSH into EC2 and run
ssh -i "your-key.pem" ec2-user@your-ec2-ip
chmod +x deploy.sh
./deploy.sh
```

**Option B: Manual Deployment**

```bash
# 1. Update system
sudo yum update -y  # Amazon Linux
# OR
sudo apt-get update -y  # Ubuntu

# 2. Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 3. Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Logout and login again (for docker group)
exit
# SSH back in

# 5. Clone your project
git clone https://github.com/yourusername/phpLogin.git
cd phpLogin

# 6. Start services
docker-compose up -d

# 7. Check status
docker-compose ps
```

### Step 4: Access Application

```
Application: http://your-ec2-public-ip:8080
phpMyAdmin: http://your-ec2-public-ip:8081
```

## 🔒 Production Security Setup

### 1. Use Environment Variables

Create `.env` file:
```env
DB_HOST=database
DB_NAME=phplogin
DB_USER=phplogin_user
DB_PASS=your_secure_password_here
MYSQL_ROOT_PASSWORD=your_root_password_here
```

Update `docker-compose.yml` to use env_file:
```yaml
services:
  database:
    env_file: .env
```

### 2. Set Up Nginx Reverse Proxy (Optional)

```bash
# Install nginx
sudo yum install -y nginx

# Configure nginx
sudo nano /etc/nginx/conf.d/phplogin.conf
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 3. Set Up SSL with Let's Encrypt

```bash
# Install certbot
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
```

### 4. Restrict phpMyAdmin Access

Update Security Group to allow port 8081 only from your IP:
```
Custom TCP  8081  Your-IP/32  phpMyAdmin
```

### 5. Regular Updates

```bash
# Create update script
cat > /home/ec2-user/update.sh <<'EOF'
#!/bin/bash
cd /home/ec2-user/phpLogin
git pull origin main
docker-compose down
docker-compose up -d --build
EOF

chmod +x /home/ec2-user/update.sh
```

## 📊 Monitoring & Maintenance

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f database
```

### Check Resource Usage
```bash
# Container stats
docker stats

# Disk usage
df -h

# Memory usage
free -m
```

### Backup Database
```bash
# Manual backup
docker exec phplogin_mysql mysqldump -u root -proot phplogin > backup_$(date +%Y%m%d).sql

# Automated daily backup (crontab)
crontab -e
# Add: 0 2 * * * docker exec phplogin_mysql mysqldump -u root -proot phplogin > /home/ec2-user/backups/backup_$(date +\%Y\%m\%d).sql
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart web
```

## 🔧 Troubleshooting

### Containers won't start
```bash
# Check logs
docker-compose logs

# Check if ports are available
sudo netstat -tlnp | grep 8080

# Rebuild containers
docker-compose down
docker-compose up -d --build --force-recreate
```

### Database connection issues
```bash
# Check database container
docker exec -it phplogin_mysql mysql -u root -p

# Verify environment variables
docker exec phplogin_web env | grep DB_
```

### Out of disk space
```bash
# Clean up Docker
docker system prune -a

# Remove old images
docker image prune -a
```

## 💰 Cost Optimization

### Use t2.micro for testing
- Free tier eligible
- Suitable for low traffic

### Stop instance when not needed
```bash
# From AWS Console or CLI
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
```

### Use Reserved Instances for production
- Save up to 75% for 1-3 year commitments

## 📈 Scaling Options

### Vertical Scaling
- Upgrade to larger instance type (t2.small → t2.medium)

### Horizontal Scaling
- Use Application Load Balancer
- Deploy multiple EC2 instances
- Use RDS for managed database

### Managed Services
- **AWS RDS** for MySQL
- **AWS ECS/EKS** for container orchestration
- **AWS Elastic Beanstalk** for managed deployment

## 🎯 Production Checklist

- [ ] Security Group properly configured
- [ ] SSL certificate installed
- [ ] Strong database passwords
- [ ] Automated backups enabled
- [ ] Monitoring set up (CloudWatch)
- [ ] Domain name configured
- [ ] Firewall rules reviewed
- [ ] phpMyAdmin access restricted
- [ ] Regular updates scheduled
- [ ] Error logging configured

## 📞 Support

For issues:
1. Check logs: `docker-compose logs`
2. Review AWS CloudWatch logs
3. Check Security Group settings
4. Verify Docker service: `sudo systemctl status docker`
