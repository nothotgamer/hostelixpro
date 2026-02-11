# Hostelix Pro — Docker Deployment Guide

**Version:** 1.0  
**Last Updated:** February 11, 2026

---

## Overview

This guide explains how to run the entire Hostelix Pro stack (Backend + PostgreSQL + Redis) using Docker. This ensures a consistent environment identical to production and simplifies setup.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Quick Start (Windows)](#2-quick-start-windows)
3. [Manual Start (All Platforms)](#3-manual-start-all-platforms)
4. [What's Included?](#4-whats-included)
5. [Default Credentials](#5-default-credentials)
6. [Managing the Environment](#6-managing-the-environment)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Prerequisites

You need **Docker Desktop** installed and running.

- **Download:** [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
- **Verify:** Open a terminal and run `docker --version`

---

## 2. Quick Start (Windows)

We've assigned a simple batch script to handle everything for you.

1. Double-click **`run_docker.bat`** in the project root folder.
2. Wait for the containers to build and start.
3. You will see logs streaming. Once you see `[INFO] Listening at: http://0.0.0.0:3000`, it's ready!

---

## 3. Manual Start (All Platforms)

If you are on macOS/Linux or prefer manual commands:

1. Navigate to the backend directory:
   ```bash
   cd project/backend
   ```

2. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

3. To run in background (detached mode):
   ```bash
   docker-compose up --build -d
   ```

4. To stop:
   ```bash
   docker-compose down
   ```

---

## 4. What's Included?

The Docker configuration spins up three services:

| Service | internal Port | External Port | Description |
|:---|:---|:---|:---|
| **backend** | 3000 | **3000** | Flask API with Gunicorn (4 workers) |
| **db** | 5432 | **5432** | PostgreSQL 15 (Production database) |
| **redis** | 6379 | **6379** | Redis 7 (Caching & Background tasks) |

> 💡 **Persistency:** Database data is stored in a Docker volume `postgres_data`, so your data survives restarts.

---

## 5. Default Credentials

On first run, the database is automatically seeded with test accounts:

| Role | Email | Password |
|:---|:---|:---|
| **Admin** | `admin@example.com` | `TestPass123` |
| **Teacher** | `teacher@example.com` | `TestPass123` |
| **Routine Mgr** | `routine@example.com` | `TestPass123` |
| **Student** | `student1@example.com` | `TestPass123` |

> ⚠️ **Note:** If you want to create a fresh admin account manually inside Docker:
> ```bash
> docker-compose exec backend python admin_setup.py
> ```

---

## 6. Managing the Environment

### View Logs
```bash
docker-compose logs -f
# OR specific service
docker-compose logs -f backend
```

### Reset Database (Fresh Start in Docker)
To wipe the PostgreSQL database and start fresh:

```bash
docker-compose down -v
docker-compose up -d
```
*The `-v` flag removes the volumes (data).*

### Access Database Shell
```bash
docker-compose exec db psql -U hostel -d hostelixpro
```

---

## 7. Troubleshooting

### "Port already allocated"
If port 3000 (API) or 5432 (Postgres) is in use:
1. Stop the local backend if running (`Ctrl+C` in terminal).
2. Stop local Postgres if installed.
3. Or modify `docker-compose.yml` ports mapping (e.g., `"3001:3000"`).

### "Connection refused"
- Ensure Docker Desktop is running.
- Wait a few seconds for the database to initialize (the `wait_for_db.py` script handles this, but it takes 5-10 seconds).

### "Database does not exist"
- The entrypoint script (`wait_for_db.py` + `create_tables.py`) runs automatically. If it failed, check logs: `docker-compose logs backend`.

---

*Hostelix Pro — Docker Guide v1.0*
