#!/usr/bin/env python
"""
═══════════════════════════════════════════════════════════════
  Hostelix Pro — Admin Account Setup
═══════════════════════════════════════════════════════════════
  Interactive script to create admin user accounts.
  Run this after creating a fresh database.

  Usage:
    python admin_setup.py               (interactive mode)
    python admin_setup.py --quick       (quick setup with defaults)
    python admin_setup.py --reset       (full reset: delete DB + recreate + admin)
    python admin_setup.py --list        (list existing admin accounts)

  Requirements:
    - Virtual environment activated
    - .env file configured
═══════════════════════════════════════════════════════════════
"""
import sys
import os
import re
import getpass
import glob


# ─── Validation ───────────────────────────────────────────────
def validate_email(email):
    """Basic email format validation"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def validate_password(password):
    """
    Password requirements:
    - At least 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 digit
    """
    if len(password) < 8:
        return False, "Password must be at least 8 characters"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least 1 uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least 1 lowercase letter"
    if not re.search(r'\d', password):
        return False, "Password must contain at least 1 digit"
    return True, "OK"


# ─── Database Reset ──────────────────────────────────────────
def find_all_db_files():
    """Find all hostelixpro.db files in the backend directory"""
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    found = []
    for root, dirs, files in os.walk(backend_dir):
        for f in files:
            if f == 'hostelixpro.db':
                found.append(os.path.join(root, f))
    return found


def reset_database():
    """Delete all database files and recreate tables"""
    print()
    print("═" * 55)
    print("  HOSTELIX PRO — Full Database Reset")
    print("═" * 55)
    print()

    # Find all DB files
    db_files = find_all_db_files()

    if db_files:
        print("  Found database file(s):")
        for f in db_files:
            size_kb = os.path.getsize(f) / 1024
            print(f"    • {f}  ({size_kb:.0f} KB)")
    else:
        print("  No existing database files found.")

    print()
    print("  ⚠  This will PERMANENTLY DELETE all data:")
    print("     - All user accounts (admin, teacher, student)")
    print("     - All usernames and passwords")
    print("     - All fees, reports, routines, announcements")
    print("     - All audit logs and backups")
    print()

    confirm = input("  Are you sure? Type 'yes' to confirm: ").strip().lower()
    if confirm != 'yes':
        print("\n  Reset cancelled. No data was deleted.")
        return False

    # Delete all found DB files
    for f in db_files:
        try:
            os.remove(f)
            print(f"  ✓ Deleted: {f}")
        except Exception as e:
            print(f"  ✗ Failed to delete {f}: {e}")
            print("    Make sure the backend server is STOPPED first!")
            return False

    # Also check and delete common locations
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    extra_paths = [
        os.path.join(backend_dir, 'hostelixpro.db'),
        os.path.join(backend_dir, 'instance', 'hostelixpro.db'),
    ]
    for p in extra_paths:
        if os.path.exists(p) and p not in db_files:
            try:
                os.remove(p)
                print(f"  ✓ Deleted: {p}")
            except Exception as e:
                print(f"  ✗ Failed to delete {p}: {e}")

    print()
    print("  All database files deleted.")
    print()

    # Recreate tables
    print("─" * 55)
    print("  Recreating database tables...")
    print("─" * 55)

    from app import create_app, db
    app = create_app()
    with app.app_context():
        db.create_all()
        print("  ✓ All 11 tables created successfully!")
    print()

    # Run interactive admin setup
    print("─" * 55)
    print("  Now set up your admin account:")
    print("─" * 55)
    interactive_setup()
    return True


# ─── Admin Creation ──────────────────────────────────────────
def create_admin(email, password, display_name):
    """Create an admin user in the database"""
    from app import create_app, db
    from app.models.user import User
    from app.services.auth_service import AuthService

    app = create_app()

    with app.app_context():
        # Check if tables exist
        db.create_all()

        # Check if email already exists
        existing = User.query.filter_by(email=email).first()
        if existing:
            print(f"\n  ✗ Error: A user with email '{email}' already exists!")
            print(f"    Role: {existing.role}")
            print(f"    Name: {existing.display_name}")

            choice = input("\n  Do you want to update this user to admin? (y/n): ").strip().lower()
            if choice == 'y':
                existing.role = 'admin'
                existing.is_approved = True
                existing.is_locked = False
                existing.password_hash = AuthService.hash_password(password)
                existing.display_name = display_name
                db.session.commit()
                print(f"\n  ✓ User '{email}' updated to admin role!")
                return True
            else:
                print("  Skipped.")
                return False

        # Create new admin user
        admin = User(
            email=email,
            password_hash=AuthService.hash_password(password),
            role='admin',
            display_name=display_name,
            is_approved=True,
            is_locked=False
        )
        db.session.add(admin)
        db.session.commit()

        print(f"\n  ✓ Admin account created successfully!")
        print(f"    ID:    {admin.id}")
        print(f"    Email: {admin.email}")
        print(f"    Name:  {admin.display_name}")
        return True


# ─── Interactive Mode ────────────────────────────────────────
def interactive_setup():
    """Interactive admin setup with user prompts"""
    print()
    print("═" * 55)
    print("  HOSTELIX PRO — Admin Account Setup")
    print("═" * 55)
    print()
    print("  This will create an admin account for the system.")
    print("  Admin users have full access to all features.")
    print()
    print("─" * 55)

    # Get email
    while True:
        email = input("\n  Enter admin email: ").strip()
        if not email:
            print("  ✗ Email cannot be empty")
            continue
        if not validate_email(email):
            print("  ✗ Invalid email format")
            continue
        break

    # Get display name
    while True:
        name = input("  Enter display name: ").strip()
        if not name:
            print("  ✗ Display name cannot be empty")
            continue
        if len(name) < 2:
            print("  ✗ Name must be at least 2 characters")
            continue
        break

    # Get password
    while True:
        print()
        print("  Password requirements:")
        print("    • At least 8 characters")
        print("    • At least 1 uppercase letter (A-Z)")
        print("    • At least 1 lowercase letter (a-z)")
        print("    • At least 1 digit (0-9)")
        print()

        password = getpass.getpass("  Enter password: ")
        valid, msg = validate_password(password)
        if not valid:
            print(f"  ✗ {msg}")
            continue

        confirm = getpass.getpass("  Confirm password: ")
        if password != confirm:
            print("  ✗ Passwords do not match")
            continue
        break

    # Confirm
    print()
    print("─" * 55)
    print(f"  Email:   {email}")
    print(f"  Name:    {name}")
    print(f"  Role:    admin")
    print("─" * 55)

    choice = input("\n  Create this admin account? (y/n): ").strip().lower()
    if choice != 'y':
        print("\n  Setup cancelled.")
        return

    create_admin(email, password, name)

    # Ask if they want to create another
    print()
    another = input("  Create another admin account? (y/n): ").strip().lower()
    if another == 'y':
        interactive_setup()
    else:
        print()
        print("═" * 55)
        print("  Setup complete! You can now log in to the app.")
        print("═" * 55)
        print()


# ─── Quick Mode ──────────────────────────────────────────────
def quick_setup():
    """Quick setup with default admin credentials"""
    print()
    print("═" * 55)
    print("  HOSTELIX PRO — Quick Admin Setup")
    print("═" * 55)
    print()
    print("  Creating default admin account...")
    print()

    success = create_admin(
        email='admin@hostelixpro.com',
        password='Admin@1234',
        display_name='System Administrator'
    )

    if success:
        print()
        print("─" * 55)
        print("  DEFAULT ADMIN CREDENTIALS:")
        print("─" * 55)
        print("  Email:    admin@hostelixpro.com")
        print("  Password: Admin@1234")
        print("─" * 55)
        print()
        print("  ⚠  IMPORTANT: Change this password after first login!")
        print()


# ─── List Existing Admins ────────────────────────────────────
def list_admins():
    """Show all current admin accounts"""
    from app import create_app, db
    from app.models.user import User

    app = create_app()

    with app.app_context():
        admins = User.query.filter_by(role='admin').all()

        print()
        print("═" * 55)
        print("  Current Admin Accounts")
        print("═" * 55)

        if not admins:
            print("\n  No admin accounts found.")
        else:
            for a in admins:
                locked = " [LOCKED]" if a.is_locked else ""
                approved = "" if a.is_approved else " [NOT APPROVED]"
                print(f"\n  ID: {a.id}")
                print(f"    Email: {a.email}")
                print(f"    Name:  {a.display_name}{locked}{approved}")

        print()
        print(f"  Total: {len(admins)} admin(s)")
        print("═" * 55)

        # Also show DB file location
        db_files = find_all_db_files()
        if db_files:
            print()
            print("  Database file(s):")
            for f in db_files:
                size_kb = os.path.getsize(f) / 1024
                print(f"    • {f}  ({size_kb:.0f} KB)")
        print()


# ─── Main ────────────────────────────────────────────────────
def main():
    if len(sys.argv) > 1:
        flag = sys.argv[1].lower()
        if flag == '--quick':
            quick_setup()
        elif flag == '--list':
            list_admins()
        elif flag == '--reset':
            reset_database()
        elif flag in ('--help', '-h'):
            print()
            print("  Hostelix Pro — Admin Account Setup")
            print()
            print("  Usage:")
            print("    python admin_setup.py           Interactive admin setup")
            print("    python admin_setup.py --quick    Create default admin account")
            print("    python admin_setup.py --reset    Full reset (delete DB + recreate + admin)")
            print("    python admin_setup.py --list     List all admin accounts")
            print("    python admin_setup.py --help     Show this help")
            print()
            print("  Database location: backend/instance/hostelixpro.db")
            print()
        else:
            print(f"  Unknown option: {flag}")
            print("  Use --help for usage information")
    else:
        interactive_setup()


if __name__ == '__main__':
    main()
