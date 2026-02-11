"""
Notification API endpoints
"""
from flask import request, jsonify
from app.api import notifications_bp
from app import db
from app.models.notification import Notification
from app.utils.decorators import token_required


@notifications_bp.route('', methods=['GET'])
@token_required
def get_notifications():
    """
    Get notifications for current user
    """
    user_id = request.current_user.get('user_id')
    
    # Query params
    unread_only = request.args.get('unread', 'false').lower() == 'true'
    limit = min(int(request.args.get('limit', 50)), 100)
    
    query = Notification.query.filter_by(user_id=user_id)
    
    if unread_only:
        query = query.filter_by(is_read=False)
    
    notifications = query.order_by(Notification.created_at.desc()).limit(limit).all()
    
    # Get unread count
    unread_count = Notification.query.filter_by(user_id=user_id, is_read=False).count()
    
    return jsonify({
        'notifications': [n.to_dict() for n in notifications],
        'unread_count': unread_count
    }), 200


@notifications_bp.route('/<int:id>/read', methods=['POST'])
@token_required
def mark_as_read(id):
    """
    Mark a notification as read
    """
    user_id = request.current_user.get('user_id')
    
    notification = Notification.query.filter_by(id=id, user_id=user_id).first_or_404()
    notification.is_read = True
    notification.update_timestamp()
    
    db.session.commit()
    
    return jsonify(notification.to_dict()), 200


@notifications_bp.route('/read-all', methods=['POST'])
@token_required
def mark_all_as_read():
    """
    Mark all notifications as read
    """
    user_id = request.current_user.get('user_id')
    
    Notification.query.filter_by(user_id=user_id, is_read=False).update({
        'is_read': True
    })
    
    db.session.commit()
    
    return jsonify({'message': 'All notifications marked as read'}), 200


@notifications_bp.route('/unread-count', methods=['GET'])
@token_required
def get_unread_count():
    """
    Get unread notification count
    """
    user_id = request.current_user.get('user_id')
    count = Notification.query.filter_by(user_id=user_id, is_read=False).count()
    
    return jsonify({'count': count}), 200
