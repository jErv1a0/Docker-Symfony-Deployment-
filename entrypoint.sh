#!/usr/bin/env sh
set -e

cd /var/www/html

export PORT="${PORT:-80}"
 

cp /var/www/html/nginx-main.conf /etc/nginx/nginx.conf
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default /etc/nginx/conf.d/default.conf
envsubst '$PORT' < /var/www/html/nginx.conf > /etc/nginx/conf.d/default.conf

## If dependencies are missing (e.g. built image lost vendor), install them so bin/console works.
if [ ! -f vendor/autoload.php ]; then
  echo "vendor/autoload.php missing — running composer install..."
  if command -v composer >/dev/null 2>&1; then
    composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader
  else
    echo "composer not available; cannot install dependencies."
  fi
fi

# Start PHP-FPM so the container can answer requests while we warm cache and run migrations.
php-fpm -D

echo "Running Symfony cache warmup..."
php bin/console cache:clear --env=${APP_ENV:-prod} --no-debug || true

echo "Running Doctrine migrations (will retry until DB is available)..."
# Run migrations in background, retrying until success or timeout.
(
  MAX_RETRIES=60
  COUNT=0
  while true; do
    if php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration; then
      echo "Migrations completed."
      break
    fi
    COUNT=$((COUNT+1))
    echo "Migrations failed or DB unavailable - retry $COUNT/$MAX_RETRIES..."
    if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
      echo "Migrations failed after $MAX_RETRIES attempts, continuing startup without completing migrations."
      break
    fi
    sleep 2
  done
) &

exec nginx -g 'daemon off;'
