# Development Setup Guide

## Prerequisites

### Backend Requirements
- Python 3.10 or higher
- PostgreSQL 14+ (or use SQLite for development)
- Redis 6+ (optional, for background workers)

### Flutter Requirements
- Flutter SDK 3.10.7+ ([Installation Guide](https://docs.flutter.dev/get-started/install))
- Dart SDK (included with Flutter)
- Chrome (for web development)
- Android Studio / Xcode (for mobile development)

### Optional
- Docker and Docker Compose (for containerized setup)

---

## Backend Setup

### Option 1: Docker (Recommended)

```bash
# Navigate to project root
cd /path/to/project

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f app

# Run migrations
docker-compose exec app flask db upgrade

# Seed database
docker-compose exec app python scripts/seed_db.py

# Stop services
docker-compose down
```

The API will be available at `http://localhost:3000`.

### Option 2: Manual Setup

#### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate

# On Linux/Mac:
source venv/bin/activate
```

#### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

#### 3. Configure Environment

```bash
# Copy example env file
copy .env.example .env     # Windows
cp .env.example .env       # Linux/Mac

# Edit .env and configure:
# - DATABASE_URL (use SQLite for dev: sqlite:///hostelixpro.db)
# - SECRET_KEY (generate a secure random key)
# - JWT_SECRET_KEY
# - Email settings (see Email Configuration section below)
```

#### 4. Initialize Database

```bash
# Create database tables
flask db upgrade

# Or if migrations don't exist yet:
python
>>> from app import create_app, db
>>> app = create_app()
>>> with app.app_context():
>>>     db.create_all()
>>> exit()

# Seed sample data
python scripts/seed_db.py
```

#### 5. Run Development Server

```bash
python app.py
# or
flask run --port 3000

# API will be available at http://localhost:3000
```

#### 6. Test API

```bash
# Health check
curl http://localhost:3000/api/v1/health

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"student1@example.com\",\"password\":\"TestPass123\"}"

# Check console for OTP (if email not configured)
```

---

## Flutter Setup

### 1. Install Flutter SDK

Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install) for your operating system.

Verify installation:
```bash
flutter doctor
```

### 2. Get Dependencies

```bash
cd hostelixpro
flutter pub get
```

### 3. Configure API Endpoint

The API endpoint is configured in `lib/services/api_client.dart`:

```dart
static const String baseUrl = 'http://localhost:3000/api/v1';
```

**For mobile development**, change to your local IP:
```dart
static const String baseUrl = 'http://192.168.1.x:3000/api/v1';
```

### 4. Run Flutter App

#### Web
```bash
flutter run -d chrome
```

#### Android
```bash
# Connect device or start emulator
flutter devices

# Run on device
flutter run
```

#### iOS (Mac only)
```bash
# Open iOS simulator
open -a Simulator

# Run app
flutter run
```

#### Windows/Linux/Mac Desktop
```bash
# Enable desktop support (if not already enabled)
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
flutter config --enable-macos-desktop

# Run on desktop
flutter run -d windows
flutter run -d linux
flutter run -d macos
```

### 5. Login to App

Use sample credentials:
- **Email**: `student1@example.com`
- **Password**: `TestPass123`
- **OTP**: Check backend console output (if email not configured)

---

## 📧 Email Configuration

Hostelix Pro uses email for **OTP login verification** and **Forgot Password** features.

### Development Mode (No Email)

By default, email credentials are **not configured**. The system will:
- Print OTPs directly to the **backend console**
- Return success for all email operations
- Log messages like: `[DEV MODE] OTP for user@example.com: 123456`

This is ideal for local development and testing.

### Production Mode (Gmail SMTP)

To send real emails, edit `backend/.env`:

```ini
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_DEFAULT_SENDER=noreply@hostelixpro.com
```

#### Setting Up Gmail App Password

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** (if not already enabled)
3. Go to [App Passwords](https://myaccount.google.com/apppasswords)
4. Select **Mail** and **Windows Computer**
5. Click **Generate** and copy the 16-character password
6. Paste it as `MAIL_PASSWORD` in your `.env` file

> **Note:** Never commit your `.env` file to version control. It is already in `.gitignore`.

### Alternative SMTP Providers

| Provider    | MAIL_SERVER           | MAIL_PORT | Notes                    |
|-------------|-----------------------|-----------|--------------------------|
| Gmail       | smtp.gmail.com        | 587       | Requires App Password    |
| Outlook     | smtp-mail.outlook.com | 587       | Use account password     |
| SendGrid    | smtp.sendgrid.net     | 587       | Use API key as password  |
| Mailgun     | smtp.mailgun.org      | 587       | Use domain API key       |

---

## Troubleshooting

### Backend Issues

**Port already in use**
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

**Database connection errors**
- Check PostgreSQL is running
- Verify DATABASE_URL in .env
- For development, use SQLite: `DATABASE_URL=sqlite:///hostelixpro.db`

**Import errors**
```bash
# Reinstall dependencies
pip install --force-reinstall -r requirements.txt
```

### Flutter Issues

**HTTP errors on mobile**
- Use your local IP instead of `localhost`
- Add internet permission in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```

**Build errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Storage permission errors (Android)**
- The app uses `flutter_secure_storage` which requires no additional permissions
- If issues persist, check Android API compatibility

---

## Implemented Features

### Phase 1 (Complete)
- ✅ MFA Authentication (Email/Password + OTP)
- ✅ Role-Based Access Control (Admin/Teacher/RoutineManager/Student)
- ✅ Audit Logging & Account Lockout

### Phase 2 (Complete)
- ✅ Daily Reports workflow
- ✅ Routine Management (entry/exit tracking with approve/reject)
- ✅ Fee Submission & Management
- ✅ Announcements System
- ✅ Student Profiles & Activities

### Phase 3 (Complete)
- ✅ Backup/Restore functionality
- ✅ Forgot Password (Email OTP reset)
- ✅ Professional UI redesign (Login, Signup, OTP, Forgot Password)
- ✅ Dark/Light Mode support
- ✅ Settings Screen

---

## Database Migrations

### Create New Migration

```bash
cd backend

# Auto-generate migration from model changes
flask db migrate -m "description of changes"

# Review generated migration in alembic/versions/

# Apply migration
flask db upgrade
```

### Rollback Migration

```bash
# Rollback one step
flask db downgrade

# Rollback to specific version
flask db downgrade <revision_id>
```

---

## Production Deployment

### Docker Production

```bash
# Use production docker-compose file
docker-compose -f docker-compose.prod.yml up -d
```

### Manual Production

1. Set environment variables:
   ```
   FLASK_ENV=production
   DATABASE_URL=postgresql://user:pass@host:5432/dbname
   SECRET_KEY=<secure-random-key>
   JWT_SECRET_KEY=<secure-random-key>
   ```

2. Run with gunicorn:
   ```bash
   gunicorn --bind 0.0.0.0:3000 --workers 4 app:app
   ```

3. Build Flutter web:
   ```bash
   cd hostelixpro
   flutter build web
   # Deploy build/web/ to static hosting
   ```

---

## Useful Commands

### Backend
```bash
# Activate virtual environment
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Install new dependency
pip install <package>
pip freeze > requirements.txt

# Run shell
flask shell
```

### Flutter
```bash
# Format code
flutter format lib/

# Analyze code
flutter analyze

# Build for production
flutter build web
flutter build apk
flutter build ios
```

---

## Support

For issues or questions:
1. Check existing GitHub issues
2. Review error logs
3. Contact development team
