"""
Authentication API endpoints
POST /api/v1/auth/login - Email/password login, generate OTP
POST /api/v1/auth/verify-otp - Verify OTP, return JWT token
POST /api/v1/auth/logout - Logout (invalidate session)
"""
from flask import request, jsonify
from app.api import auth_bp
from app import db
from app.models.user import User
from app.models.student import Student
from app.models.audit_log import AuditLog
from app.services.auth_service import AuthService
from app.services.email_service import EmailService
from app.utils.decorators import validate_json, token_required
from sqlalchemy import cast, String
import uuid
import os


@auth_bp.route('/register', methods=['POST'])
@validate_json('email', 'password', 'display_name')
def register():
    """
    Public registration endpoint
    Creates a new user with is_approved=False
    """
    data = request.get_json()
    email = data['email'].lower().strip()
    
    # Check if user exists
    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'Email already exists'}), 409
        
    # Create User
    user = User(
        email=email,
        password_hash=AuthService.hash_password(data['password']),
        display_name=data['display_name'],
        role='student', # Default to student for public registration
        is_approved=False # Requires admin approval
    )
    
    db.session.add(user)
    db.session.flush()
    
    # Create empty Student profile
    student = Student(user_id=user.id)
    db.session.add(student)
    
    # Audit Log
    AuditLog.log(
        user_id=None,
        action='REGISTER_REQUEST',
        entity='user',
        entity_id=user.id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent', ''),
        details={'email': email}
    )
    
    db.session.commit()
    
    return jsonify({
        'message': 'Registration successful. Please wait for Admin approval.',
        'user_id': user.id
    }), 201


@auth_bp.route('/login', methods=['POST'])
@validate_json('email', 'password')
def login():
    """
    Step 1 of MFA login: Verify email/password and send OTP
    
    Request:
        {
            "email": "user@example.com",
            "password": "password123"
        }
    
    Response:
        {
            "tx_id": "uuid",
            "otp_sent": true,
            "message": "OTP sent to email"
        }
    """
    data = request.get_json()
    email = data['email'].lower().strip()
    password = data['password']
    
    ip = request.remote_addr
    device = request.headers.get('User-Agent', '')
    
    # Find user by email
    user = User.query.filter_by(email=email).first()
    
    if not user:
        # Log failed attempt (no user found)
        AuditLog.log(
            user_id=None,
            action='LOGIN_FAILED',
            entity='user',
            ip=ip,
            device=device,
            details={'reason': 'user_not_found', 'email': email}
        )
        db.session.commit()
        
        # Return generic error to avoid user enumeration
        return jsonify({'error': 'Invalid email or password'}), 401
    
    # Check if account is locked
    if user.is_account_locked():
        AuditLog.log(
            user_id=user.id,
            action='LOGIN_BLOCKED',
            entity='user',
            ip=ip,
            device=device,
            details={'reason': 'account_locked'}
        )
        db.session.commit()
        
        return jsonify({'error': 'Account is locked. Please try again later.'}), 403

    # Check if account is approved
    if not user.is_approved:
         AuditLog.log(
            user_id=user.id,
            action='LOGIN_BLOCKED',
            entity='user',
            ip=ip,
            device=device,
            details={'reason': 'account_not_approved'}
        )
         db.session.commit()
         return jsonify({'error': 'Account pending approval. Please contact Admin.'}), 403
    
    # Verify password
    if not AuthService.verify_password(password, user.password_hash):
        # Record failed login attempt
        max_attempts = int(os.getenv('MAX_FAILED_LOGIN_ATTEMPTS', 5))
        lockout_duration = int(os.getenv('ACCOUNT_LOCKOUT_DURATION_SECONDS', 1800))
        
        user.record_failed_login(max_attempts, lockout_duration)
        
        AuditLog.log(
            user_id=user.id,
            action='LOGIN_FAILED',
            entity='user',
            ip=ip,
            device=device,
            details={'reason': 'invalid_password'}
        )
        db.session.commit()
        
        return jsonify({'error': 'Invalid email or password'}), 401
    
    # Password verified - generate JWT token directly (OTP removed)
    jwt_expiry_hours = int(os.getenv('JWT_EXPIRY_HOURS', 24))
    token, expiry_ms = AuthService.generate_jwt_token(
        user_id=user.id,
        role=user.role,
        expiry_hours=jwt_expiry_hours
    )
    
    # Record successful login
    user.record_successful_login()
    
    AuditLog.log(
        user_id=user.id,
        action='LOGIN_SUCCESS',
        entity='user',
        ip=ip,
        device=device
    )
    db.session.commit()
    
    return jsonify({
        'token': token,
        'expires_at': expiry_ms,
        'user': user.to_dict()
    }), 200


