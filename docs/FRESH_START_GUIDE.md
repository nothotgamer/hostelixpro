# Hostelix Pro — Fresh Start & Admin Setup Guide

**Version:** 1.1  
**Last Updated:** February 11, 2026

---

## Overview

This guide walks you through **completely resetting** the Hostelix Pro database and setting up fresh admin accounts using `admin_setup.py`. Use this when you need a clean slate — whether deploying to a new environment, resetting a corrupted database, or starting fresh for production.

---

## Table of Contents

1. [Stop the Backend Server](#1-stop-the-backend-server)
2. [Delete the Old Database](#2-delete-the-old-database)
3. [Recreate the Database Tables](#3-recreate-the-database-tables)
4. [Set Up Admin Accounts](#4-set-up-admin-accounts)
5. [Verify the Setup](#5-verify-the-setup)
6. [Start Using the System](#6-start-using-the-system)

---

## 1. Stop the Backend Server

Before deleting the database, stop any running backend process:

- **If running in terminal:** Press `Ctrl + C`
- **If running as a service:** `sudo systemctl stop hostelixpro`
- **If running in Docker:** `docker stop hostelixpro`

> ⚠️ **WARNING:** Deleting the database will permanently erase ALL data — users, students, fees, reports, routines, announcements, notifications, and audit logs. **Make a backup first** if you need any existing data.

> ❗ **IMPORTANT:** All user accounts, usernames, and passwords are stored **only** in the database. When you delete the database file, **every account is permanently gone** — including all admin, teacher, routine manager, and student accounts. There is no separate credential store. After deleting the database, you **must** run `admin_setup.py` to create new admin accounts before anyone can log in.

---

## 2. Delete the Old Database

> ❗ **CRITICAL — Correct Database Location:**  
> The SQLite database is stored inside the **`instance/`** folder, NOT directly in the `backend/` folder.  
> The correct path is: **`backend/instance/hostelixpro.db`**  
> This is because Flask creates SQLite databases in its `instance` directory by default.

### For SQLite (Default Local Setup)

**Windows (Command Prompt):**
```cmd
cd project\backend
del instance\hostelixpro.db
```

**Windows (PowerShell):**
```powershell
cd project\backend
Remove-Item instance\hostelixpro.db
```

**macOS / Linux:**
```bash
cd project/backend
rm instance/hostelixpro.db
```

> 💡 **TIP:** To make sure no database file is hiding anywhere, search for all `.db` files:
> ```bash
> # Windows PowerShell
> Get-ChildItem -Path . -Filter *.db -Recurse
> 
> # macOS / Linux
> find . -name "*.db"
> ```
> Delete every `hostelixpro.db` file you find.

Also delete the migration history if you want a completely clean slate:

**Windows:**
```cmd
rmdir /s /q migrations\versions
mkdir migrations\versions
```

**macOS / Linux:**
```bash
rm -rf migrations/versions/*
```

### For PostgreSQL

```bash
# Drop and recreate the database
psql -U postgres
DROP DATABASE hostelixpro;
CREATE DATABASE hostelixpro OWNER your_user;
\q
```

---

## 3. Recreate the Database Tables

Navigate to the backend directory and activate the virtual environment:

**Windows (PowerShell):**
```powershell
cd project\backend
.venv\Scripts\Activate.ps1
```

**Windows (CMD):**
```cmd
cd project\backend
.venv\Scripts\activate.bat
```

**macOS / Linux:**
```bash
cd project/backend
source .venv/bin/activate
```

Now create all tables:

```bash
python create_tables.py
```

Expected output:
```
Creating tables...
Done!
```

This creates all 11 tables: `users`, `students`, `fees`, `fee_structures`, `transactions`, `reports`, `routines`, `announcements`, `notifications`, `audit_logs`, and `backup_meta`.

---

## 4. Set Up Admin Accounts

Use the `admin_setup.py` script to create your admin account(s).

### Option A: Interactive Mode (Recommended)

```bash
python admin_setup.py
```

The script will prompt you for:

```
═══════════════════════════════════════════════════════════
  HOSTELIX PRO — Admin Account Setup
═══════════════════════════════════════════════════════════

  This will create an admin account for the system.
  Admin users have full access to all features.

───────────────────────────────────────────────────────────

  Enter admin email: admin@yourschool.com
  Enter display name: Dr. Ahmed Khan

  Password requirements:
    • At least 8 characters
    • At least 1 uppercase letter (A-Z)
    • At least 1 lowercase letter (a-z)
    • At least 1 digit (0-9)

  Enter password: ********
  Confirm password: ********

───────────────────────────────────────────────────────────
  Email:   admin@yourschool.com
  Name:    Dr. Ahmed Khan
  Role:    admin
───────────────────────────────────────────────────────────

  Create this admin account? (y/n): y

  ✓ Admin account created successfully!
    ID:    1
    Email: admin@yourschool.com
    Name:  Dr. Ahmed Khan

  Create another admin account? (y/n): n

═══════════════════════════════════════════════════════════
  Setup complete! You can now log in to the app.
═══════════════════════════════════════════════════════════
```

### Option B: Quick Setup (Default Admin)

For quick testing, create a default admin account instantly:

```bash
python admin_setup.py --quick
```

This creates:

| Field | Value |
|:---|:---|
| Email | `admin@hostelixpro.com` |
| Password | `Admin@1234` |
| Display Name | System Administrator |

> ⚠️ **Change this password immediately after first login in production!**

### Option C: Full Reset (Delete DB + Recreate + Admin)

If you want to do everything in one command — delete the database, recreate tables, and set up an admin:

```bash
python admin_setup.py --reset
```

This will:
1. Ask for confirmation (since it deletes ALL data)
2. Delete the database file (`instance/hostelixpro.db`)
3. Recreate all 11 tables
4. Launch the interactive admin setup

### Option D: List Existing Admins

To see which admin accounts already exist:

```bash
python admin_setup.py --list
```

### All Commands

| Command | Description |
|:---|:---|
| `python admin_setup.py` | Interactive setup — prompts for email, name, password |
| `python admin_setup.py --quick` | Quick setup — creates default admin account |
| `python admin_setup.py --reset` | Full reset — deletes DB, recreates tables, sets up admin |
| `python admin_setup.py --list` | Shows all existing admin accounts |
| `python admin_setup.py --help` | Displays usage help |

---

## 5. Verify the Setup

### Start the Backend

```bash
python app.py
```

### Test the Health Endpoint

```bash
curl http://localhost:3000/api/v1/health
```

Expected:
```json
{"status": "healthy", "service": "Hostelix Pro API"}
```

### Test Admin Login

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@hostelixpro.com", "password": "Admin@1234"}'
```

Expected: A response with `tx_id` and `otp_sent: true`.

> 💡 **TIP:** Since email is likely not configured on a fresh setup, OTPs will print to the backend terminal. Look for:  
> `[DEV MODE] OTP for admin@hostelixpro.com: 482917`

---

## 6. Start Using the System

After the admin is set up, here's the recommended order to configure the system:

### Step-by-Step First Run

| Step | Action | Where |
|:---|:---|:---|
| 1 | Log in with admin account | Flutter App → Login page |
| 2 | Create teacher accounts | Admin Dashboard → Users → Add User |
| 3 | Create routine manager accounts | Admin Dashboard → Users → Add User |
| 4 | Set up fee structures | Admin Dashboard → Fees → Fee Structures |
| 5 | Create announcements | Admin Dashboard → Announcements |
| 6 | Students self-register via the app | Login page → Register |
| 7 | Admin approves student accounts | Admin Dashboard → Users → Pending Approvals |
| 8 | Teachers get assigned students | Admin Dashboard → Users → Assign |

### User Roles Reference

| Role | Access Level |
|:---|:---|
| **Admin** | Full system access — users, fees, reports, backups, audit logs |
| **Teacher** | View assigned students, approve reports, manage routines |
| **Routine Manager** | Manage walk/exit requests, return confirmations |
| **Student** | Submit reports, request exits, view fees, pay fees |

---

## Quick Reference: Complete Fresh Start

Copy-paste this block to do a full reset in one go:

### Windows (PowerShell)
```powershell
cd project\backend
.venv\Scripts\Activate.ps1

# Delete old database (CORRECT PATH — inside instance/ folder)
Remove-Item instance\hostelixpro.db -ErrorAction SilentlyContinue

# Recreate tables
python create_tables.py

# Set up admin account (interactive)
python admin_setup.py

# Start server
python app.py
```

### macOS / Linux
```bash
cd project/backend
source .venv/bin/activate

# Delete old database (CORRECT PATH — inside instance/ folder)
rm -f instance/hostelixpro.db

# Recreate tables
python create_tables.py

# Set up admin account (interactive)
python admin_setup.py

# Start server
python app.py
```

### One-Line Reset (All Platforms)
```bash
python admin_setup.py --reset
```

---

*Hostelix Pro — Fresh Start & Admin Setup Guide v1.1*
