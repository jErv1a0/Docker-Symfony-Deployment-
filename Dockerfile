FROM php:8.2-apache

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    unzip \
    zip \
    libicu-dev \
    libzip-dev \
    zlib1g-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install intl pdo pdo_mysql zip opcache

# Install Composer binary from the official Composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Allow Composer plugins (symfony/flex) to run as root
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY . .

ENV COMPOSER_ALLOW_SUPERUSER=1

# Install PHP dependencies
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

# Enable Apache rewrite and force a single MPM for Apache startup
RUN a2dismod mpm_event mpm_worker || true \
    && a2enmod mpm_prefork rewrite

EXPOSE 8080

CMD ["apache2-foreground"]