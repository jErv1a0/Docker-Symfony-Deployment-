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

# Copy dependency manifests first to leverage Docker layer cache.
COPY composer.json composer.lock symfony.lock* ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader --no-scripts

# Copy the full project.
COPY . .

# Ensure runtime folders are writable by php-fpm user.
RUN mkdir -p var/cache var/log var/share \
 && chown -R www-data:www-data var \
 && chmod +x entrypoint.sh

ENV APP_ENV=prod
ENV APP_DEBUG=0

# Build-time safeguard: if vendor is missing for some reason, install dependencies now
RUN if [ ! -f vendor/autoload.php ]; then \
        composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader --no-scripts; \
    fi

ENTRYPOINT ["/var/www/html/entrypoint.sh"]
CMD ["php-fpm"]
