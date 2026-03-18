# PHP Login System

A simple login system with a modern design and professional file structure.

## 📁 Project Structure

```
/phpLogin
├── /assets
│   ├── /css
│   │   └── style.css          # All styles
│   ├── /js                     # JavaScript files
│   └── /images                 # Image assets
├── /config
│   ├── database.php            # Database connection (Docker + XAMPP)
│   └── setup.sql               # Database setup script
├── /includes                   # Reusable PHP components
├── index.php                   # Login page
├── login.php                   # Login handler
├── logout.php                  # Logout handler
├── welcome.php                 # Welcome/Dashboard page
├── setup.php                   # Database setup tool
├── Dockerfile                  # Docker container definition
├── docker-compose.yml          # Multi-container Docker setup
├── Jenkinsfile                 # CI/CD pipeline configuration
├── .dockerignore               # Docker ignore file
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore file
├── deploy.sh                   # EC2 deployment script
├── backup.sh                   # Database backup script
├── DOCKER.md                   # Docker documentation
├── EC2-DEPLOYMENT.md           # AWS EC2 deployment guide
└── README.md                   # This file
```

## 🚀 Setup Instructions

### Option 1: Local XAMPP Setup

1. **Start XAMPP**
   - Start Apache and MySQL

2. **Run Setup Script**
   - Open http://localhost/phpLogin/setup.php in your browser
   - This will automatically create the database and users table
   - Click "Go to Login Page" when done

   **OR manually import:**
   - Open phpMyAdmin (http://localhost/phpmyadmin)
   - Import the `config/setup.sql` file

3. **Test Login**
   - Open http://localhost/phpLogin
   - Use test credentials:
     - Username: `admin` Password: `123456`
     - Username: `user1` Password: `123456`
     - Username: `demo` Password: `123456`

## 📝 Files

- **index.php** - Login page with modern UI
- **login.php** - Processes login authentication
- **welcome.php** - Welcome page shown after successful login
- **logout.php** - Logs out and destroys session
- **config/database.php** - Database connection (supports Docker and XAMPP)
- **assets/css/style.css** - All styling
- **setup.php** - Automated database setup tool

### Option 2: Docker Setup

Run with Docker (recommended for production):

```bash
# Start all services
docker-compose up -d

# Access application at http://localhost:8080
# Access phpMyAdmin at http://localhost:8081
```

📖 See [DOCKER.md](DOCKER.md) for complete Docker and Jenkins CI/CD documentation.

### Option 3: AWS EC2 Deployment

Deploy to AWS EC2 instance:

```bash
# 1. Launch EC2 instance (Amazon Linux 2 or Ubuntu)
# 2. Configure Security Group (ports 22, 8080, 8081)
# 3. SSH into instance
# 4. Run deployment script:

chmod +x deploy.sh
./deploy.sh
```

🚀 See [EC2-DEPLOYMENT.md](EC2-DEPLOYMENT.md) for complete AWS deployment guide with:
- Step-by-step EC2 setup
- Security configuration
- SSL/HTTPS setup
- Automated backups
- Production best practices

## 🔧 Technologies

- **Backend**: PHP 8.2
- **Database**: MySQL 8.0
- **Frontend**: HTML5, CSS3, JavaScript
- **Containerization**: Docker, Docker Compose
- **CI/CD**: Jenkins Pipeline

## 📚 Documentation

- **[DOCKER.md](DOCKER.md)** - Docker setup and commands
- **[EC2-DEPLOYMENT.md](EC2-DEPLOYMENT.md)** - AWS EC2 deployment guide
- **[JENKINS-SETUP.md](JENKINS-SETUP.md)** - Jenkins CI/CD configuration
- **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** - Pre-deployment checklist
