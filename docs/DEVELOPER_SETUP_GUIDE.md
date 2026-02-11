# Hostelix Pro — Developer Setup & Deployment Guide

**Version:** 1.0  
**Last Updated:** February 10, 2026  
**Audience:** New developers joining the project

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Structure Overview](#2-project-structure-overview)
3. [Backend Setup (Flask API)](#3-backend-setup-flask-api)
4. [Creating the Admin User](#4-creating-the-admin-user)
5. [Frontend Setup (Flutter App)](#5-frontend-setup-flutter-app)
6. [Connecting Frontend to Backend](#6-connecting-frontend-to-backend)
7. [Building for Production](#7-building-for-production)
8. [Remote Access with Ngrok](#8-remote-access-with-ngrok)
9. [Cloud Deployment](#9-cloud-deployment)
10. [Email / SMTP Configuration](#10-email--smtp-configuration)
11. [API Reference Quick Start](#11-api-reference-quick-start)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Prerequisites

Before starting, ensure the following tools are installed on your machine:

### Required Software

| Tool | Minimum Version | Download Link | Purpose |
|:---|:---|:---|:---|
| **Python** | 3.10+ | [python.org/downloads](https://python.org/downloads) | Backend API server |
| **pip** | Latest | Comes with Python | Python package manager |
| **Flutter SDK** | 3.10+ | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) | Mobile/Desktop/Web frontend |
| **Git** | Any | [git-scm.com](https://git-scm.com) | Version control |

### Optional Software

| Tool | Purpose | When Needed |
|:---|:---|:---|
| **Android Studio** | Android emulator + SDK | Building Android APK |
| **Xcode** (macOS only) | iOS build tools | Building iOS app |
| **Visual Studio** (Windows) | C++ desktop development workload | Building Windows desktop app |
| **Chrome** | Web browser | Flutter web debugging |
| **Ngrok** | Secure tunneling | Remote access from other devices |
| **PostgreSQL** | Production database | Cloud deployment |
| **Docker** | Containerization | Docker-based deployment |

### Verify Your Environment

Open a terminal and run:

```bash
# Check Python
python --version          # Should show 3.10+

# Check pip
pip --version

# Check Flutter
flutter --version         # Should show 3.10+
flutter doctor            # Shows all platform readiness
```

> [!IMPORTANT]
> If `flutter doctor` shows issues (missing Android SDK, Chrome not found, etc.), resolve them before proceeding. Run `flutter doctor -v` for detailed diagnostics.

---

## 2. Project Structure Overview

```
project/
├── backend/                  # Flask REST API (Python)
│   ├── app/                  # Application package
│   │   ├── __init__.py       # App factory (create_app)
│   │   ├── api/              # API route blueprints (11 modules)
│   │   ├── models/           # SQLAlchemy data models (11 models)
│   │   ├── services/         # Business logic layer
│   │   └── utils/            # Decorators, helpers
│   ├── scripts/              # Utility scripts (seed_db.py)
│   ├── migrations/           # Alembic database migrations
│   ├── app.py                # Entry point
│   ├── requirements.txt      # Python dependencies
│   ├── Dockerfile            # Docker production image
│   ├── .env                  # Environment config (DO NOT COMMIT)
│   └── .env.example          # Template for .env
│
├── hostelixpro/              # Flutter mobile app (Dart)
│   ├── lib/                  # Application source code
│   │   ├── main.dart         # App entry point
│   │   ├── pages/            # UI screens (22 pages)
│   │   ├── services/         # API clients and services
│   │   ├── models/           # Dart data models
│   │   ├── providers/        # State management (Provider)
│   │   └── widgets/          # Reusable UI components
│   ├── assets/               # Images, icons
│   ├── pubspec.yaml          # Flutter dependencies
│   ├── android/              # Android-specific config
│   ├── ios/                  # iOS-specific config
│   ├── windows/              # Windows desktop config
│   ├── linux/                # Linux desktop config
│   ├── macos/                # macOS desktop config
│   └── web/                  # Web build config
│
└── docs/                     # Documentation
    ├── FEATURES.md           # Full feature documentation
    └── DEVELOPER_SETUP_GUIDE.md  # This file
```

---

## 3. Backend Setup (Flask API)

### Step 1: Navigate to the Backend Directory

```bash
cd project/backend
```

### Step 2: Create a Python Virtual Environment

```bash
# Create virtual environment
python -m venv .venv

# Activate it
# On Windows (PowerShell):
.venv\Scripts\Activate.ps1

# On Windows (Command Prompt):
.venv\Scripts\activate.bat

# On macOS/Linux:
source .venv/bin/activate
```

> [!TIP]
> You'll know the virtual environment is active when you see `(.venv)` at the beginning of your terminal prompt.

### Step 3: Install Python Dependencies

```bash
pip install -r requirements.txt
```

This installs:
- **Flask** — Web framework
- **Flask-SQLAlchemy** — ORM for database access
- **Flask-Migrate** — Database migration management
- **Flask-CORS** — Cross-Origin Resource Sharing
- **bcrypt** — Password hashing
- **PyJWT** — JWT token authentication
- **pyotp** — Time-based OTP generation (2FA)
- **reportlab** — PDF generation (fee challans)
- **qrcode** — QR code generation (2FA setup)
- **openpyxl** — Excel export
- **cryptography** — AES encryption for backups

### Step 4: Configure Environment Variables

```bash
# Copy the example config
cp .env.example .env      # macOS/Linux
copy .env.example .env     # Windows
```

Now edit `.env` with your values:

```env
# ─── Flask Configuration ───────────────────────────────
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=generate-a-random-string-here
PORT=3000

# ─── Database ──────────────────────────────────────────
# SQLite (recommended for local development):
DATABASE_URL=sqlite:///hostelixpro.db

# PostgreSQL (for production):
# DATABASE_URL=postgresql://user:password@localhost:5432/hostelixpro

# ─── JWT ───────────────────────────────────────────────
JWT_SECRET_KEY=generate-another-random-string-here

# ─── CORS ──────────────────────────────────────────────
# Allow all origins during development:
CORS_ORIGINS=*
# For production, restrict to your domain:
# CORS_ORIGINS=https://yourdomain.com

# ─── Email (Optional for dev) ─────────────────────────
# If not configured, OTPs will print to the terminal console
# MAIL_SERVER=smtp.gmail.com
# MAIL_PORT=587
# MAIL_USE_TLS=True
# MAIL_USERNAME=your-email@gmail.com
# MAIL_PASSWORD=your-app-password
```

> [!IMPORTANT]
> **For development without email setup:** When SMTP is not configured, OTPs are printed directly to the backend terminal console as `[DEV MODE] OTP for user@email.com: 123456`. Look at the terminal running the Flask server to see the OTP codes.

### Step 5: Initialize the Database

```bash
# Create all database tables
python create_tables.py
```

You should see:
```
Creating tables...
Done!
```

### Step 6: Start the Backend Server

```bash
python app.py
```

You should see:
```
 * Running on http://0.0.0.0:3000
 * Debug mode: on
```

### Step 7: Verify the Backend is Running

Open a browser or use `curl`:

```bash
curl http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": 1707580800000,
  "service": "Hostelix Pro API"
}
```

---

## 4. Creating the Admin User

There are **two methods** to create the admin user and seed test data:

### Method A: Using the Seed Script (Recommended)

The seed script creates a full set of test users automatically:

```bash
# From the backend/ directory (with venv activated)
python scripts/seed_db.py
```

This creates the following accounts:

| Role | Email | Password | Display Name |
|:---|:---|:---|:---|
| **Admin** | `admin@example.com` | `TestPass123` | System Administrator |
| **Teacher** | `teacher@example.com` | `TestPass123` | Mr. Johnson |
| **Routine Manager** | `routine@example.com` | `TestPass123` | Alice Brown |
| **Student 1** | `student1@example.com` | `TestPass123` | John Doe (Room A101) |
| **Student 2** | `student2@example.com` | `TestPass123` | Jane Smith (Room A102) |
| **Student 3** | `student3@example.com` | `TestPass123` | Mike Wilson (Room B201) |
| **Student 4** | `student4@example.com` | `TestPass123` | Sarah Davis (Room B202) |
| **Student 5** | `student5@example.com` | `TestPass123` | Tom Anderson (Room C301) |

> [!WARNING]
> **Change all passwords before using in production!** The seed script uses weak test passwords.

### Method B: Using the Flask Shell (Manual Admin Creation)

If you want to create just an admin account manually:

```bash
# From the backend/ directory (with venv activated)
python
```

```python
from app import create_app, db
from app.models.user import User
from app.services.auth_service import AuthService

app = create_app()
with app.app_context():
    db.create_all()
    
    admin = User(
        email='your-admin-email@example.com',
        password_hash=AuthService.hash_password('YourSecurePassword123'),
        role='admin',
        display_name='Admin Name'
    )
    db.session.add(admin)
    db.session.commit()
    print(f'Admin created with ID: {admin.id}')
```

### Method C: Using the API (After Backend is Running)

Register through the API and then manually approve in the database:

```bash
# Step 1: Register a user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@yourdomain.com", "password": "SecurePass123", "display_name": "Admin"}'
```

Then update the user's role to `admin` in the database:

```bash
python
```

```python
from app import create_app, db
from app.models.user import User

app = create_app()
with app.app_context():
    user = User.query.filter_by(email='admin@yourdomain.com').first()
    user.role = 'admin'
    user.is_approved = True
    db.session.commit()
    print('User promoted to admin!')
```

---

## 5. Frontend Setup (Flutter App)

### Step 1: Verify Flutter Installation

```bash
flutter doctor
```

Ensure at least one platform shows a green checkmark ✓. Common setups:

| Platform | Requirements |
|:---|:---|
| **Android** | Android Studio + Android SDK + emulator or physical device |
| **iOS** | macOS + Xcode + CocoaPods |
| **Web** | Chrome browser |
| **Windows Desktop** | Visual Studio with "Desktop development with C++" workload |
| **Linux Desktop** | `clang`, `cmake`, `ninja-build`, `libgtk-3-dev` |
| **macOS Desktop** | Xcode |

### Step 2: Navigate to the Flutter Project

```bash
cd project/hostelixpro
```

### Step 3: Install Flutter Dependencies

```bash
flutter pub get
```

This downloads all packages defined in `pubspec.yaml`:
- **http** — HTTP client for API calls
- **provider** — State management
- **go_router** — Navigation and routing
- **shared_preferences** — Local storage (settings, JWT tokens)
- **intl** — Date/time formatting and internationalization
- **path_provider** — File system paths
- **file_picker** — File selection dialogs
- **permission_handler** — Runtime permissions
- **flutter_form_builder** — Form validation
- **open_file** — Open files with native apps

### Step 4: Run the App in Development

```bash
# Run on connected device or emulator
flutter run

# Run on a specific device
flutter devices                        # List connected devices
flutter run -d chrome                  # Run on Chrome (web)
flutter run -d windows                 # Run on Windows desktop
flutter run -d <device-id>             # Run on specific device
```

### Step 5: Generate App Icon (Optional)

If you modify the logo or icon:

```bash
dart run flutter_launcher_icons
```

This reads the config from `pubspec.yaml` and generates platform-specific icons from `assets/images/logo.png`.

---

## 6. Connecting Frontend to Backend

### How It Works

The Flutter app connects to the backend via the `ApiClient` class in `lib/services/api_client.dart`. By default, it points to:

```
http://127.0.0.1:3000/api/v1
```

### Scenario A: Running on the Same Machine (Emulator/Desktop/Web)

If your backend and Flutter app are running on the **same computer**:

| Platform | Default URL | Notes |
|:---|:---|:---|
| **Chrome (Web)** | `http://127.0.0.1:3000` | Works out of the box |
| **Windows/macOS/Linux Desktop** | `http://127.0.0.1:3000` | Works out of the box |
| **Android Emulator** | `http://10.0.2.2:3000` | Emulator maps `10.0.2.2` to host's `127.0.0.1` |
| **iOS Simulator** | `http://127.0.0.1:3000` | Works out of the box |

> [!IMPORTANT]
> **Android Emulator users:** You must change the backend URL to `http://10.0.2.2:3000` in the app's **Settings → Backend Configuration** screen, or modify `defaultHost` in `lib/services/api_client.dart`.

### Scenario B: Running on a Physical Device (Same Network)

1. Find your computer's local IP address:
   ```bash
   # Windows
   ipconfig     # Look for "IPv4 Address" (e.g., 192.168.1.100)
   
   # macOS/Linux
   ifconfig     # or: ip addr show
   ```

2. Make sure the backend is bound to `0.0.0.0` (it is by default in `app.py`)

3. In the Flutter app, go to **Settings → Backend Configuration** and enter:
   ```
   http://192.168.1.100:3000
   ```

### Scenario C: Remote Access (Different Network)

See [Section 8: Remote Access with Ngrok](#8-remote-access-with-ngrok).

### Changing the Default Host in Code

To permanently change the default API host, edit `lib/services/api_client.dart`:

```dart
class ApiClient {
  // Change this to your backend URL
  static const String defaultHost = 'http://YOUR-IP-OR-DOMAIN:3000';
  static const String apiPrefix = '/api/v1';
  // ...
}
```

### In-App Configuration (No Code Change Required)

Users can change the backend URL at runtime through the app:

1. Open the app → **Settings** page
2. Scroll to **Backend Configuration**
3. Tap on the current URL
4. Enter the new backend host URL
5. Tap **Save**
6. Restart the app

---

## 7. Building for Production

### 7.1 Build Android APK

```bash
cd project/hostelixpro

# Build a release APK
flutter build apk --release

# Build a split APK (smaller per-architecture files)
flutter build apk --split-per-abi --release
```

Output location:
```
build/app/outputs/flutter-apk/app-release.apk
```

> [!TIP]
> For split APKs, you'll get three files:
> - `app-arm64-v8a-release.apk` — Most modern phones (recommended)
> - `app-armeabi-v7a-release.apk` — Older 32-bit phones
> - `app-x86_64-release.apk` — Emulator/Chromebook

### 7.2 Build Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 7.3 Build iOS (macOS only)

```bash
# Build for iOS
flutter build ios --release

# Open in Xcode for signing and deployment
open ios/Runner.xcworkspace
```

### 7.4 Build Windows Desktop

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

The entire `Release` folder is your distributable — copy it to share the app.

### 7.5 Build macOS Desktop

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/hostelixpro.app`

### 7.6 Build Linux Desktop

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

### 7.7 Build Web App

```bash
flutter build web --release
```

Output: `build/web/`

To serve the web build locally:
```bash
cd build/web
python -m http.server 8080
# Open http://localhost:8080 in your browser
```

> [!NOTE]
> For production web hosting, deploy the `build/web/` folder to any static hosting service (Nginx, Apache, Netlify, Vercel, GitHub Pages, Firebase Hosting, etc.).

### Build Summary Table

| Platform | Command | Output Location |
|:---|:---|:---|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/` |
| Android Bundle | `flutter build appbundle --release` | `build/app/outputs/bundle/release/` |
| iOS | `flutter build ios --release` | Open Xcode workspace |
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |
| Web | `flutter build web --release` | `build/web/` |

---

## 8. Remote Access with Ngrok

Ngrok creates a secure tunnel so the Flutter app can reach the backend from any network.

### Step 1: Install Ngrok

Download from [ngrok.com/download](https://ngrok.com/download) and add it to your PATH.

### Step 2: Sign Up and Get Your Auth Token

1. Create a free account at [dashboard.ngrok.com](https://dashboard.ngrok.com)
2. Copy your auth token from the dashboard
3. Configure ngrok:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
```

### Step 3: Start the Backend and Ngrok

**Terminal 1** — Start the backend:
```bash
cd project/backend
.venv\Scripts\activate     # or source .venv/bin/activate
python app.py
```

**Terminal 2** — Start ngrok:
```bash
ngrok http 3000
```

Ngrok will display a public URL like:
```
Forwarding  https://xxxx-xx-xx-xxx-xxx.ngrok-free.app -> http://localhost:3000
```

### Step 4: Configure the Flutter App

In the Flutter app, go to **Settings → Backend Configuration** and enter the ngrok URL:
```
https://xxxx-xx-xx-xxx-xxx.ngrok-free.app
```

> [!NOTE]
> The `ngrok-skip-browser-warning` header is already added to all API requests in `ApiClient`, so you don't need to worry about ngrok's browser interstitial page.

> [!WARNING]
> Free ngrok URLs change every time you restart ngrok. You'll need to update the app settings each time. Consider a paid ngrok plan for a fixed domain.

---

## 9. Cloud Deployment

### 9.1 Deploy Backend with Docker

The project includes a `Dockerfile` ready for production:

```bash
cd project/backend

# Build the Docker image
docker build -t hostelixpro-api .

# Run the container
docker run -d \
  --name hostelixpro \
  -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/hostelixpro \
  -e SECRET_KEY=your-production-secret \
  -e JWT_SECRET_KEY=your-jwt-secret \
  -e CORS_ORIGINS=* \
  hostelixpro-api
```

### 9.2 Deploy to Render (Free Tier Available)

1. Push your code to GitHub
2. Go to [render.com](https://render.com) → New Web Service
3. Connect your GitHub repo
4. Configure:
   - **Root Directory:** `backend`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `gunicorn --bind 0.0.0.0:3000 --workers 4 app:app`
5. Add environment variables (from `.env.example`)
6. Add a PostgreSQL database from Render's dashboard
7. Set `DATABASE_URL` to the provided connection string

### 9.3 Deploy to Railway

1. Go to [railway.app](https://railway.app)
2. New Project → Deploy from GitHub
3. Select your repo, set root to `backend`
4. Railway auto-detects Python and uses `Dockerfile` or `requirements.txt`
5. Add a PostgreSQL plugin
6. Set environment variables in the Railway dashboard

### 9.4 Deploy Backend Manually (VPS / Linux Server)

```bash
# On the server
git clone <your-repo-url>
cd project/backend

python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Create and configure .env
cp .env.example .env
nano .env  # Set production values

# Initialize database
python create_tables.py

# Seed admin user
python scripts/seed_db.py

# Run with Gunicorn (production server)
gunicorn --bind 0.0.0.0:3000 --workers 4 --timeout 120 app:app
```

For persistence, use `systemd` or `supervisor`:

```ini
# /etc/systemd/system/hostelixpro.service
[Unit]
Description=Hostelix Pro API
After=network.target

[Service]
User=www-data
WorkingDirectory=/opt/hostelixpro/backend
Environment="PATH=/opt/hostelixpro/backend/.venv/bin"
ExecStart=/opt/hostelixpro/backend/.venv/bin/gunicorn --bind 0.0.0.0:3000 --workers 4 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable hostelixpro
sudo systemctl start hostelixpro
```

---

## 10. Email / SMTP Configuration

Email is used for **OTP delivery** during login and **password reset** flows.

### Development Mode (No Email Setup)

If SMTP is **not configured**, OTPs are printed to the backend terminal:

```
[DEV MODE] OTP for admin@example.com: 482917
```

Simply look at the terminal running `python app.py` to see the codes.

### Production Mode (Gmail SMTP)

1. **Enable 2-Step Verification** on your Google Account
2. Generate an **App Password**: [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
3. Add to `.env`:

```env
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-16-char-app-password
MAIL_DEFAULT_SENDER=noreply@hostelixpro.com
```

### Other SMTP Providers

| Provider | Server | Port | TLS |
|:---|:---|:---|:---|
| Gmail | `smtp.gmail.com` | 587 | Yes |
| Outlook | `smtp-mail.outlook.com` | 587 | Yes |
| Yahoo | `smtp.mail.yahoo.com` | 587 | Yes |
| SendGrid | `smtp.sendgrid.net` | 587 | Yes |
| Mailgun | `smtp.mailgun.org` | 587 | Yes |

---

## 11. API Reference Quick Start

All API endpoints use the base path `/api/v1/`.

### Authentication Flow

```bash
# 1. Login (sends OTP to email)
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "TestPass123"}'

# Response: {"tx_id": "some-uuid", "otp_sent": true}

# 2. Verify OTP (check terminal for OTP in dev mode)
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"tx_id": "some-uuid", "otp": "123456"}'

# Response: {"token": "jwt-token-here", "user": {...}}

# 3. Use the token for authenticated requests
curl http://localhost:3000/api/v1/dashboard/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Complete API Module Map

| Module | Prefix | Key Endpoints |
|:---|:---|:---|
| **Health** | `/api/v1/health` | `GET /` — Server health check |
| **Auth** | `/api/v1/auth` | `POST /login`, `POST /verify-otp`, `POST /register`, `POST /logout`, `POST /forgot-password`, `POST /reset-password`, `GET /me` |
| **Users** | `/api/v1/users` | `GET /`, `POST /`, `PATCH /{id}`, `DELETE /{id}`, `POST /{id}/lock`, `POST /{id}/approve` |
| **Account** | `/api/v1/account` | `GET /profile`, `PATCH /profile`, `POST /password`, `POST /2fa/setup`, `POST /2fa/verify`, `POST /2fa/disable` |
| **Dashboard** | `/api/v1/dashboard` | `GET /stats`, `GET /teacher-daily`, `GET /routine-overview` |
| **Reports** | `/api/v1/reports` | `GET /`, `POST /`, `POST /{id}/approve`, `POST /{id}/reject`, `GET /export` |
| **Routines** | `/api/v1/routines` | `GET /`, `POST /`, `POST /{id}/approve`, `POST /{id}/reject`, `POST /{id}/return`, `POST /{id}/confirm-return`, `GET /stats`, `GET /currently-out`, `GET /calendar` |
| **Fees** | `/api/v1/fees` | `GET /`, `GET /calendar`, `GET /stats`, `POST /submit`, `POST /upload-proof`, `POST /{id}/approve`, `POST /{id}/reject`, `GET /{id}/transactions`, `GET /{id}/challan` |
| **Announcements** | `/api/v1/announcements` | `GET /`, `POST /`, `DELETE /{id}`, `GET /holidays` |
| **Notifications** | `/api/v1/notifications` | `GET /`, `POST /{id}/read`, `POST /read-all`, `GET /unread-count` |
| **Audit** | `/api/v1/audit` | `GET /` |
| **Backups** | `/api/v1/backups` | `POST /`, `GET /`, `GET /{id}/download`, `POST /restore` |

---

## 12. Troubleshooting

### Backend Issues

| Problem | Cause | Solution |
|:---|:---|:---|
| `ModuleNotFoundError` | Missing Python packages | Run `pip install -r requirements.txt` |
| Port 3000 already in use | Another process on same port | Kill the process or change `PORT` in `.env` |
| Database errors | Missing or outdated schema | Run `python create_tables.py` |
| CORS errors in Flutter | Origins not configured | Set `CORS_ORIGINS=*` in `.env` |
| OTP not received | SMTP not configured | Check terminal for `[DEV MODE] OTP` output |
| `ImportError: cannot import name...` | Virtual env not activated | Activate with `.venv\Scripts\activate` |

### Flutter Issues

| Problem | Cause | Solution |
|:---|:---|:---|
| `flutter pub get` fails | Network or SDK issues | Run `flutter clean` then `flutter pub get` |
| Can't connect to backend | Wrong URL or CORS | Check Settings → Backend Configuration |
| Android build fails | Missing SDK or licenses | Run `flutter doctor --android-licenses` |
| Web build blank page | Base href mismatch | Add `--base-href=/` to build command |
| Windows build fails | Missing Visual Studio workload | Install "Desktop development with C++" |
| `Gradle` error on Android | Outdated Gradle | Delete `.gradle` folder, re-run |

### Connection Issues

| Symptom | Check |
|:---|:---|
| Flutter app shows "Connection refused" | Is the backend running? Is the URL correct? |
| Android emulator can't reach backend | Use `http://10.0.2.2:3000` instead of `127.0.0.1` |
| Physical device can't connect | Use your computer's LAN IP (e.g., `192.168.x.x`) |
| Ngrok shows "tunnel not found" | Ngrok session expired — restart `ngrok http 3000` |
| API returns 401 Unauthorized | JWT token expired — log in again |
| API returns 403 Forbidden | Your user role doesn't have access to that endpoint |

### Quick Diagnostic Commands

```bash
# Check if backend is reachable
curl http://localhost:3000/api/v1/health

# Check Flutter devices
flutter devices

# Clean and rebuild Flutter project
flutter clean && flutter pub get && flutter run

# Check Python virtual environment
which python        # macOS/Linux
where python        # Windows
```

---

> [!NOTE]
> For the complete feature documentation including all user roles, workflows, and data models, see [FEATURES.md](./FEATURES.md).

---

*Hostelix Pro — Developer Setup & Deployment Guide v1.0*
