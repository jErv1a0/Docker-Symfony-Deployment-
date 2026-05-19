#!/usr/bin/env sh
set -e

cd /var/www/html

export PORT="${PORT:-80}"
export APP_ENV="${APP_ENV:-prod}"
export APP_DEBUG="${APP_DEBUG:-0}"

echo "Starting container..."

# Ensure .env exists for Symfony
if [ ! -f .env ]; then
  echo "Creating fallback .env file..."
  cat > .env <<EOF
APP_ENV=$APP_ENV
APP_DEBUG=$APP_DEBUG
EOF
fi

# Configure nginx
cp /var/www/html/nginx-main.conf /etc/nginx/nginx.conf

rm -f \
  /etc/nginx/sites-enabled/default \
  /etc/nginx/sites-available/default \
  /etc/nginx/conf.d/default.conf

envsubst '$PORT' < /var/www/html/nginx.conf > /etc/nginx/conf.d/default.conf

# Ensure required Symfony directories exist
mkdir -p var/cache var/log var/sessions
chown -R www-data:www-data var

# Install dependencies only if missing
if [ ! -f vendor/autoload.php ]; then
  echo "vendor/autoload.php missing — running composer install..."

  if command -v composer >/dev/null 2>&1; then
    composer install \
      --no-dev \
      --prefer-dist \
      --no-interaction \
      --no-progress \
      --optimize-autoloader \
      --no-scripts
  else
    echo "ERROR: composer not available."
    exit 1
  fi
fi

# Start PHP-FPM
echo "Starting PHP-FPM..."
php-fpm -D

# Warm Symfony cache
echo "Clearing and warming Symfony cache..."

php bin/console cache:clear \
  --env=$APP_ENV \
  --no-debug || true

php bin/console cache:warmup \
  --env=$APP_ENV \
  --no-debug || true

# Run migrations in background with retries
echo "Running Doctrine migrations..."

(
  MAX_RETRIES=60
  COUNT=0

  while true; do
    if php bin/console doctrine:migrations:migrate \
      --no-interaction \
      --allow-no-migration; then

      echo "Migrations completed."
      break
    fi

    COUNT=$((COUNT+1))

    echo "Database unavailable or migration failed ($COUNT/$MAX_RETRIES)..."

    if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
      echo "Migration retries exceeded. Continuing startup."
      break
    fi

    sleep 2
  done
) &

# Start nginx
echo "Starting Nginx..."
exec nginx -g 'daemon off;'
