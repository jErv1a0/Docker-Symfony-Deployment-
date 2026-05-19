Railway Deployment Guide
=======================

This project is ready to deploy to Railway using the root `Dockerfile`.

Quick steps
-----------

1. Push this repository to GitHub (already done).
2. On Railway, create a new project and choose "Deploy from GitHub".
3. Select this repository. Railway will build using the top-level `Dockerfile`.
4. In the deployed service, add the environment variables listed below.

Required environment variables
------------------------------

- `APP_ENV=prod`
- `APP_DEBUG=0`
- `APP_SECRET` — a long random value (generate with `openssl rand -base64 32`).
- `DATABASE_URL` — Railway MySQL example:

  mysql://<user>:<password>@<host>:<port>/<database>?serverVersion=8.0.32&charset=utf8mb4

Notes about ports
------------------

- Railway sets the `PORT` environment variable for the running container. The project's `entrypoint.sh` and `nginx.conf` already use `PORT` and `envsubst` so Nginx will bind to the correct port automatically.

Database
--------

- Use Railway's MySQL service (or an external MySQL) and copy the connection values into `DATABASE_URL` above. If the password contains special characters, URL-encode it.
- Do NOT commit secrets to the repo — set them in Railway Variables.

Migrations and startup
----------------------

- The project's `entrypoint.sh` runs Doctrine migrations and cache warmup in the background at container start. That minimizes manual steps, but you may prefer to run migrations from Railway console for visibility.

Troubleshooting
---------------

- If the deploy fails with "Dockerfile not found", ensure `Dockerfile` is in the repository root and not excluded by `.dockerignore`.
- If the app fails to connect to the database, verify the Railway-provided MySQL host/port and make sure `DATABASE_URL` is set correctly.

Useful Railway settings
----------------------

- Set the service to use the repository's Dockerfile (default for Docker deployments).
- Add health checks if Railway supports them for the app (HTTP on `/` or `/health`).

Example commit and deploy flow
------------------------------

1. Commit and push changes:

   git add .
   git commit -m "Add Railway deployment guide"
   git push origin main

2. On Railway choose the repository and deploy.

Contact
-------

If you want, I can also create a `railway.json` or workflow to automate Railway deployments, or help set the required variables in your Railway project if you grant access.
