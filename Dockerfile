FROM php:8.1-fpm

ARG FUSIONPBX_VERSION=latest

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
    supervisor \
    nginx

# Install Node.js (LTS) for asset builds
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@10 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd zip

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . /var/www/fspbx

# Pull in FusionPBX public assets that legacy includes expect
RUN set -euo pipefail \
    && rm -rf /var/www/fspbx/public \
    && mkdir -p /var/www/fspbx/public \
    && RELEASE_URL="" \
    && if [ "$FUSIONPBX_VERSION" = "latest" ]; then \
        FUSIONPBX_VERSION=$(curl -sS https://api.github.com/repos/nemerald-voip/fusionpbx/releases/latest | grep '"tag_name"' | head -n1 | cut -d '"' -f4 || true); \
    fi \
    && if [ -n "$FUSIONPBX_VERSION" ]; then \
        RELEASE_URL="https://github.com/nemerald-voip/fusionpbx/archive/refs/tags/${FUSIONPBX_VERSION}.tar.gz"; \
    else \
        RELEASE_URL="https://github.com/nemerald-voip/fusionpbx/archive/refs/heads/master.tar.gz"; \
    fi \
    && curl -fSL "$RELEASE_URL" -o /tmp/fusionpbx.tar.gz \
    && tar -xzf /tmp/fusionpbx.tar.gz -C /var/www/fspbx/public --strip-components=1 \
    && rm /tmp/fusionpbx.tar.gz

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
