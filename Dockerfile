FROM php:8.2-fpm

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    nginx \
    gettext-base \
    git \
    unzip \
    zip \
    libicu-dev \
    libzip-dev \
    zlib1g-dev \
    libonig-dev \
  && docker-php-ext-install intl pdo pdo_mysql zip opcache \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APP_ENV=prod
ENV APP_DEBUG=0

# Install PHP deps but DO NOT run composer scripts at build time
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

# Ensure php-fpm listens on TCP (avoid unix socket)
RUN sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf \
  && sed -i 's|^;listen.allowed_clients = .*|listen.allowed_clients = 127.0.0.1|' /usr/local/etc/php-fpm.d/www.conf

# Nginx config
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf || true
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Permissions + make entrypoint executable (remove Windows CRs)
RUN chown -R www-data:www-data /var/www/html
RUN sed -i 's/\r$//' /var/www/html/entrypoint.sh && chmod +x /var/www/html/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/var/www/html/entrypoint.sh"]
