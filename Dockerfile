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
# Ensure PHP-FPM preserves environment variables passed from Docker
RUN sed -i "s|^;*\s*clear_env\s*=.*|clear_env = no|" /usr/local/etc/php-fpm.d/www.conf || echo "clear_env = no" >> /usr/local/etc/php-fpm.d/www.conf

# Remove default nginx config
RUN rm -f /etc/nginx/sites-enabled/default \
    /etc/nginx/conf.d/default.conf || true

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Fix permissions
RUN mkdir -p var/cache var/log public \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 var

EXPOSE 80

ENTRYPOINT ["/bin/sh", "-lc", "set -e; cd /var/www/html; export PORT=\"${PORT:-80}\" APP_ENV=\"${APP_ENV:-prod}\" APP_DEBUG=\"${APP_DEBUG:-0}\" DEFAULT_URI=\"${DEFAULT_URI:-http://localhost}\"; echo 'Starting container...'; if [ ! -f .env ]; then echo 'Creating fallback .env file...'; printf 'APP_ENV=%s\nAPP_DEBUG=%s\nDEFAULT_URI=%s\n' \"$APP_ENV\" \"$APP_DEBUG\" \"$DEFAULT_URI\" > .env; fi; cp /var/www/html/nginx-main.conf /etc/nginx/nginx.conf; rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default /etc/nginx/conf.d/default.conf; envsubst '$PORT' < /var/www/html/nginx.conf > /etc/nginx/conf.d/default.conf; mkdir -p var/cache var/log var/sessions; chown -R www-data:www-data var; if [ ! -f vendor/autoload.php ]; then echo 'vendor/autoload.php missing — running composer install...'; if command -v composer >/dev/null 2>&1; then composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader --no-scripts; else echo 'ERROR: composer not available.'; exit 1; fi; fi; echo 'Starting PHP-FPM...'; php-fpm -D; echo 'Clearing and warming Symfony cache...'; php bin/console cache:clear --env=$APP_ENV --no-debug || true; php bin/console cache:warmup --env=$APP_ENV --no-debug || true; echo 'Running Doctrine migrations...'; MAX_RETRIES=60; COUNT=0; MIGRATED=0; while [ \"$COUNT\" -lt \"$MAX_RETRIES\" ]; do if php bin/console doctrine:migrations:sync-metadata-storage --no-interaction >/dev/null 2>&1; then :; fi; if php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration; then MIGRATED=1; echo 'Migrations completed.'; break; fi; COUNT=$((COUNT+1)); echo \"Database unavailable or migration failed ($COUNT/$MAX_RETRIES)...\"; sleep 2; done; if [ \"$MIGRATED\" -ne 1 ]; then echo \"ERROR: Could not apply migrations after $MAX_RETRIES retries. Exiting to avoid serving broken app.\"; exit 1; fi; echo 'Starting Nginx...'; exec nginx -g 'daemon off;'"]
