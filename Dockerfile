FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    gettext-base \
    git \
    unzip \
    zip \
    curl \
    libicu-dev \
    libzip-dev \
    zlib1g-dev \
    libonig-dev \
    && docker-php-ext-install \
        intl \
        pdo \
        pdo_mysql \
        zip \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files first (better Docker cache)
COPY composer.json composer.lock ./

# Symfony env vars
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APP_ENV=prod
ENV APP_DEBUG=0

# Install dependencies WITHOUT scripts
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress \
    --no-scripts

# Copy application files
COPY . .

# Ensure .env exists (important for Symfony)
RUN if [ ! -f .env ]; then \
      echo "APP_ENV=prod" > .env && \
      echo "APP_DEBUG=0" >> .env; \
    fi

# Configure PHP-FPM to listen on TCP
RUN sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|^;listen.allowed_clients = .*|listen.allowed_clients = 127.0.0.1|' /usr/local/etc/php-fpm.d/www.conf

# Remove default nginx config
RUN rm -f /etc/nginx/sites-enabled/default \
    /etc/nginx/conf.d/default.conf || true

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Fix permissions
RUN mkdir -p var/cache var/log public \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 var

# Fix entrypoint line endings and permissions
RUN sed -i 's/\r$//' /var/www/html/entrypoint.sh \
    && chmod +x /var/www/html/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/var/www/html/entrypoint.sh"]
