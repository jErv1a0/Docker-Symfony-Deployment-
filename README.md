# Final Project Deployment Guide

## Symfony Docker Deployment (Railway & Other Hosting Platforms)

This project demonstrates how to containerize and deploy a Symfony application using Docker and related technologies.

---

## Technologies Used

The application is deployed using:

- Docker
- Nginx
- PHP-FPM
- MySQL
- Docker Compose
- Railway or another container platform that provides a `PORT` environment variable

---

## Project Objectives

This project is designed to demonstrate understanding of:

- Containerized application deployment
- Symfony production configuration
- Docker networking and orchestration
- Web server configuration using Nginx
- Environment variable management
- Cloud deployment workflows (e.g., Railway)

---

## Project Requirements

Your final project must include:

- A working Symfony application
- Dockerized deployment setup
- Proper Nginx configuration
- Production-ready environment configuration
- Database integration
- Complete deployment documentation
- Successful deployment on a hosting platform (e.g., Railway)

---

## Current Implementation Status

The project now includes the required deployment files:

- Dockerfile
- docker-compose.yaml
- entrypoint.sh
- nginx.conf
- nginx-main.conf
- .dockerignore

And the container architecture is:

- web: Nginx reverse proxy on port 8080
- app: Nginx + PHP-FPM Symfony application container
- database: MySQL 8 container on port 3310 (host) / 3306 (container)

For Railway deployments, Railway should build the root Dockerfile directly and run the Nginx + PHP-FPM container on the platform-assigned port.

---

## Required Files

Create the following files in your project root directory:

### Dockerfile

Defines the blueprint for building the application’s Docker image.  
Without it, the application cannot be containerized or deployed consistently across environments.

---

### docker-compose.yaml

Defines and manages multiple containers as a single application stack (primarily for local development).  
Ensures all services work together as a complete system and simplifies container orchestration.

---

### entrypoint.sh

Script executed when a container starts.  
Ensures the application initializes in a consistent and production-ready state every time.

---

### nginx.conf

Main configuration file for the Nginx web server.  
Acts as the entry point for all web traffic and forwards requests correctly to the application.

---

### nginx-main.conf

Additional or environment-specific Nginx configuration file.  
Improves maintainability and allows safer updates without modifying the main config.

---

### .dockerignore

Specifies files and folders excluded from the Docker build context.  
Helps keep Docker images clean and builds efficient.

---

### .env

Stores environment variables used by the application.  
Keeps sensitive information out of the codebase and allows flexible configuration across environments.

---

## Local Run Guide

### Prerequisites

- Docker Desktop installed and running
- Windows: Ensure Docker daemon is started (`docker info` should work)
- Port 8080 should be available for the web server

### Steps to Run Locally

1. **Start Docker Desktop** and verify the engine is running:

    docker info

2. **Build and start all containers**:

    docker compose up -d --build

3. **Verify all services are running**:

    docker compose ps

4. **Access the application**:

    Open http://localhost:8080 in your browser.

5. **View application logs** (if needed):

    docker compose logs -f app

6. **Stop containers when finished**:

    docker compose down

To remove database volumes and start fresh:

    docker compose down -v

### What Happens on Startup

When the `app` container starts:
1. Waits for database connection (timeout: ~60 seconds)
2. Clears Symfony cache for production mode
3. **Automatically runs database migrations** (Doctrine Migrations)
4. Nginx starts and forwards PHP requests to PHP-FPM
5. Nginx routes traffic to PHP-FPM in local Docker Compose and on Railway

No additional setup is needed—migrations run automatically.

### Railway Deployment

When deploying to Railway:

1. Set the service to use this repository and let Railway build the Dockerfile.
2. Provide the database and secret environment variables, including `APP_SECRET`, `DATABASE_URL`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, and `MYSQL_ROOT_PASSWORD`.
3. Make sure Railway assigns a `PORT` value for the service mapping.
4. Use Railway’s generated public URL after the deploy finishes.
5. If Railway shows `GitHub Repo not found`, reconnect the GitHub integration and re-select the repository before redeploying.
6. If you add a custom domain, create the DNS records Railway shows in its dialog and wait for propagation before verifying.

---

## Troubleshooting

### Error: unable to get image ... failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine

**Cause:** Docker daemon is not running on Windows.

**Fix:**

1. Open Docker Desktop manually (Run as Administrator if needed).
2. Wait for Docker Desktop to show "Engine running" status.
3. Retry:

    docker compose up -d

**Quick checks:**

    docker info
    Get-Service -Name com.docker.service

If service is stopped, start Docker Desktop from the application and retry.

---

### Error: Symfony routing class loading errors after dependency or cache changes

**Example:**
```
ClassNotFoundError: Attempted to load class 'CompiledUrlGeneratorDumper' from namespace 'Symfony\Component\Routing\Generator\Dumper'
```

**Cause:** Stale Composer autoload cache or Symfony build cache.

