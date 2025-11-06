FROM php:8.1-fpm

# Set working directory
WORKDIR /var/www/fspbx

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    supervisor \
    nginx

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd zip

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . /var/www/fspbx

# Create necessary directories
RUN mkdir -p /var/www/fspbx/storage/framework/{cache,sessions,views} \
    && mkdir -p /var/www/fspbx/storage/logs \
    && mkdir -p /var/www/fspbx/bootstrap/cache

# Install composer dependencies as root first
RUN composer install --no-interaction --optimize-autoloader --no-dev --verbose || \
    composer install --no-interaction --no-dev --verbose

# Install npm dependencies and build assets as root
RUN npm install && npm run build

# Set proper permissions after installation
RUN chown -R www-data:www-data /var/www/fspbx \
    && chmod -R 755 /var/www/fspbx/storage \
    && chmod -R 755 /var/www/fspbx/bootstrap/cache

# Copy supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Expose port 9000 for PHP-FPM and 80 for nginx
EXPOSE 9000 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
