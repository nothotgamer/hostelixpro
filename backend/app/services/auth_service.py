"""
Authentication service for password hashing, OTP, and JWT tokens
"""
import bcrypt
import pyotp
import jwt
import os
import secrets
import string
from datetime import datetime, timedelta
from app.services.time_service import TimeService


class AuthService:
    """
    Authentication service handling:
    - Password hashing and verification (bcrypt)
    - OTP generation and verification
    - JWT token generation and validation
    """
    
    # OTP storage (in-memory for development, use Redis in production)
    _otp_store = {}
    
    @staticmethod
    def hash_password(password):
        """
        Hash password using bcrypt with 12 rounds
        
        Args:
            password: Plain text password
            
        Returns:
            Hashed password as string
        """
        salt = bcrypt.gensalt(rounds=12)
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')
    
    @staticmethod
    def verify_password(password, password_hash):
        """
        Verify password against hash
        
        Args:
            password: Plain text password to verify
            password_hash: Stored password hash
            
        Returns:
            True if password matches, False otherwise
        """
        return bcrypt.checkpw(
            password.encode('utf-8'),
            password_hash.encode('utf-8')
        )
    
    @staticmethod
    def generate_otp(length=6):
        """
        Generate random numeric OTP
        
        Args:
            length: Length of OTP (default 6)
            
        Returns:
            OTP string
        """
        return ''.join(secrets.choice(string.digits) for _ in range(length))
    
    @staticmethod
    def store_otp(tx_id, otp, expiry_seconds=300):
        """
        Store OTP hash and expiry for transaction
        
        Args:
            tx_id: Transaction ID (UUID)
            otp: OTP to store (will be hashed)
            expiry_seconds: OTP validity duration
            
        Returns:
            Expiry timestamp in milliseconds
        """
        otp_hash = AuthService.hash_password(otp)
        expiry_ms = TimeService.now_ms() + (expiry_seconds * 1000)
        
        AuthService._otp_store[tx_id] = {
            'otp_hash': otp_hash,
            'expiry_ms': expiry_ms,
            'attempts': 0
        }
        
        return expiry_ms
    
    @staticmethod
    def verify_otp(tx_id, otp, max_attempts=3):
        """
        Verify OTP for transaction
        
        Args:
            tx_id: Transaction ID
            otp: OTP to verify
            max_attempts: Maximum verification attempts
            
        Returns:
            (success: bool, error_message: str)
        """
        if tx_id not in AuthService._otp_store:
            return False, 'Invalid or expired OTP transaction'
        
        otp_data = AuthService._otp_store[tx_id]
        
        # Check expiry
        current_time = TimeService.now_ms()
        if current_time > otp_data['expiry_ms']:
            del AuthService._otp_store[tx_id]
            return False, 'OTP has expired'
        
        # Check attempts
        if otp_data['attempts'] >= max_attempts:
            del AuthService._otp_store[tx_id]
            return False, 'Too many failed attempts'
        
        # Verify OTP
        is_valid = AuthService.verify_password(otp, otp_data['otp_hash'])
        
        if is_valid:
            # Success - remove from store
            del AuthService._otp_store[tx_id]
            return True, None
        else:
            # Failed attempt
            otp_data['attempts'] += 1
            return False, 'Invalid OTP'
    
    @staticmethod
    def generate_jwt_token(user_id, role, expiry_hours=24):
        """
        Generate JWT token for authenticated user
        
        Args:
            user_id: User ID
            role: User role
            expiry_hours: Token validity in hours
            
        Returns:
            (token: str, expiry_ms: int)
        """
        secret_key = os.getenv('JWT_SECRET_KEY', 'jwt-secret-change-me')
        expiry_time = datetime.utcnow() + timedelta(hours=expiry_hours)
        expiry_ms = int(expiry_time.timestamp() * 1000)
        
        payload = {
            'user_id': user_id,
            'role': role,
            'exp': expiry_time,
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(payload, secret_key, algorithm='HS256')
        return token, expiry_ms
    
    @staticmethod
    def verify_jwt_token(token):
        """
        Verify and decode JWT token
        
        Args:
            token: JWT token string
            
        Returns:
            (payload: dict, error: str) - payload if valid, error message if invalid
        """
        try:
            secret_key = os.getenv('JWT_SECRET_KEY', 'jwt-secret-change-me')
            payload = jwt.decode(token, secret_key, algorithms=['HS256'])
            return payload, None
        except jwt.ExpiredSignatureError:
            return None, 'Token has expired'
        except jwt.InvalidTokenError:
            return None, 'Invalid token'
    
    @staticmethod
    def cleanup_expired_otps():
        """
        Clean up expired OTPs from store (call periodically)
        In production, this would be handled by Redis TTL
        """
        current_time = TimeService.now_ms()
        expired = [
            tx_id for tx_id, data in AuthService._otp_store.items()
            if current_time > data['expiry_ms']
        ]
        
        for tx_id in expired:
            del AuthService._otp_store[tx_id]
        
        return len(expired)
