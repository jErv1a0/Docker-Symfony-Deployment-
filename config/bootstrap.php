<?php

use Symfony\Component\Dotenv\Dotenv;

require dirname(__DIR__).'/vendor/autoload.php';

// Prefer real environment variables first (Railway, Docker, shell).
foreach (array_keys($_ENV + $_SERVER) as $key) {
    if (array_key_exists($key, $_ENV)) {
        $_SERVER[$key] = $_ENV[$key];
    }
}

// Fall back to the compiled env only when a value is not already provided.
if (is_file(dirname(__DIR__).'/.env.local.php')) {
    $compiledEnv = include dirname(__DIR__).'/.env.local.php';
    foreach ($compiledEnv as $key => $value) {
        if (false === getenv($key) && !isset($_ENV[$key]) && !isset($_SERVER[$key])) {
            $_ENV[$key] = $_SERVER[$key] = $value;
        }
    }
}

if (!isset($_SERVER['APP_ENV']) && !isset($_ENV['APP_ENV']) && class_exists(Dotenv::class)) {
    (new Dotenv())->bootEnv(dirname(__DIR__).'/.env');
}

$_SERVER['APP_ENV'] = $_SERVER['APP_ENV'] ?? $_ENV['APP_ENV'] ?? 'dev';
$_SERVER['APP_DEBUG'] = $_SERVER['APP_DEBUG'] ?? $_ENV['APP_DEBUG'] ?? '1';
