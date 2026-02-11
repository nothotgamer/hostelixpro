"""
Account API endpoints (Self-service for logged-in user)
- Get/Update Profile
- Change Password
- 2FA Setup/Verify/Disable
"""
import pyotp
import base64
import io
import qrcode
from flask import request, jsonify
from app.api import account_bp
from app import db
from app.models.user import User
from app.models.audit_log import AuditLog
from app.services.auth_service import AuthService
from app.utils.decorators import token_required


@account_bp.route('/profile', methods=['GET'])
@token_required
def get_profile():
    """Get current user's profile"""
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200


@account_bp.route('/profile', methods=['PATCH'])
@token_required
def update_profile():
    """
    Update current user's profile
    
    Request:
        {
            "display_name": "New Name",
            "email": "newemail@example.com"
        }
    """
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    data = request.get_json() or {}
    
    if 'display_name' in data:
        user.display_name = data['display_name']
    
        if existing:
            return jsonify({'error': 'Email already taken'}), 409
        user.email = data['email'].lower()
    
    if 'bio' in data:
        user.bio = data['bio']
    
    if 'skills' in data:
        user.skills = data['skills']
        
    if 'status_message' in data:
        user.status_message = data['status_message']
    
    AuditLog.log(
        user_id=user_id,
        action='UPDATE_PROFILE',
        entity='user',
        entity_id=user_id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify({'message': 'Profile updated', 'user': user.to_dict()}), 200


@account_bp.route('/password', methods=['POST'])
@token_required
def change_password():
    """
    Change current user's password
    
    Request:
        {
            "current_password": "OldPass123",
            "new_password": "NewPass456"
        }
    """
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    data = request.get_json()
    
    if not data or 'current_password' not in data or 'new_password' not in data:
        return jsonify({'error': 'current_password and new_password are required'}), 400
    
    # Verify current password
    if not AuthService.verify_password(data['current_password'], user.password_hash):
        return jsonify({'error': 'Current password is incorrect'}), 401
    
    # Validate new password
    if len(data['new_password']) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400
    
    # Update password
    user.password_hash = AuthService.hash_password(data['new_password'])
    
    AuditLog.log(
        user_id=user_id,
        action='CHANGE_PASSWORD',
        entity='user',
        entity_id=user_id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify({'message': 'Password changed successfully'}), 200


@account_bp.route('/2fa/setup', methods=['POST'])
@token_required
def setup_2fa():
    """
    Generate 2FA secret and QR code
    
    Response:
        {
            "secret": "BASE32SECRET",
            "qr_code": "data:image/png;base64,..."
        }
    """
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    if user.mfa_enabled:
        return jsonify({'error': '2FA is already enabled'}), 400
    
    # Generate secret
    secret = pyotp.random_base32()
    
    # Store secret (not enabled yet until verified)
    user.mfa_secret = secret
    db.session.commit()
    
    # Generate OTP URI for authenticator apps
    totp = pyotp.TOTP(secret)
    uri = totp.provisioning_uri(name=user.email, issuer_name='Hostelix')
    
    # Generate QR code
    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color='black', back_color='white')
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    qr_base64 = base64.b64encode(buffer.getvalue()).decode()
    
    return jsonify({
        'secret': secret,
        'qr_code': f'data:image/png;base64,{qr_base64}'
    }), 200


@account_bp.route('/2fa/verify', methods=['POST'])
@token_required
def verify_2fa():
    """
    Verify 2FA code and enable 2FA
    
    Request:
        {
            "code": "123456"
        }
    """
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    if not user.mfa_secret:
        return jsonify({'error': 'No 2FA setup in progress. Call /2fa/setup first'}), 400
    
    data = request.get_json()
    
    if not data or 'code' not in data:
        return jsonify({'error': 'code is required'}), 400
    
    # Verify code
    totp = pyotp.TOTP(user.mfa_secret)
    if not totp.verify(str(data['code'])):
        return jsonify({'error': 'Invalid verification code'}), 401
    
    # Enable 2FA
    user.mfa_enabled = True
    
    AuditLog.log(
        user_id=user_id,
        action='ENABLE_2FA',
        entity='user',
        entity_id=user_id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify({'message': '2FA enabled successfully'}), 200


@account_bp.route('/2fa/disable', methods=['POST'])
@token_required
def disable_2fa():
    """
    Disable 2FA (requires current password)
    
    Request:
        {
            "password": "CurrentPassword123"
        }
    """
    user_id = request.current_user.get('user_id')
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    if not user.mfa_enabled:
        return jsonify({'error': '2FA is not enabled'}), 400
    
    data = request.get_json()
    
    if not data or 'password' not in data:
        return jsonify({'error': 'password is required'}), 400
    
    # Verify password
    if not AuthService.verify_password(data['password'], user.password_hash):
        return jsonify({'error': 'Incorrect password'}), 401
    
    # Disable 2FA
    user.mfa_enabled = False
    user.mfa_secret = None
    
    AuditLog.log(
        user_id=user_id,
        action='DISABLE_2FA',
        entity='user',
        entity_id=user_id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify({'message': '2FA disabled successfully'}), 200
