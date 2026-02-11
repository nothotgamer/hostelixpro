#!/usr/bin/env python
"""
Database seeding script
Creates sample users and data for development/testing
"""
import sys
import os

# Add backend directory to path to import app
# structure: project/scripts/seed_db.py -> project/backend/app
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from app import create_app, db
from app.models.user import User
from app.models.student import Student
from app.services.auth_service import AuthService


def seed_database():
    """
    Seed database with sample users and data
    
    creates:
    - 1 admin
    - 1 teacher
    - 1 routine manager
    - 5 students
    
    All passwords: TestPass123
    """
    app = create_app()
    
    with app.app_context():
        print('Starting database seed...')
        
        # Create tables if they don't exist
        db.create_all()
        
        # Check if already seeded
        if User.query.filter_by(email='admin@example.com').first():
            print('Database already seeded. Skipping.')
            return
        
        password_hash = AuthService.hash_password('TestPass123')
        
        # Create admin
        admin = User(
            email='admin@example.com',
            password_hash=password_hash,
            role='admin',
            display_name='System Administrator'
        )
        db.session.add(admin)
        print('✓ Created admin user: admin@example.com')
        
        # Create teacher
        teacher = User(
            email='teacher@example.com',
            password_hash=password_hash,
            role='teacher',
            display_name='Mr. Johnson'
        )
        db.session.add(teacher)
        db.session.flush()  # Get teacher ID
        print('✓ Created teacher user: teacher@example.com')
        
        # Create routine manager
        routine_manager = User(
            email='routine@example.com',
            password_hash=password_hash,
            role='routine_manager',
            display_name='Alice Brown'
        )
        db.session.add(routine_manager)
        print('✓ Created routine manager: routine@example.com')
        
        # Create students
        student_names = [
            ('student1@example.com', 'John Doe', 'A101', 'STU001'),
            ('student2@example.com', 'Jane Smith', 'A102', 'STU002'),
            ('student3@example.com', 'Mike Wilson', 'B201', 'STU003'),
            ('student4@example.com', 'Sarah Davis', 'B202', 'STU004'),
            ('student5@example.com', 'Tom Anderson', 'C301', 'STU005'),
        ]
        
        for email, name, room, admission_no in student_names:
            user = User(
                email=email,
                password_hash=password_hash,
                role='student',
                display_name=name
            )
            db.session.add(user)
            db.session.flush()  # Get user ID
            
            # Create student profile
            student = Student(
                user_id=user.id,
                assigned_teacher_id=teacher.id,
                room=room,
                admission_no=admission_no
            )
            db.session.add(student)
            print(f'✓ Created student: {email} (Room: {room})')
        
        # Commit all changes
        db.session.commit()
        
        print('\n' + '='*50)
        print('Database seeded successfully!')
        print('='*50)
        print('\nSample credentials (all use password: TestPass123):')
        print('  Admin:           admin@example.com')
        print('  Teacher:         teacher@example.com')
        print('  Routine Manager: routine@example.com')
        print('  Students:        student1@example.com through student5@example.com')
        print('='*50)


if __name__ == '__main__':
    seed_database()
