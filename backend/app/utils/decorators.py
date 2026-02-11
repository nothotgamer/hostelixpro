"""
Utility decorators for route protection and validation
"""
from functools import wraps
from flask import request, jsonify
from app.services.auth_service import AuthService
from app.models.audit_log import AuditLog
from app import db


def token_required(f):
    """
    Decorator to require valid JWT token
    Extracts token from Authorization header
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None
        
        # Get token from Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            parts = auth_header.split()
            
            if len(parts) == 2 and parts[0].lower() == 'bearer':
                token = parts[1]
        
        if not token:
            return jsonify({'error': 'Missing authentication token'}), 401
        
        # Verify token
        payload, error = AuthService.verify_jwt_token(token)
        
        if error:
            return jsonify({'error': error}), 401
        
        # Attach user info to request
        request.current_user = payload
        
        return f(*args, **kwargs)
    
    return decorated_function


def role_required(*allowed_roles):
    """
    Decorator to require specific role(s)
    Must be used after @token_required
    
    Usage:
        @role_required('admin')
        @role_required('admin', 'teacher')
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not hasattr(request, 'current_user'):
                return jsonify({'error': 'Authentication required'}), 401
            
            user_role = request.current_user.get('role')
            
            if user_role not in allowed_roles:
                return jsonify({'error': 'Insufficient permissions'}), 403
            
            return f(*args, **kwargs)
        
        return decorated_function
    
    return decorator


def audit_log(action, entity=None):
    """
    Decorator to automatically create audit log entries
    
    Usage:
        @audit_log('LOGIN', 'user')
        @audit_log('APPROVE_REPORT', 'report')
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Execute the function
            result = f(*args, **kwargs)
            
            # Log the action
            user_id = getattr(request, 'current_user', {}).get('user_id')
            entity_id = kwargs.get('id') or kwargs.get(f'{entity}_id')
            
            ip = request.remote_addr
            device = request.headers.get('User-Agent', '')
            
            AuditLog.log(
                user_id=user_id,
                action=action,
                entity=entity,
                entity_id=entity_id,
                ip=ip,
                device=device
            )
            
            db.session.commit()
            
            return result
        
        return decorated_function
    
    return decorator


def validate_json(*required_fields):
    """
    Decorator to validate JSON request body
    
    Usage:
        @validate_json('email', 'password')
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not request.is_json:
                return jsonify({'error': 'Content-Type must be application/json'}), 400
            
            data = request.get_json()
            
            missing_fields = [field for field in required_fields if field not in data or not data[field]]
            
            if missing_fields:
                return jsonify({
                    'error': 'Missing required fields',
                    'missing_fields': missing_fields
                }), 400
            
            return f(*args, **kwargs)
        
        return decorated_function
    
    return decorator
