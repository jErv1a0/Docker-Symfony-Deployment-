<?php

return [
    'APP_ENV' => 'prod',
    'APP_DEBUG' => '0',
    'APP_SECRET' => 'change_me_on_railway',
    'APP_SHARE_DIR' => 'var/share',
    'DEFAULT_URI' => 'http://localhost',
    'MYSQL_USER' => 'root',
    'MYSQL_PASSWORD' => '',
    'MYSQL_DATABASE' => 'fplatform',
    'MYSQL_ROOT_PASSWORD' => '',
    'DATABASE_URL' => 'mysql://root@127.0.0.1:3310/fplatform?serverVersion=8.0.32&charset=utf8mb4',
    'MESSENGER_TRANSPORT_DSN' => 'doctrine://default?auto_setup=0',
    'MAILER_DSN' => 'null://null',
];
