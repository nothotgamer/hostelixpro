"""
Routine API endpoints
"""
from flask import request, jsonify
from app.api import routines_bp
from app.services.routine_service import RoutineService
from app.utils.decorators import token_required, role_required

@routines_bp.route('', methods=['GET'])
@token_required
def list_routines():
    """
    List routines based on role
    Student: Own history
    Manager: Pending requests
    """
    user = request.current_user
    role = user['role']
    user_id = user['user_id']
    
    from app.models.routine import Routine
    from app.models.student import Student
    
    query = Routine.query
    
    if role == 'student':
        student = Student.query.filter_by(user_id=user_id).first()
        if not student:
            return jsonify({'error': 'Student profile not found'}), 404
        query = query.filter_by(student_id=student.id)
        
    elif role in ('routine_manager', 'admin', 'teacher'):
        # Default to pending requests for managers
        status = request.args.get('status')
        if status:
            query = query.filter_by(status=status)
        elif role == 'routine_manager':
            # Show pending by default for managers
            query = query.filter(Routine.status.in_(['PENDING_ROUTINE_MANAGER', 'PENDING_RETURN_APPROVAL']))
        # Admin and teacher see all routines by default
            
    # Sort by newest first
    routines = query.order_by(Routine.created_at.desc()).limit(50).all()
    
    return jsonify({
        'routines': [r.to_dict() for r in routines]
    }), 200


@routines_bp.route('', methods=['POST'])
@token_required
@role_required('student')
def create_routine():
    """Create walk or exit request"""
    data = request.get_json()
    req_type = data.get('type')
    payload = data.get('payload')
    
    if req_type not in ['walk', 'exit']:
        return jsonify({'error': 'Invalid type. Must be walk or exit'}), 400
        
    user_id = request.current_user['user_id']
    routine, error = RoutineService.create_request(user_id, req_type, payload)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(routine.to_dict()), 201

@routines_bp.route('/<int:id>/approve', methods=['POST'])
@token_required
@role_required('routine_manager')
def approve_routine(id):
    """Manager approves request"""
    routine, error = RoutineService.approve_request(id, request.current_user['user_id'])
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(routine.to_dict()), 200

@routines_bp.route('/<int:id>/return', methods=['POST'])
@token_required
@role_required('student')
def request_return(id):
    """Student requests return"""
    user_id = request.current_user['user_id']
    routine, error = RoutineService.request_return(id, user_id)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(routine.to_dict()), 200

@routines_bp.route('/<int:id>/confirm-return', methods=['POST'])
@token_required
@role_required('routine_manager')
def confirm_return(id):
    """Manager confirms return"""
    routine, error = RoutineService.confirm_return(id, request.current_user['user_id'])
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(routine.to_dict()), 200


@routines_bp.route('/<int:id>/reject', methods=['POST'])
@token_required
@role_required('routine_manager')
def reject_routine(id):
    """Manager rejects request with reason"""
    data = request.get_json() or {}
    reason = data.get('reason', 'No reason provided')
    
    routine, error = RoutineService.reject_request(id, request.current_user['user_id'], reason)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(routine.to_dict()), 200


@routines_bp.route('/stats', methods=['GET'])
@token_required
@role_required('routine_manager', 'admin')
def get_stats():
    """Get routine statistics for dashboard"""
    from app.models.routine import Routine
    
    pending_count = Routine.query.filter(
        Routine.status.in_(['PENDING_ROUTINE_MANAGER', 'PENDING_RETURN_APPROVAL'])
    ).count()
    
    currently_out = Routine.query.filter_by(status='APPROVED_PENDING_RETURN').count()
    
    # Late returns
    from app.services.time_service import TimeService
    now = TimeService.now_ms()
    
    late_returns = Routine.query.filter(
        Routine.status == 'APPROVED_PENDING_RETURN',
        Routine.expected_return_time != None,
        Routine.expected_return_time < now
    ).count()
    
    return jsonify({
        'pending_count': pending_count,
        'currently_out': currently_out,
        'late_returns': late_returns
    }), 200


@routines_bp.route('/currently-out', methods=['GET'])
@token_required
@role_required('routine_manager', 'admin')
def get_currently_out():
    """Get list of students currently out (including those pending return confirmation)"""
    from app.models.routine import Routine
    
    routines = Routine.query.filter(
        Routine.status.in_(['APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL'])
    ).order_by(
        Routine.request_time.desc()
    ).all()
    
    return jsonify({
        'routines': [r.to_dict() for r in routines]
    }), 200


@routines_bp.route('/calendar', methods=['GET'])
@token_required
@role_required('admin')
def get_calendar():
    """Get routines grouped by date for calendar view"""
    from datetime import datetime
    from collections import defaultdict
    from app.models.routine import Routine
    
    year = request.args.get('year', type=int, default=datetime.now().year)
    month = request.args.get('month', type=int, default=datetime.now().month)
    
    # Calculate timestamp range for the month
    start_date = datetime(year, month, 1)
    if month == 12:
        end_date = datetime(year + 1, 1, 1)
    else:
        end_date = datetime(year, month + 1, 1)
    
    start_ts = int(start_date.timestamp() * 1000)
    end_ts = int(end_date.timestamp() * 1000)
    
    routines = Routine.query.filter(
        Routine.request_time >= start_ts,
        Routine.request_time < end_ts
    ).order_by(Routine.request_time.desc()).all()
    
    # Group by date
    grouped = defaultdict(list)
    for r in routines:
        date_str = datetime.fromtimestamp(r.request_time / 1000).strftime('%Y-%m-%d')
        grouped[date_str].append(r.to_dict())
    
    # Summary counts per day
    summary = {}
    for date_str, items in grouped.items():
        summary[date_str] = {
            'total': len(items),
            'walks': len([i for i in items if i['type'] == 'walk']),
            'exits': len([i for i in items if i['type'] == 'exit']),
            'returns': len([i for i in items if i['type'] == 'return']),
        }
    
    return jsonify({
        'year': year,
        'month': month,
        'activities': dict(grouped),
        'summary': summary
    }), 200
