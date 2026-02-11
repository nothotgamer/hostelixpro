# Hostelix Pro - Hostel Management System

A role-enforced, audit-compliant hostel discipline management system with server-time-authority and mandatory MFA.

## Key Features

### Phase 1 (Complete)
- ✅ **Email + Password + OTP Authentication (MFA)**
- ✅ **Role-Based Access Control (RBAC)**: Admin, Teacher, RoutineManager, Student
- ✅ **Server-Authoritative Timestamps** (no client-side date/time input)
- ✅ **Comprehensive Audit Logging**
- ✅ **Secure Token Management (JWT)**
- ✅ **Account Lockout** after failed attempts
- ✅ **Flutter Web & Mobile Support**

### Coming in Phase 2
- Student daily report workflow (Wake up → Teacher → Admin)
- Routine management: morning walk, exit request, return confirmation
- Fee submission → Admin approval (immutable when approved)
- Announcements (Admin→All, Teacher→Students)

### Coming in Phase 3
- Backup & Restore with encrypted backup files
- Export reports to PDF / Excel
- Exportable audit logs
- Admin audit UI with filters

## Tech Stack

### Backend
- **Framework**: Flask (Python 3.10+)
- **Database**: PostgreSQL (or SQLite for dev)
- **ORM**: SQLAlchemy + Alembic migrations
- **Auth**: bcrypt password hashing, PyOTP for MFA, JWT tokens
- **API**: REST JSON API
- **Container**: Docker + Docker Compose

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Routing**: GoRouter
- **HTTP Client**: http package
- **Secure Storage**: flutter_secure_storage for JWT tokens
- **Platforms**: Web, Android, iOS, Desktop

## Quick Start

### Using Docker (Recommended)

```bash
# Start all services (API, PostgreSQL, Redis)
docker-compose up -d

# Run database migrations
docker-compose exec app flask db upgrade

# Seed sample data
docker-compose exec app python scripts/seed_db.py

# Access API at: http://localhost:3000
# API health check: http://localhost:3000/api/v1/health
```

### Manual Setup

See [docs/DEV_SETUP.md](docs/DEV_SETUP.md) for detailed setup instructions.

## Sample Credentials

After seeding the database:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@example.com | TestPass123 |
| Teacher | teacher@example.com | TestPass123 |
| Routine Manager | routine@example.com | TestPass123 |
| Student 1-5 | student1@example.com ... student5@example.com | TestPass123 |

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - Email/password login
- `POST /api/v1/auth/verify-otp` - OTP verification
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/me` - Get current user

### Users (Admin only)
- `GET /api/v1/users` - List users
- `POST /api/v1/users` - Create user
- `GET /api/v1/users/:id` - Get user details

### Health
- `GET /api/v1/health` - Server health check with timestamp

## Architecture

- **Server-Time Authority**: All timestamps generated server-side (Unix epoch ms)
- **MFA Flow**: Login → Email/password verification → OTP sent via email → OTP verification → JWT token
- **Audit Trail**: Every action logged (user, timestamp, IP, device, action, entity)
- **Security**: bcrypt password hashing (12 rounds), JWT with HS256, account lockout after 5 failed attempts

## Project Structure

```
project/
├── backend/
│   ├── app/
│   │   ├── api/          # API endpoints (blueprints)
│   │   ├── models/       # SQLAlchemy models
│   │   ├── services/     # Business logic
│   │   └── utils/        # Decorators, helpers
│   ├── app.py            # Flask entry point
│   ├── requirements.txt  # Python dependencies
│   └── Dockerfile        # Backend container
├── hostelixpro/
│   └── lib/
│       ├── models/       # Dart models
│       ├── services/     # API client, auth service
│       ├── providers/    # State management
│       └── pages/        # UI pages
├── scripts/
│   └── seed_db.py        # Database seeding
├── docker-compose.yml    # Multi-container setup
└── docs/
    ├── README.md (this file)
    └── DEV_SETUP.md      # Development setup guide
```

## Development

### Backend
```bash
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
flask run --port 3000
```

### Flutter
```bash
cd hostelixpro
flutter pub get
flutter run -d chrome  # for web
flutter run            # for mobile
```

## Testing

```bash
# Backend tests (coming soon)
cd backend
pytest

# Flutter tests
cd hostelixpro
flutter test
```

## License

Private project - All rights reserved

## Support

For issues or questions, contact the development team.
