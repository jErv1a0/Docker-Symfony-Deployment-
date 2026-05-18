#!/usr/bin/env sh
set -e

cd /var/www/html

export PORT="${PORT:-80}"

envsubst '$PORT' < /var/www/html/nginx.conf > /etc/nginx/conf.d/default.conf

# Start PHP-FPM immediately so the container can answer requests even if
# cache warmup or migrations fail because the database is slow or misconfigured.
php-fpm -D

(
  echo "Running Symfony cache warmup..."
  php bin/console cache:clear --env=${APP_ENV:-prod} --no-debug || true

  echo "Running Doctrine migrations..."
  php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration || true
) &

# If dependencies are missing (e.g. built image lost vendor), install them so bin/console works.
if [ ! -f vendor/autoload.php ]; then
  echo "vendor/autoload.php missing — running composer install..."
  if command -v composer >/dev/null 2>&1; then
    composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader
  else
    echo "composer not available; cannot install dependencies."
  fi
fi
exec nginx -g 'daemon off;'
