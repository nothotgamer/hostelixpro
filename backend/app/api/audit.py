"""
Audit Logs API implementation
Admin-only access to view system activity
"""
from flask import request, jsonify
from app import db
from app.api import audit_bp

from app.models.audit_log import AuditLog
from app.models.user import User
from app.utils.decorators import token_required, role_required

@audit_bp.route('/', methods=['GET'])
@token_required
@role_required('admin')
def get_audit_logs():
    """
    Get audit logs with pagination and filtering
    Query params:
        page: int (default 1)
        per_page: int (default 50)
        user_id: int (optional)
        action: str (optional)
        entity: str (optional)
    """
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)
    
    user_id = request.args.get('user_id', type=int)
    action = request.args.get('action')
    entity = request.args.get('entity')
    
    query = AuditLog.query
    
    if user_id:
        query = query.filter_by(user_id=user_id)
    if action:
        query = query.filter(AuditLog.action.ilike(f"%{action}%"))
    if entity:
        query = query.filter_by(entity=entity)
        
    # Sort by newest first
    pagination = query.order_by(AuditLog.timestamp.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    logs = []
    for log in pagination.items:
        log_dict = log.to_dict()
        # Enrich with user email if available
        if log.user_id:
            user = User.query.get(log.user_id)
            if user:
                log_dict['user_email'] = user.email
                log_dict['user_name'] = user.display_name
        logs.append(log_dict)
        
    return jsonify({
        'logs': logs,
        'total': pagination.total,
        'pages': pagination.pages,
        'current_page': page
    }), 200
