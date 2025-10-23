# ============================================
# Stage 1: Base OS Setup
# ============================================
FROM php:8.2-fpm AS os

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libpq-dev \
    libonig-dev \
    git \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    intl \
    zip \
    soap \
    opcache \
    exif \
    mbstring \
    xml

# Install and configure APCu and Redis
RUN pecl install apcu redis \
    && docker-php-ext-enable apcu redis

# Set recommended PHP.ini settings for Moodle
RUN { \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'memory_limit = 256M'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'max_input_vars = 5000'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 256'; \
    echo 'opcache.max_accelerated_files = 20000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'opcache.use_cwd = 1'; \
    echo 'opcache.validate_timestamps = 1'; \
    echo 'opcache.save_comments = 1'; \
    echo 'opcache.enable_file_override = 0'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# Configure PHP-FPM
RUN { \
    echo '[www]'; \
    echo 'user = www-data'; \
    echo 'group = www-data'; \
    echo 'listen = 0.0.0.0:9000'; \
    echo 'pm = dynamic'; \
    echo 'pm.max_children = 50'; \
    echo 'pm.start_servers = 5'; \
    echo 'pm.min_spare_servers = 5'; \
    echo 'pm.max_spare_servers = 35'; \
    echo 'pm.max_requests = 500'; \
    echo 'clear_env = no'; \
} > /usr/local/etc/php-fpm.d/www.conf

# ============================================
# Stage 2: Moodle Application
# ============================================
FROM os AS moodle

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create directories for persistent data
RUN mkdir -p /var/www/moodledata /var/www/localcache /var/www/persistent \
    && chown -R www-data:www-data /var/www/html /var/www/moodledata /var/www/localcache /var/www/persistent \
    && chmod -R 755 /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Health check for PHP-FPM - verificăm că procesul rulează
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep php-fpm > /dev/null || exit 1

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm"]
