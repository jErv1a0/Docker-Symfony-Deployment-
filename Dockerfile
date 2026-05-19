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

# add composer binary from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# copy project files
COPY . .

# Ensure composer can run as root inside container
ENV COMPOSER_ALLOW_SUPERUSER=1
# Runtime environment defaults (can be overridden by Railway env vars)
ENV APP_ENV=prod
ENV APP_DEBUG=0

# Install PHP dependencies at build time but DO NOT run scripts (they require runtime env)
# --no-scripts prevents Symfony post-install hooks like cache:clear from running during build
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

# Configure php-fpm to listen on TCP so it doesn't try a unix socket
RUN sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf \
  && sed -i 's|^;listen.allowed_clients = .*|listen.allowed_clients = 127.0.0.1|' /usr/local/etc/php-fpm.d/www.conf

# Ensure permissions, nginx config, and entrypoint script are ready
RUN chown -R www-data:www-data /var/www/html
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf || true
RUN [ -f /var/www/html/nginx.conf ] && cp /var/www/html/nginx.conf /etc/nginx/conf.d/default.conf || true
RUN sed -i 's/\r$//' /var/www/html/entrypoint.sh && chmod +x /var/www/html/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/var/www/html/entrypoint.sh"]
