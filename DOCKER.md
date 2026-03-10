# PHP Login System - Docker & CI/CD

## 🐳 Docker Setup

### Quick Start with Docker Compose

```bash
# Start all services (Web, MySQL, phpMyAdmin)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

**Access Points:**
- **Application**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081
- **MySQL**: localhost:3307

### Manual Docker Build

```bash
# Build image
docker build -t phplogin:latest .

# Run container
docker run -d -p 8080:80 phplogin:latest
```

## 🔧 Jenkins CI/CD Pipeline

### Prerequisites
- Jenkins installed with Docker plugin
- Docker installed on Jenkins agent
- Docker credentials configured in Jenkins

### Pipeline Stages

1. **Checkout** - Clone repository
2. **Build** - Build Docker image
3. **Test** - Run automated tests
4. **Security Scan** - Vulnerability scanning
5. **Push** - Push to Docker registry
6. **Deploy** - Deploy to production

### Setup Instructions

1. Create new Pipeline job in Jenkins
2. Point to your repository
3. Jenkins will automatically detect the `Jenkinsfile`
4. Configure credentials for Docker registry
5. Run the pipeline

### Environment Variables

Update these in `docker-compose.yml`:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`

## 📝 Docker Commands

```bash
# Build and start
docker-compose up --build -d

# View running containers
docker-compose ps

# Access web container shell
docker exec -it phplogin_web bash

# Access MySQL container
docker exec -it phplogin_mysql mysql -u root -proot

# View logs
docker-compose logs web
docker-compose logs database

# Restart services
docker-compose restart

# Remove everything (including volumes)
docker-compose down -v
```

## 🔍 Troubleshooting

### Database connection issues
- Ensure MySQL container is healthy: `docker-compose ps`
- Check logs: `docker-compose logs database`
- Wait for MySQL initialization (first run takes longer)

### Port conflicts
- Change ports in `docker-compose.yml` if 8080, 8081, or 3307 are in use

### Permission issues
- Ensure proper file permissions: `chmod -R 755 /var/www/html`

## 🚀 Production Deployment

1. Update `Jenkinsfile` with your registry URL
2. Set up Docker registry credentials
3. Configure deployment target
4. Push to `main` branch to trigger deployment

## 📊 Monitoring

Access container stats:
```bash
docker stats
```

View resource usage:
```bash
docker-compose top
```
