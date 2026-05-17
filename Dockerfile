FROM php:8.2-fpm

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    unzip \
    zip \
    libicu-dev \
    libzip-dev \
    zlib1g-dev \
    libonig-dev \
    nginx \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install intl pdo pdo_mysql zip opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

ENV COMPOSER_ALLOW_SUPERUSER=1

COPY . .

RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

EXPOSE 80

CMD ["php-fpm"]