**Fix:**

    composer dump-autoload -o
    php bin/console cache:clear
    php bin/console cache:clear --env=prod
    php bin/console debug:router

The `debug:router` command verifies that all routes are properly registered.

---

### Error: The "MYSQL_USER" variable is not set. Defaulting to a blank string

**Cause:** Environment variables referenced in `DATABASE_URL` but not defined in `.env`.

**Fix:** Ensure `.env` contains:

    MYSQL_USER=app
    MYSQL_PASSWORD=!ChangeMe!
    MYSQL_DATABASE=app
    MYSQL_ROOT_PASSWORD=RootChangeMe!

---

### Database migration errors during deployment

**Issue:** Migrations don't run or show version conflicts.

**Solution:**

1. Check container startup logs:

    docker compose logs app --tail 30

2. Verify database is accessible:

    docker compose exec app php bin/console doctrine:migrations:status

3. If needed, manually run migrations:

    docker compose exec app php bin/console doctrine:migrations:migrate

---

### Application accessible but returns 404/500 errors

**Possible causes:**

1. **Symfony routing cache is stale:**

    docker compose exec app php bin/console cache:clear --env=prod

2. **Nginx not routing correctly:**
   - Check that `nginx.conf` has `fastcgi_pass app:9000;` (correct internal hostname)
   - Verify Nginx config is valid:

    docker compose logs web | head -20

3. **Database connection issue:**
   - Verify DATABASE_URL in docker-compose.yaml uses `database:3306` (not localhost)
   - Check MySQL health:

    docker compose ps database

---

## Deployment Notes

### Environment Variables for Production (Railway & Other Platforms)

Before deployment, you **MUST** set these environment variables (replace placeholders with real values):

```
APP_ENV=prod
APP_DEBUG=0
APP_SECRET=<generate-a-long-random-string-at-least-32-chars>
MYSQL_DATABASE=app_production
MYSQL_USER=app_user
MYSQL_PASSWORD=<strong-random-password>
MYSQL_ROOT_PASSWORD=<strong-random-password>
```

### Production Configuration Checklist

- [ ] Generate secure `APP_SECRET` (use `openssl rand -base64 32` or similar)
- [ ] Set unique `MYSQL_PASSWORD` and `MYSQL_ROOT_PASSWORD`
- [ ] Ensure `APP_DEBUG=0` to disable debug mode
- [ ] Ensure `APP_ENV=prod` in deployment environment
- [ ] Configure database connectivity (Docker Compose uses `database` hostname internally)
- [ ] Verify health checks are active (MySQL health check set to 20 retries × 5s intervals)
- [ ] Test migrations run during startup
- [ ] Confirm Nginx successfully routes requests to PHP-FPM

### Local Development vs Production

- **Local (.env file)**: `APP_ENV=dev` for Symfony debug and dev features
- **Docker containers (Dockerfile)**: `APP_ENV=prod` and `APP_DEBUG=0` (hardcoded for security)
- **Railway & cloud platforms**: Override with environment variables to use production mode automatically

### Notes

