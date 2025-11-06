#!/bin/bash

# FS PBX Docker Quick Start Script
# This script helps you quickly deploy FS PBX using Docker

set -e

echo "=========================================="
echo "FS PBX Docker Deployment Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker is installed"

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi
print_success "Docker Compose is installed"

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from .env.example..."
    cp .env.example .env
    print_success ".env file created"
    
    print_warning "Please edit .env file and set your passwords!"
    echo ""
    echo "Required changes in .env:"
    echo "  - DB_PASSWORD=your_secure_password"
    echo "  - FS_ESL_PW=your_secure_password"
    echo "  - APP_URL=http://your-server-ip"
    echo ""
    read -p "Press Enter to continue after editing .env file..."
fi

# Generate APP_KEY if not set
if ! grep -q "APP_KEY=base64:" .env; then
    print_info "Generating application key..."
    
    # Try to use local PHP if available
    if command -v php &> /dev/null && [ -f artisan ]; then
        php artisan key:generate
        print_success "Application key generated"
    else
        print_warning "PHP not found locally. Will generate key using Docker..."
        docker run --rm -v $(pwd):/app -w /app php:8.1-cli php artisan key:generate
        print_success "Application key generated using Docker"
    fi
else
    print_success "Application key already set"
fi

# Create necessary directories
print_info "Creating necessary directories..."
mkdir -p storage/app/public
mkdir -p storage/framework/{cache,sessions,views}
mkdir -p storage/logs
mkdir -p bootstrap/cache
print_success "Directories created"

# Build Docker images
print_info "Building Docker images (this may take a few minutes)..."
docker compose build
print_success "Docker images built successfully"

# Start containers
print_info "Starting Docker containers..."
docker compose up -d
print_success "Containers started"

# Wait for PostgreSQL to be ready
print_info "Waiting for PostgreSQL to be ready..."
sleep 10

# Check if containers are running
if docker compose ps | grep -q "Up"; then
    print_success "All containers are running"
else
    print_error "Some containers failed to start. Check logs with: docker compose logs"
    exit 1
fi

# Run database migrations
print_info "Running database migrations..."
docker compose exec -T app php artisan migrate --force
print_success "Database migrations completed"

# Set proper permissions
print_info "Setting proper permissions..."
docker compose exec -T app chown -R www-data:www-data /var/www/fspbx/storage /var/www/fspbx/bootstrap/cache
docker compose exec -T app chmod -R 775 /var/www/fspbx/storage /var/www/fspbx/bootstrap/cache
print_success "Permissions set"

# Optimize application
print_info "Optimizing application..."
docker compose exec -T app php artisan config:cache
docker compose exec -T app php artisan route:cache
docker compose exec -T app php artisan view:cache
print_success "Application optimized"

echo ""
echo "=========================================="
print_success "FS PBX is now running!"
echo "=========================================="
echo ""
echo "Access your application at:"
echo "  → http://localhost"
echo "  → http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Useful commands:"
echo "  View logs:       docker compose logs -f"
echo "  Stop services:   docker compose down"
echo "  Restart:         docker compose restart"
echo "  Shell access:    docker compose exec app bash"
echo ""
print_warning "For production deployment, please:"
echo "  1. Configure SSL/HTTPS"
echo "  2. Update APP_URL in .env to your domain"
echo "  3. Set APP_DEBUG=false in .env"
echo "  4. Configure firewall rules"
echo ""
echo "Read DOCKER_DEPLOYMENT.md for detailed instructions."
echo ""
