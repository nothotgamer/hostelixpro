"""
Announcements API endpoints
"""
from flask import request, jsonify
from app.api import announcements_bp
from app import db
from app.models.announcement import Announcement
from app.models.audit_log import AuditLog
from app.utils.decorators import token_required, role_required, validate_json

@announcements_bp.route('/', methods=['GET'])
@token_required
def get_announcements():
    """
    Get announcements visible to current user
    """
    user = request.current_user
    user_role = user.get('role')
    user_id = user.get('user_id')
    
    query = Announcement.query
    
    # 1. Role-based filtering (Base)
    query = query.filter(
        (Announcement.target_role == None) | 
        (Announcement.target_role == user_role) |
        (Announcement.target_role == 'all') |
        (Announcement.author_id == user_id)
    )
    
    # 2. Student-specific filtering (Teacher targeting)
    if user_role == 'student':
        from app.models.student import Student
        from app.models.user import User
        
        student = Student.query.filter_by(user_id=user_id).first()
        if student and student.assigned_teacher_id:
            # Show if:
            # - Author is Admin/RoutineManager (Global) - role check on author
            # - Author is THEIR assigned teacher
            # - Author is themselves (implied but rare)
            
            # Subquery or Join approach
            # We join with User (author) to check role
            query = query.join(User, Announcement.author_id == User.id)
            
            query = query.filter(
                (User.role.in_(['admin', 'routine_manager'])) |
                (Announcement.author_id == student.assigned_teacher_id)
            )
        else:
            # If no teacher assigned yet, only show Admin/RoutineManager announcements
            query = query.join(User, Announcement.author_id == User.id)
            query = query.filter(User.role.in_(['admin', 'routine_manager']))

    # Order by priority and date
    query = query.order_by(Announcement.priority.desc(), Announcement.created_at.desc())
    
    announcements = query.limit(50).all()
    
    return jsonify([a.to_dict() for a in announcements]), 200

@announcements_bp.route('/', methods=['POST'])
@token_required
@role_required('admin', 'teacher', 'routine_manager')
@validate_json('title', 'content')
def create_announcement():
    """
    Create a new announcement
    """
    from datetime import datetime
    
    data = request.get_json()
    user_id = request.current_user.get('user_id')
    
    event_date = None
    if data.get('event_date'):
        try:
            event_date = datetime.strptime(data['event_date'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid event_date format. Use YYYY-MM-DD'}), 400
            
    end_date = None
    if data.get('end_date'):
        try:
            end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid end_date format. Use YYYY-MM-DD'}), 400
    
    announcement = Announcement(
        title=data['title'],
        content=data['content'],
        priority=data.get('priority', 'normal'),
        announcement_type=data.get('announcement_type', 'general'),
        event_date=event_date,
        end_date=end_date,
        target_role=data.get('target_role'),
        author_id=user_id
    )
    
    db.session.add(announcement)
    
    # Log action
    ip = request.remote_addr
    device = request.headers.get('User-Agent', '')
    AuditLog.log(
        user_id=user_id,
        action='ANNOUNCEMENT_CREATE',
        entity='announcement',
        ip=ip,
        device=device,
        details={
            'title': data['title'], 
            'type': announcement.announcement_type,
            'event_date': str(event_date) if event_date else None,
            'end_date': str(end_date) if end_date else None
        }
    )
    
    db.session.commit()
    
    return jsonify(announcement.to_dict()), 201

@announcements_bp.route('/<int:id>', methods=['DELETE'])
@token_required
@role_required('admin')
def delete_announcement(id):
    """
    Delete an announcement (Admin only)
    """
    announcement = Announcement.query.get_or_404(id)
    
    db.session.delete(announcement)
    
    # Log action
    user_id = request.current_user.get('user_id')
    ip = request.remote_addr
    device = request.headers.get('User-Agent', '')
    AuditLog.log(
        user_id=user_id,
        action='ANNOUNCEMENT_DELETE',
        entity='announcement',
        entity_id=id,
        ip=ip,
        device=device,
        details={'title': announcement.title}
    )
    
    db.session.commit()
    
    return jsonify({'message': 'Announcement deleted'}), 200


@announcements_bp.route('/holidays', methods=['GET'])
@token_required
def get_holidays():
    """Get holiday announcements for a given year"""
    from datetime import date
    
    year = request.args.get('year', type=int, default=date.today().year)
    
    start_date = date(year, 1, 1)
    end_date = date(year, 12, 31)
    
    holidays = Announcement.query.filter(
        Announcement.announcement_type == 'holiday',
        Announcement.event_date >= start_date,
        Announcement.event_date <= end_date
    ).order_by(Announcement.event_date).all()
    
    return jsonify({
        'year': year,
        'holidays': [h.to_dict() for h in holidays]
    }), 200
