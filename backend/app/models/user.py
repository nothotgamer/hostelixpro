"""
User model for authentication and role-based access control
"""
from app import db
from app.models.base import BaseModel
import time


class User(BaseModel):
    """
    User model with RBAC support
    Roles: admin, teacher, routine_manager, student
    """
    __tablename__ = 'users'
    
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.Text, nullable=False)
    display_name = db.Column(db.String(255))
    role = db.Column(
        db.String(50), 
        nullable=False,
        index=True
    )
    is_locked = db.Column(db.Boolean, default=False, nullable=False)
    is_approved = db.Column(db.Boolean, default=True, nullable=False)  # Default True for existing, False for new
    mfa_enabled = db.Column(db.Boolean, default=False, nullable=False)
    mfa_secret = db.Column(db.String(32))  # TOTP secret key
    failed_login_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.BigInteger)  # Unix epoch ms
    last_login_at = db.Column(db.BigInteger)
    
    # Profile fields
    bio = db.Column(db.Text)
    skills = db.Column(db.Text)  # Comma-separated or JSON string
    status_message = db.Column(db.String(255))
    
    # Relationships
    student_profile = db.relationship(
        'Student', 
        backref='user', 
        uselist=False, 
        cascade='all, delete-orphan',
        foreign_keys='Student.user_id'
    )
    audit_logs = db.relationship('AuditLog', backref='user', lazy='dynamic')
    
    # Constraints
    __table_args__ = (
        db.CheckConstraint(
            role.in_(['admin', 'teacher', 'routine_manager', 'student']),
            name='check_valid_role'
        ),
    )
    
    def to_dict(self, include_sensitive=False):
        """Convert user to dictionary"""
        data = {
            'id': self.id,
            'email': self.email,
            'display_name': self.display_name,
            'role': self.role,
            'is_locked': self.is_locked,
            'is_approved': self.is_approved,
            'mfa_enabled': self.mfa_enabled,
            'last_login_at': self.last_login_at,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'bio': self.bio,
            'skills': self.skills,
            'status_message': self.status_message
        }
        
        if include_sensitive:
            data['failed_login_attempts'] = self.failed_login_attempts
            data['locked_until'] = self.locked_until
            
        # Include student profile if user is student
        if self.role == 'student' and self.student_profile:
            data['student_profile'] = self.student_profile.to_dict()
        
        return data
    
    def is_account_locked(self):
        """Check if account is currently locked"""
        if not self.is_locked and self.locked_until:
            current_time = int(time.time() * 1000)
            if current_time < self.locked_until:
                return True
            else:
                # Lock period expired, reset
                self.locked_until = None
                self.failed_login_attempts = 0
        return self.is_locked
    
    def record_failed_login(self, max_attempts=5, lockout_duration_seconds=1800):
        """Record failed login attempt and lock if needed"""
        self.failed_login_attempts += 1
        
        if self.failed_login_attempts >= max_attempts:
            # Lock account for specified duration
            self.locked_until = int(time.time() * 1000) + (lockout_duration_seconds * 1000)
    
    def record_successful_login(self):
        """Record successful login and reset failed attempts"""
        self.last_login_at = int(time.time() * 1000)
        self.failed_login_attempts = 0
        self.locked_until = None
    
    def __repr__(self):
        return f'<User {self.email} ({self.role})>'
