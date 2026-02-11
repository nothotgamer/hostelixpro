#!/usr/bin/env python
"""
Hostelix Pro - Initial Admin Setup Script

This script creates the first admin user for a new installation.
It can only be run ONCE - attempting to run it again will fail.

USAGE:
    cd backend
    python scripts/setup_admin.py
"""

import os
import sys
import getpass
import re

# Add parent directory to path for imports  
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load .env file
from dotenv import load_dotenv
load_dotenv()

from app import create_app, db
from app.models.user import User
from werkzeug.security import generate_password_hash


def validate_email(email):
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def validate_password(password):
    """Password must be at least 8 chars with letters and numbers"""
    if len(password) < 8:
        return False, "Password must be at least 8 characters"
    if not re.search(r'[A-Za-z]', password):
        return False, "Password must contain at least one letter"
    if not re.search(r'[0-9]', password):
        return False, "Password must contain at least one number"
    return True, "OK"


def main():
    print("=" * 50)
    print("  HOSTELIX PRO - Initial Admin Setup")
    print("=" * 50)
    print()
    
    # Create Flask app context
    app = create_app()
    
    with app.app_context():
        # Security Check: Check if admin already exists
        existing_admin = User.query.filter_by(role='admin').first()
        if existing_admin:
            print("❌ ERROR: An admin user already exists!")
            print(f"   Email: {existing_admin.email}")
            print()
            print("This script can only be run once during initial setup.")
            print("To add more admins, use the admin panel.")
            sys.exit(1)
        
        print("No existing admin found. Let's create one!")
        print()
        
        # Get admin details
        while True:
            email = input("Admin email: ").strip().lower()
            if validate_email(email):
                # Check if email already exists
                if User.query.filter_by(email=email).first():
                    print("   ⚠ This email is already registered. Try another.")
                    continue
                break
            print("   ⚠ Invalid email format. Try again.")
        
        display_name = input("Admin name: ").strip()
        if not display_name:
            display_name = "Administrator"
        
        while True:
            password = getpass.getpass("Password (min 8 chars, letters + numbers): ")
            valid, msg = validate_password(password)
            if not valid:
                print(f"   ⚠ {msg}")
                continue
            
            password_confirm = getpass.getpass("Confirm password: ")
            if password != password_confirm:
                print("   ⚠ Passwords do not match. Try again.")
                continue
            break
        
        print()
        print("-" * 40)
        print("Creating admin account...")
        
        # Create the admin user
        from app.services.time_service import TimeService
        
        admin_user = User(
            email=email,
            password_hash=generate_password_hash(password),
            display_name=display_name,
            role='admin',
            is_approved=True,
            created_at=TimeService.now_ms()
        )
        
        db.session.add(admin_user)
        db.session.commit()
        
        print()
        print("=" * 50)
        print("  ✓ ADMIN ACCOUNT CREATED SUCCESSFULLY!")
        print("=" * 50)
        print()
        print(f"  Email:    {email}")
        print(f"  Name:     {display_name}")
        print(f"  Role:     admin")
        print()
        print("  You can now log in to the Hostelix Pro dashboard.")
        print()
        print("-" * 50)
        print("TIP: Delete this script after setup for security!")
        print("-" * 50)


if __name__ == '__main__':
    main()