@auth_bp.route('/logout', methods=['POST'])
@token_required
def logout():
    """
    Logout endpoint (invalidate session)
    Currently just logs the action; token invalidation would be handled by Redis blacklist
    
    Response:
        {
            "message": "Logged out successfully"
        }
    """
    user_id = request.current_user.get('user_id')
    ip = request.remote_addr
    device = request.headers.get('User-Agent', '')
    
    AuditLog.log(
        user_id=user_id,
        action='LOGOUT',
        entity='user',
        ip=ip,
        device=device
    )
    db.session.commit()
    
    return jsonify({'message': 'Logged out successfully'}), 200


@auth_bp.route('/me', methods=['GET'])
@token_required
def get_current_user():
    """
    Get current authenticated user info
    
    Response:
        {
            "id": 1,
            "email": "user@example.com",
            "role": "student",
            "display_name": "John Doe"
        }
    """
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200


@auth_bp.route('/forgot-password', methods=['POST'])
@validate_json('email')
def forgot_password():
    """
    Initiate password reset flow
    Request: {"email": "user@example.com"}
    Response: {"tx_id": "uuid", "message": "Reset code sent"}
    """
    data = request.get_json()
    email = data['email'].lower().strip()
    
    user = User.query.filter_by(email=email).first()
    
    # We always return 200 even if user doesn't exist to prevent enumeration
    if not user:
        # Fake delay to match processing time? Optional.
        return jsonify({
            'message': 'If an account exists with this email, a reset code has been sent.',
            'tx_id': str(uuid.uuid4()) # Fake TX ID
        }), 200
        
    # Generate OTP
    tx_id = str(uuid.uuid4())
    otp = AuthService.generate_otp(6)
    AuthService.store_otp(tx_id, otp, 600) # 10 minutes expiry
    
    # Send Email
    EmailService.send_password_reset_email(user.email, otp, user.display_name)
    
    # Log request - crucial for linking tx_id to user_id for step 2
    AuditLog.log(
        user_id=user.id,
        action='PASSWORD_RESET_REQUEST',
        entity='user',
        ip=request.remote_addr,
        device=request.headers.get('User-Agent', ''),
        details={'tx_id': tx_id}
    )
    db.session.commit()
    
    return jsonify({
        'tx_id': tx_id,
        'message': 'If an account exists with this email, a reset code has been sent.'
    }), 200


@auth_bp.route('/reset-password', methods=['POST'])
@validate_json('tx_id', 'otp', 'new_password')
def reset_password():
    """
    Complete password reset
    Request: {"tx_id": "...", "otp": "...", "new_password": "..."}
    """
    data = request.get_json()
    tx_id = data['tx_id']
    otp = data['otp']
    new_password = data['new_password']
    
    # Verify OTP
    success, error = AuthService.verify_otp(tx_id, otp)
    if not success:
        return jsonify({'error': error}), 400
        
    # Find User from AuditLog
    # Look for PASSWORD_RESET_REQUEST with this tx_id
    logs = AuditLog.query.filter_by(action='PASSWORD_RESET_REQUEST').order_by(AuditLog.timestamp.desc()).limit(100).all()
    target_log = None
    for log in logs:
        if log.details_json and log.details_json.get('tx_id') == tx_id:
            target_log = log
            break
            
    if not target_log or not target_log.user_id:
        return jsonify({'error': 'Invalid reset transaction'}), 400
        
    user = User.query.get(target_log.user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
        
    # Update Password
    user.password_hash = AuthService.hash_password(new_password)
    # Unlock account if locked
    user.is_locked = False
    user.locked_until = None
    user.failed_login_attempts = 0
    
    # Log success
    AuditLog.log(
        user_id=user.id,
        action='PASSWORD_RESET_SUCCESS',
        entity='user',
        ip=request.remote_addr,
        device=request.headers.get('User-Agent', '')
    )
    db.session.commit()
    
    return jsonify({'message': 'Password has been reset successfully.'}), 200
