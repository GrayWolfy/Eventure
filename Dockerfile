FROM unit:1.30.0-php8.2

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    libpq-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd

# Install Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Configure Xdebug
RUN echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Set the working directory
WORKDIR /var/www/html

# Copy Laravel application files
COPY --chown=www-data:www-data src /var/www/html

# Install Laravel dependencies
RUN composer install

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Set permissions for NGINX Unit directories
RUN chown -R www-data:www-data /var/lib/unit && chmod -R 755 /var/run

# Copy NGINX Unit configuration
COPY config/unit/unit.json /docker-entrypoint.d/

# Create a new user named 'appuser'
RUN adduser --disabled-password --gecos '' --uid 1000 appuser

# Switch to 'appuser'
USER appuser

# Expose port 8000 for the app
EXPOSE 8000
