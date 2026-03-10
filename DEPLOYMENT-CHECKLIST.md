# AWS EC2 Deployment Checklist

## ✅ Pre-Deployment Checklist

### AWS Account Setup
- [ ] AWS account created and verified
- [ ] Billing alerts configured
- [ ] IAM user created (don't use root account)
- [ ] Access keys generated (if using CLI)

### EC2 Instance
- [ ] EC2 instance launched
- [ ] Instance type selected (t2.micro for testing, t2.small+ for production)
- [ ] Key pair downloaded and saved securely (.pem file)
- [ ] Elastic IP assigned (optional, for static IP)

### Security Group Configuration
- [ ] Port 22 (SSH) - Your IP only
- [ ] Port 8080 (Application) - 0.0.0.0/0 or specific IPs
- [ ] Port 8081 (phpMyAdmin) - Your IP only (IMPORTANT!)
- [ ] Port 80 (HTTP) - 0.0.0.0/0 (if using reverse proxy)
- [ ] Port 443 (HTTPS) - 0.0.0.0/0 (if using SSL)

## 📦 Deployment Steps

### Step 1: Connect to EC2
```bash
chmod 400 your-key.pem
ssh -i "your-key.pem" ec2-user@YOUR_EC2_IP
```
- [ ] Successfully connected via SSH
- [ ] Can access EC2 terminal

### Step 2: Upload Files
```bash
# From your local machine
scp -i "your-key.pem" deploy.sh ec2-user@YOUR_EC2_IP:/home/ec2-user/
scp -i "your-key.pem" -r phpLogin ec2-user@YOUR_EC2_IP:/home/ec2-user/
```
OR
```bash
# Clone from Git on EC2
git clone https://github.com/yourusername/phpLogin.git
```
- [ ] Files uploaded to EC2
- [ ] Project directory accessible

### Step 3: Run Deployment
```bash
cd phpLogin
chmod +x deploy.sh
./deploy.sh
```
- [ ] Docker installed successfully
- [ ] Docker Compose installed successfully
- [ ] Containers built and started
- [ ] All containers running (`docker-compose ps`)

### Step 4: Verify Deployment
```bash
# Check containers
docker-compose ps

# Check logs
docker-compose logs

# Test database connection
docker exec -it phplogin_mysql mysql -u root -p
```
- [ ] Web container running
- [ ] Database container running
- [ ] phpMyAdmin container running
- [ ] No errors in logs

### Step 5: Access Application
- [ ] Application accessible at http://YOUR_EC2_IP:8080
- [ ] Login page loads correctly
- [ ] Can login with test credentials
- [ ] phpMyAdmin accessible at http://YOUR_EC2_IP:8081

## 🔒 Security Hardening

### Database Security
- [ ] Changed default database passwords
- [ ] Created `.env` file with secure credentials
- [ ] Removed test users (admin, demo)
- [ ] Configured proper user permissions

### Application Security
- [ ] phpMyAdmin restricted to your IP only
- [ ] Strong passwords enforced
- [ ] Session timeout configured
- [ ] Error messages don't expose sensitive info

### Server Security
- [ ] OS updates applied (`sudo yum update -y`)
- [ ] Unnecessary services disabled
- [ ] Firewall configured
- [ ] SSH configured for key-only authentication
- [ ] Root login disabled

### SSL/HTTPS (Production)
- [ ] Domain name configured
- [ ] SSL certificate installed (Let's Encrypt)
- [ ] HTTPS redirect enabled
- [ ] HTTP traffic redirected to HTTPS

## 📊 Monitoring & Maintenance

### Monitoring Setup
- [ ] CloudWatch alarms configured
- [ ] Log monitoring enabled
- [ ] Disk space alerts set up
- [ ] CPU/Memory alerts configured

### Backup Strategy
- [ ] Automated backup script configured (`backup.sh`)
- [ ] Backup schedule set (cron job)
- [ ] Backup location configured (local or S3)
- [ ] Backup restoration tested

### Regular Maintenance
- [ ] Update schedule planned
- [ ] Log rotation configured
- [ ] Docker cleanup scheduled (`docker system prune`)
- [ ] Security patches monitored

## 🚨 Troubleshooting Verification

### If Application Doesn't Load
- [ ] Security Group allows port 8080
- [ ] Docker containers are running
- [ ] Check logs: `docker-compose logs web`
- [ ] Verify port not blocked: `sudo netstat -tlnp | grep 8080`

### If Database Connection Fails
- [ ] Database container is running
- [ ] Check database logs: `docker-compose logs database`
- [ ] Verify credentials in config/database.php
- [ ] Test manual connection: `docker exec -it phplogin_mysql mysql -u root -p`

### If Out of Memory/Disk
- [ ] Check disk usage: `df -h`
- [ ] Check memory: `free -m`
- [ ] Clean Docker: `docker system prune -a`
- [ ] Check logs size: `du -sh /var/log/*`

## 📈 Production Ready

### Performance
- [ ] Database indexed properly
- [ ] PHP opcache enabled
- [ ] Static assets cached
- [ ] CDN configured (optional)

### Scaling
- [ ] Load balancer configured (if needed)
- [ ] Auto-scaling group set up (if needed)
- [ ] RDS instead of container database (recommended for production)
- [ ] ElastiCache for sessions (optional)

### Documentation
- [ ] Deployment documentation updated
- [ ] Runbook created for common issues
- [ ] Contact information for support
- [ ] Recovery procedures documented

## 🎯 Final Verification

Before going live:
- [ ] All test credentials removed
- [ ] Production passwords set
- [ ] Backups verified and tested
- [ ] SSL certificate valid
- [ ] Monitoring alerts working
- [ ] DNS properly configured
- [ ] Load testing performed
- [ ] Security audit completed
- [ ] Disaster recovery plan in place
- [ ] Team trained on deployment process

## 📞 Emergency Contacts

```
AWS Support: https://console.aws.amazon.com/support/
Instance ID: _________________
Region: _____________________
Elastic IP: __________________
```

## 📝 Notes

```
Deployment Date: ______________
Deployed By: __________________
Version: ______________________
Special Configurations:
_________________________________
_________________________________
_________________________________
```

---

✅ **Ready to Deploy!** 

Once all items are checked, your application is ready for production deployment on AWS EC2.
