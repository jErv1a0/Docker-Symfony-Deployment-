<?php

use Symfony\Component\Dotenv\Dotenv;

require dirname(__DIR__).'/vendor/autoload.php';

// Prefer real environment variables first (Railway, Docker, shell).
foreach (array_keys($_ENV + $_SERVER) as $key) {
    if (array_key_exists($key, $_ENV)) {
        $_SERVER[$key] = $_ENV[$key];
    }
}

$getEnv = static function (array $names, ?string $default = null): ?string {
    foreach ($names as $name) {
        $value = $_SERVER[$name] ?? $_ENV[$name] ?? getenv($name);
        if (false !== $value && null !== $value && '' !== $value) {
            return (string) $value;
        }
    }

    return $default;
};

$databaseUrl = $getEnv(['DATABASE_URL']);
$databaseUrlIsPlaceholder = null !== $databaseUrl && (str_contains($databaseUrl, '<user>') || str_contains($databaseUrl, '<password>') || str_contains($databaseUrl, '<host>') || str_contains($databaseUrl, '<port>') || str_contains($databaseUrl, '<database>'));

if (null === $databaseUrl || $databaseUrlIsPlaceholder) {
    $dbHost = $getEnv(['MYSQLHOST', 'MYSQL_HOST', 'DATABASE_HOST', 'DB_HOST']);
    $dbPort = $getEnv(['MYSQLPORT', 'MYSQL_PORT', 'DATABASE_PORT', 'DB_PORT'], '3306');
    $dbUser = $getEnv(['MYSQLUSER', 'MYSQL_USER', 'DATABASE_USER', 'DB_USER']);
    $dbPassword = $getEnv(['MYSQLPASSWORD', 'MYSQL_PASSWORD', 'DATABASE_PASSWORD', 'DB_PASSWORD'], '');
    $dbName = $getEnv(['MYSQLDATABASE', 'MYSQL_DATABASE', 'DATABASE_NAME', 'DB_NAME']);

    if (null !== $dbHost && null !== $dbUser && null !== $dbName) {
        $databaseUrl = sprintf(
            'mysql://%s:%s@%s:%s/%s?serverVersion=8.0.32&charset=utf8mb4',
            rawurlencode($dbUser),
            rawurlencode($dbPassword ?? ''),
            $dbHost,
            $dbPort,
            $dbName,
        );
        $_ENV['DATABASE_URL'] = $_SERVER['DATABASE_URL'] = $databaseUrl;
    }
}

// If DATABASE_URL uses localhost, replace with 127.0.0.1 to force TCP (avoid UNIX socket).
if (isset($databaseUrl) && str_contains((string) $databaseUrl, '@localhost')) {
    $databaseUrl = preg_replace('/@localhost(?=[:\/])/', '@127.0.0.1', $databaseUrl);
    $_ENV['DATABASE_URL'] = $_SERVER['DATABASE_URL'] = $databaseUrl;
}

// Fall back to the compiled env only when a value is not already provided.
if (is_file(dirname(__DIR__).'/.env.local.php')) {
    $compiledEnv = include dirname(__DIR__).'/.env.local.php';
    foreach ($compiledEnv as $key => $value) {
        if (false === getenv($key) && !isset($_ENV[$key]) && !isset($_SERVER[$key])) {
            if ('DATABASE_URL' === $key && null !== $databaseUrl) {
                continue;
            }
            $_ENV[$key] = $_SERVER[$key] = $value;
        }
    }
}

if (!isset($_SERVER['APP_ENV']) && !isset($_ENV['APP_ENV']) && class_exists(Dotenv::class)) {
    $envFile = dirname(__DIR__).'/.env';
    if (is_file($envFile)) {
        (new Dotenv())->bootEnv($envFile);
    }
}

$_SERVER['APP_ENV'] = $_SERVER['APP_ENV'] ?? $_ENV['APP_ENV'] ?? 'dev';
$_SERVER['APP_DEBUG'] = $_SERVER['APP_DEBUG'] ?? $_ENV['APP_DEBUG'] ?? '1';
