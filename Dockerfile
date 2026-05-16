FROM php:8.3-fpm-alpine

WORKDIR /var/www/html

# Install system packages and required PHP extensions for Symfony + MySQL.
RUN apk add --no-cache \
    bash \
    git \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    unzip \
 && docker-php-ext-install -j"$(nproc)" intl pdo pdo_mysql opcache

# Install Composer from the official image.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV APP_ENV=prod
ENV APP_DEBUG=0

# Copy dependency manifests first to leverage Docker layer cache.
COPY composer.json composer.lock symfony.lock* ./

# Copy the full project before Composer runs so Symfony auto-scripts can use bin/console.
COPY . .

RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

# Ensure runtime folders are writable by php-fpm user.
RUN mkdir -p var/cache var/log var/share \
 && chown -R www-data:www-data var \
 && chmod +x entrypoint.sh

ENTRYPOINT ["/var/www/html/entrypoint.sh"]
CMD ["php-fpm"]
