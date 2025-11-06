# FS PBX Docker Deployment Guide

This guide will help you deploy FS PBX using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10+ installed
- Docker Compose v2.0+ installed
- At least 4GB RAM
- 30GB disk space

## Quick Start

### 1. Configure Environment Variables

Edit the `.env` file and update the following important variables:

```bash
# Change these security-critical values!
DB_PASSWORD=your_secure_database_password
FS_ESL_PW=your_secure_freeswitch_password

# Update with your domain or server IP
APP_URL=http://your-server-ip-or-domain

# For production, keep these as:
APP_ENV=production
APP_DEBUG=false
```

### 2. Generate Application Key

Before starting Docker, generate a Laravel application key:

```bash
# If you have PHP installed locally
php artisan key:generate

# OR use a temporary PHP container
docker run --rm -v $(pwd):/app -w /app composer/composer:latest-bin composer install --no-dev --optimize-autoloader
docker run --rm -v $(pwd):/app -w /app php:8.1-cli php artisan key:generate
```

### 3. Build and Start Containers

```bash
# Build the Docker images
docker-compose build

# Start all services
docker-compose up -d
```

### 4. Initialize the Application

```bash
# Wait for PostgreSQL to be ready (check with)
docker-compose logs postgres

# Run database migrations
docker-compose exec app php artisan migrate

# Optional: Seed the database with initial data
docker-compose exec app php artisan db:seed

# Set proper permissions
docker-compose exec app chown -R www-data:www-data /var/www/fspbx/storage /var/www/fspbx/bootstrap/cache
docker-compose exec app chmod -R 775 /var/www/fspbx/storage /var/www/fspbx/bootstrap/cache
```

### 5. Access the Application

Open your browser and navigate to:

- **HTTP**: `http://your-server-ip` or `http://localhost` (if running locally)
- **HTTPS**: Configure SSL certificate (see SSL section below)

## Container Management

### View Running Containers

```bash
docker-compose ps
```

### View Logs

```bash
# All containers
docker-compose logs -f

# Specific container
docker-compose logs -f app
docker-compose logs -f postgres
docker-compose logs -f freeswitch
docker-compose logs -f redis
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart app
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: This will delete all data!)
docker-compose down -v
```

### Execute Commands in Containers

```bash
# Access app container shell
docker-compose exec app bash

# Run artisan commands
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:list

# Access PostgreSQL
docker-compose exec postgres psql -U fusionpbx -d fusionpbx
```

## Production Deployment

### 1. Use Production-Ready Configuration

Update `.env`:

```bash
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=error
```

### 2. Configure SSL/HTTPS

#### Option A: Using Let's Encrypt with Nginx Proxy

1. Install certbot in the app container or use a reverse proxy like Traefik or Nginx Proxy Manager

2. Update `docker-compose.yml` to add SSL ports and certificate volumes

#### Option B: Using Reverse Proxy (Recommended)

Use a reverse proxy like Nginx, Traefik, or Caddy in front of the application.

Example Nginx reverse proxy configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Configure Session Domain

Update in `.env`:

```bash
SESSION_DOMAIN=your-domain.com
SANCTUM_STATEFUL_DOMAINS=your-domain.com
APP_URL=https://your-domain.com
```

### 4. Optimize Application

```bash
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
docker-compose exec app php artisan optimize
```

## Backup and Restore

### Backup Database

```bash
# Create backup
docker-compose exec postgres pg_dump -U fusionpbx fusionpbx > backup-$(date +%Y%m%d).sql

# Or using docker volumes
docker run --rm -v fspbx_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore Database

```bash
# Restore from SQL dump
docker-compose exec -T postgres psql -U fusionpbx fusionpbx < backup-20250105.sql
```

### Backup Application Files

```bash
# Backup storage and configuration
tar czf fspbx-files-backup-$(date +%Y%m%d).tar.gz storage .env
```

## Updating FS PBX

```bash
# Pull latest code
git pull origin main

# Rebuild containers
docker-compose build

# Restart services
docker-compose down
docker-compose up -d

# Run migrations
docker-compose exec app php artisan migrate

# Clear and rebuild cache
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs app

# Check container status
docker-compose ps
```

### Database connection issues

```bash
# Verify PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec app php artisan tinker
>>> DB::connection()->getPdo();
```

### Permission issues

```bash
docker-compose exec app chown -R www-data:www-data /var/www/fspbx/storage
docker-compose exec app chmod -R 775 /var/www/fspbx/storage
```

### Error 419 (Page Expired)

This is usually a session/CSRF token issue. Make sure:

1. `SESSION_DOMAIN` matches your domain in `.env`
2. Clear browser cookies
3. Clear application cache: `docker-compose exec app php artisan cache:clear`

### Clear all caches

```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

## Resource Management

### Monitor Resource Usage

```bash
docker stats
```

### Scale Queue Workers

```bash
# Edit docker-compose.yml and add more queue workers, then:
docker-compose up -d --scale queue=3
```

## Security Best Practices

1. **Change default passwords** in `.env`:
   - `DB_PASSWORD`
   - `FS_ESL_PW`

2. **Use strong APP_KEY**: Generated automatically with `php artisan key:generate`

3. **Enable firewall** and only allow necessary ports:
   - 80 (HTTP)
   - 443 (HTTPS)
   - 5060-5061 (SIP)
   - 5080-5081 (SIP TLS)
   - 16384-32768 (RTP)

4. **Keep Docker images updated**:

   ```bash
   docker-compose pull
   docker-compose up -d
   ```

5. **Regular backups**: Schedule automatic backups of database and files

6. **Use SSL/TLS**: Always use HTTPS in production

## Support

For issues and questions:

- GitHub Issues: <https://github.com/nemerald-voip/fspbx/issues>
- Documentation: <https://github.com/nemerald-voip/fspbx/wiki>