- The database uses MySQL 8.0 with `mysql_native_password` plugin (compatible with Doctrine)
- Nginx listens on port 80 (mapped to 8080 locally, use platform's default port in production)
- Database is accessible internally as `database:3306` within the Docker network
- Migrations are executed automatically during container startup

---

## Deployment Platform

Recommended platform:

- Railway

---

## Railway Deployment Instructions

### Step 1: Prepare Your GitHub Repository

1. Initialize git (if not already done):

    git init
    git add .
    git commit -m "Initial deployment setup"

2. Create a repository on GitHub and push:

    git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
    git branch -M main
    git push -u origin main

### Step 2: Connect Railway to GitHub

1. Go to [railway.app](https://railway.app)
2. Sign in or create an account
3. Click **New Project** → **Deploy from GitHub repo**
4. Authorize Railway to access GitHub
5. Select your repository

### Step 3: Configure Railway Services

Railway deploys the repository from GitHub, but the local `docker-compose.yaml` is mainly for development. On Railway, deploy the web application with the Dockerfile and connect it to a MySQL database service or external MySQL instance.

**Web/App Service:**
- Railway will build from the repository and run the container
- Use the platform's assigned public URL
- Keep `APP_ENV=prod` and `APP_DEBUG=0`

**Database Service:**
- Use Railway's MySQL service if available, or another MySQL provider
- Set the database name, user, and password to match the variables below
- Make sure the app can reach the database using Railway-provided host/port values

### Step 4: Set Environment Variables in Railway

Click on the **App** service and go to **Variables**. Add these:

| Variable | Value | Notes |
|----------|-------|-------|
| `APP_ENV` | `prod` | **MUST** be prod |
| `APP_DEBUG` | `0` | **MUST** be 0 for security |
| `APP_SECRET` | `[generate-long-random-value]` | Generate with: `openssl rand -base64 32` |
| `MYSQL_DATABASE` | `app_production` | Database name |
| `MYSQL_USER` | `app_user` | DB user |
| `MYSQL_PASSWORD` | `[strong-random-value]` | Random strong password |
| `MYSQL_ROOT_PASSWORD` | `[strong-random-value]` | Random strong password |

### Step 5: Deploy

1. Railway will automatically build and deploy when you push to GitHub
2. Monitor deployment progress in Railway dashboard
3. Once deployment completes, Railway will provide a public URL

### Step 6: Verify Deployment

1. Visit the Railway URL provided
2. Verify the application loads correctly
3. Test CRUD operations:
   - Click "Products" to see database connection
   - Create a new product to test form submission
   - Verify database persistence across requests

### Troubleshooting Railway Deployment

**Build fails with "Dockerfile not found":**
- Ensure all required files are in the repository root
- Verify .dockerignore is not excluding Dockerfile

**Application shows 500 error:**
- Check Railway service logs (click on app service → Logs)
- Verify all environment variables are set
- Check if migrations ran successfully

**Database connection error:**
- Verify the Railway database credentials match the values in your app variables
- Check database service status in Railway dashboard
- Ensure the app is using the database host and port provided by Railway or your external provider

**Application takes too long to start:**
- The container waits up to 60 seconds for database connectivity
- Check database health in Railway logs
- Increase app service start timeout if needed

## Notes

This project is intended for educational purposes and demonstrates full-stack containerized deployment practices using Symfony.

## What to Submit

### 1. Deployed Application Link

Submit the Railway URL (or other hosting platform URL) where the application is live.

**Testing Requirements:**
- App must be publicly accessible
- Home page loads without errors
- Products CRUD operations work (create, read, update, delete)
- Database persistence is confirmed

### 2. Video Explanation (5–10 minutes required)

Record and submit a video demonstrating:

**Suggested Timeline:**

| Topic | Duration | Content |
|-------|----------|---------|
| **Project Overview** | 0:00–1:00 | Show project structure, list required files (Dockerfile, docker-compose.yaml, entrypoint.sh, nginx.conf) |
| **Dockerfile Explanation** | 1:00–2:30 | <ul><li>Base image: `php:8.3-fpm-alpine` (lightweight, production-ready)</li><li>PHP extensions installed (intl, pdo, pdo_mysql, opcache)</li><li>Composer dependencies installed with `--no-dev` (production optimization)</li><li>Environment: `APP_ENV=prod`, `APP_DEBUG=0`</li><li>Entrypoint: Database wait logic + migrations</li></ul> |
| **Nginx Configuration** | 2:30–4:00 | <ul><li>Reverse proxy setup: listens on port 80</li><li>FastCGI routing: `fastcgi_pass app:9000` (internal Docker hostname)</li><li>try_files directive for Symfony routing</li><li>Static asset caching (7 days for CSS/JS/images)</li></ul> |
| **Environment Variables** | 4:00–4:45 | <ul><li>List required variables for production</li><li>Explain database connection string format</li><li>Show how docker-compose.yaml interpolates variables from .env</li><li>Security: never commit real credentials</li></ul> |
| **Local Testing** | 4:45–6:30 | <ul><li>Run `docker compose up -d --build`</li><li>Verify `docker compose ps` (all services running, healthy status)</li><li>Access app at `http://localhost:8080`</li><li>Show logs: `docker compose logs app` (migrations executing)</li><li>Test CRUD: create/view product</li></ul> |
| **Railway Deployment** | 6:30–8:15 | <ul><li>Push repository to GitHub</li><li>Create Railway project from GitHub repo</li><li>Set environment variables in Railway dashboard</li><li>Monitor deployment progress</li><li>Access live URL and verify it works</li></ul> |
| **Live Verification** | 8:15–9:30 | <ul><li>Access production URL in browser</li><li>Demonstrate CRUD operations on live app</li><li>Show that database is persistent across requests</li></ul> |

**Video Quality Requirements:**
- Clear audio (speak clearly, no background noise)
- Readable terminal/browser font size
- Logical flow between topics
- Stay within 5–10 minute total time
- No long pauses or debugging time

**Recommended Tools:**
- OBS Studio (free)
- Loom (free plan available)
- Windows Screen Recording (Win+G)
- ScreenFlow (macOS)

| Category                              | Description                                           | Points |
| ------------------------------------- | ----------------------------------------------------- | ------ |
| **Docker Setup**                      | Dockerfile and docker-compose are correct and working | 25     |
| **Nginx Configuration**               | Correct routing to PHP-FPM and proper Symfony setup   | 15     |
| **Symfony Production Setup**          | Production mode, caching, and stable runtime          | 15     |
| **Environment & Security**            | Proper .env usage and secure configuration            | 10     |
| **Database Integration**              | Working database connection and CRUD/migrations       | 10     |
| **Deployment**                        | Successfully deployed and accessible live application | 15     |
| **Understanding (Video Explanation)** | Clear explanation of Docker, Nginx, and deployment    | 7      |
| **Video Presentation Quality**        | Clear, complete, and within 5–10 minutes              | 3      |
