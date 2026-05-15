#!/usr/bin/env sh
set -e

cd /var/www/html

# Wait for the database to accept TCP connections before running migrations.
if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
  echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
  i=0
  until php -r '
    $h = getenv("DB_HOST");
    $p = (int) getenv("DB_PORT");
    $s = @fsockopen($h, $p, $errno, $errstr, 2);
    if ($s) {
      fclose($s);
      exit(0);
    }
    exit(1);
  '; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
      echo "Database is not reachable after 60 seconds."
      exit 1
    fi
    sleep 2
  done
fi

php bin/console cache:clear --env=${APP_ENV:-prod} --no-debug
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

exec "$@"
