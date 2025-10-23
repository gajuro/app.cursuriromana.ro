# ============================================
# Stage 1: Base OS Setup
# ============================================
FROM php:8.2-apache AS os

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

# Install and configure APCu
RUN pecl install apcu && docker-php-ext-enable apcu

# Configure Apache
RUN a2enmod rewrite expires headers

# Set recommended PHP.ini settings for Moodle
RUN { \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'memory_limit = 256M'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'max_input_vars = 5000'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.max_accelerated_files = 10000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'opcache.use_cwd = 1'; \
    echo 'opcache.validate_timestamps = 1'; \
    echo 'opcache.save_comments = 1'; \
    echo 'opcache.enable_file_override = 0'; \
} > /usr/local/etc/php/conf.d/moodle.ini

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

# Configure Apache DocumentRoot to point to public directory (Moodle 4.5+ structure)
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|<Directory /var/www/html>|<Directory /var/www/html/public>|g' /etc/apache2/apache2.conf \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configure Apache for Moodle 4.5+ with Routing Engine
RUN { \
    echo '<Directory /var/www/html/public>'; \
    echo '    Options Indexes FollowSymLinks'; \
    echo '    AllowOverride None'; \
    echo '    Require all granted'; \
    echo '    DirectoryIndex index.php index.html'; \
    echo ''; \
    echo '    RewriteEngine On'; \
    echo ''; \
    echo '    # Strip /public/ prefix if present (legacy URLs)'; \
    echo '    RewriteCond %{REQUEST_URI} ^/public/(.*)$'; \
    echo '    RewriteRule ^public/(.*)$ /$1 [R=301,L]'; \
    echo ''; \
    echo '    # Only route to r.php if file/directory does not exist'; \
    echo '    RewriteCond %{REQUEST_FILENAME} !-f'; \
    echo '    RewriteCond %{REQUEST_FILENAME} !-d'; \
    echo '    RewriteRule ^ /r.php [L]'; \
    echo '</Directory>'; \
} >> /etc/apache2/apache2.conf

# Expose port
EXPOSE 80

# Health check - check install.php since index.php redirects when no config
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/install.php || curl -f http://localhost/ || exit 1

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
