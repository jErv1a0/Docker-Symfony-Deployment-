#!/bin/sh
set -e

cd /var/www/html

export PORT="${PORT:-80}"
export APP_ENV="${APP_ENV:-prod}"
export APP_DEBUG="${APP_DEBUG:-0}"
export DEFAULT_URI="${DEFAULT_URI:-http://localhost}"

echo "Starting container..."

# Ensure .env exists for Symfony
if [ ! -f .env ]; then
  echo "Creating fallback .env file..."
  cat > .env <<EOF
APP_ENV=$APP_ENV
APP_DEBUG=$APP_DEBUG
DEFAULT_URI=$DEFAULT_URI
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

# Run migrations in foreground with retries so app doesn't serve 500 before schema is ready
echo "Running Doctrine migrations..."

MAX_RETRIES=60
COUNT=0
MIGRATED=0

while [ "$COUNT" -lt "$MAX_RETRIES" ]; do
  if php bin/console doctrine:migrations:sync-metadata-storage --no-interaction >/dev/null 2>&1; then
    :
  fi

  if php bin/console doctrine:migrations:migrate \
    --no-interaction \
    --allow-no-migration; then
    MIGRATED=1
    echo "Migrations completed."
    break
  fi

  COUNT=$((COUNT+1))
  echo "Database unavailable or migration failed ($COUNT/$MAX_RETRIES)..."
  sleep 2
done

if [ "$MIGRATED" -ne 1 ]; then
  echo "ERROR: Could not apply migrations after $MAX_RETRIES retries. Exiting to avoid serving broken app."
  exit 1
fi

# Start nginx
echo "Starting Nginx..."
exec nginx -g 'daemon off;'
