FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    nginx \
    gettext-base \
    git \
    unzip \
    zip \
    libicu-dev \
    libzip-dev \
    zlib1g-dev \
    libonig-dev \
    && docker-php-ext-install intl pdo pdo_mysql zip opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN composer install --no-dev --optimize-autoloader

RUN sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|^;listen.allowed_clients = .*|listen.allowed_clients = 127.0.0.1|' /usr/local/etc/php-fpm.d/www.conf

# Permissions
RUN chown -R www-data:www-data /var/www/html
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf
RUN sed -i 's/\r$//' /var/www/html/entrypoint.sh && chmod +x /var/www/html/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/var/www/html/entrypoint.sh"]