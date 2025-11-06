# FS PBX Docker Setup - Quick Reference

## What Was Created

I've set up a complete Docker environment for FS PBX with the following files:

1. **Dockerfile** - Application container definition
2. **docker-compose.yml** - Multi-container orchestration
3. **docker/nginx.conf** - Nginx web server configuration
4. **docker/supervisord.conf** - Process supervisor configuration
5. **.dockerignore** - Files to exclude from Docker build
6. **docker-deploy.sh** - Automated deployment script
7. **Makefile** - Common commands shortcuts
8. **DOCKER_DEPLOYMENT.md** - Comprehensive deployment guide
9. **.env** - Updated for Docker (DB host changed to 'postgres', Redis to 'redis')

## Quick Start (3 Steps)

### Step 1: Edit Configuration

```bash
nano .env
```

**Change these critical values:**

- `DB_PASSWORD=fusionpbx_secure_password_change_me` → Use your own secure password
- `FS_ESL_PW=ClueCon_change_me` → Use your own secure password
- `APP_URL=http://localhost` → Change to your server IP or domain

### Step 2: Run Deployment Script

```bash
./docker-deploy.sh
```

This script will:

- Check Docker installation
- Generate application key
- Build Docker images
- Start all containers (PostgreSQL, Redis, FreeSWITCH, Laravel App)
- Run database migrations
- Set proper permissions
- Optimize the application

### Step 3: Access Your PBX

Open browser: **<http://your-server-ip>** or **<http://localhost>**

## Container Architecture

The setup includes 5 containers:

1. **postgres** - PostgreSQL 17 database
2. **redis** - Redis cache server
3. **freeswitch** - FreeSWITCH telephony engine
4. **app** - Laravel + Nginx (web interface)
5. **queue** - Laravel queue worker

## Common Commands

### Using Makefile (Easiest)

```bash
make help           # Show all available commands
make up             # Start containers
make down           # Stop containers
make logs           # View logs
make shell          # Access app shell
make migrate        # Run migrations
make optimize       # Optimize application
make backup-db      # Backup database
```

### Using Docker Compose Directly

```bash
docker compose up -d              # Start containers
docker compose down               # Stop containers
docker compose logs -f            # View logs
docker compose ps                 # Check status
docker compose restart            # Restart all
docker compose exec app bash     # Access shell
```

### Artisan Commands

```bash
docker compose exec app php artisan migrate
docker compose exec app php artisan cache:clear
docker compose exec app php artisan config:cache
docker compose exec app php artisan queue:work
```

## Production Deployment Checklist

- [ ] Change `DB_PASSWORD` in .env
- [ ] Change `FS_ESL_PW` in .env
- [ ] Set `APP_URL` to your domain
- [ ] Set `APP_ENV=production`
- [ ] Set `APP_DEBUG=false`
- [ ] Configure SSL/HTTPS (use reverse proxy)
- [ ] Update `SESSION_DOMAIN` to your domain
- [ ] Configure firewall (allow ports 80, 443, 5060-5061, 16384-32768)
- [ ] Set up automated backups
- [ ] Configure email settings (MAIL_* variables)

## Ports Exposed

- **80** - HTTP (web interface)
- **443** - HTTPS (when configured)
- **5432** - PostgreSQL
- **6379** - Redis
- **5060** - SIP (FreeSWITCH)
- **5080** - SIP TLS (FreeSWITCH)
- **8021** - FreeSWITCH ESL
- **16384-32768** - RTP media (FreeSWITCH uses host network)

## Troubleshooting

### Containers won't start

```bash
docker compose logs
```

### Database connection failed

```bash
docker compose exec postgres psql -U fusionpbx -d fusionpbx
```

### Permission errors

```bash
make permissions
# or
docker compose exec app chown -R www-data:www-data /var/www/fspbx/storage
```

### Clear all caches

```bash
make clear-cache
```

### Error 419 (Page Expired)

1. Check `SESSION_DOMAIN` matches your domain
2. Clear browser cookies
3. Run: `docker compose exec app php artisan cache:clear`

## Backup & Restore

### Backup Database

```bash
make backup-db
# or
docker compose exec postgres pg_dump -U fusionpbx fusionpbx > backup.sql
```

### Restore Database

```bash
docker compose exec -T postgres psql -U fusionpbx fusionpbx < backup.sql
```

### Backup Everything

```bash
# Database
make backup-db

# Application files
tar czf fspbx-backup-$(date +%Y%m%d).tar.gz storage .env

# Docker volumes
docker run --rm -v fspbx_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/volumes-backup.tar.gz /data
```

## Updates

```bash
make update
# or manually:
git pull origin main
docker compose build
docker compose down
docker compose up -d
docker compose exec app php artisan migrate --force
docker compose exec app php artisan optimize
```

## Next Steps

1. **Read DOCKER_DEPLOYMENT.md** for detailed production deployment guide
2. **Configure SSL** using Let's Encrypt or reverse proxy
3. **Set up monitoring** for containers and services
4. **Configure backups** - automate database and file backups
5. **Customize FreeSWITCH** - configure SIP trunks and extensions

## Support

- **Documentation**: See DOCKER_DEPLOYMENT.md
- **Issues**: <https://github.com/nemerald-voip/fspbx/issues>
- **Original Project**: <https://github.com/nemerald-voip/fspbx>
