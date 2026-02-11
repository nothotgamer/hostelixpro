"""
User management API endpoints (Admin only)
"""
from flask import request, jsonify
from app.api import users_bp
from app import db
from app.models.user import User
from app.models.student import Student
from app.models.audit_log import AuditLog
from app.services.auth_service import AuthService
from app.utils.decorators import token_required, role_required, validate_json


@users_bp.route('', methods=['GET'])
@token_required
@role_required('admin')
def list_users():
    """
    List all users (Admin only)
    Query params: role, is_locked
    """
    role = request.args.get('role')
    is_locked = request.args.get('is_locked')
    is_approved = request.args.get('is_approved')
    
    query = User.query
    
    if role:
        query = query.filter_by(role=role)
    
    if is_locked is not None:
        query = query.filter_by(is_locked=is_locked.lower() == 'true')

    if is_approved is not None:
        query = query.filter_by(is_approved=is_approved.lower() == 'true')
    
    users = query.all()
    
    return jsonify({
        'users': [user.to_dict() for user in users],
        'total': len(users)
    }), 200


@users_bp.route('/my-students', methods=['GET'])
@token_required
@role_required('teacher')
def get_my_students():
    """
    Get students assigned to the current teacher
    """
    teacher_id = request.current_user['user_id']
    
    # query students assigned to this teacher
    students = Student.query.filter_by(assigned_teacher_id=teacher_id).all()
    
    # We want to return User objects (with student info nested or vice versa)
    # But User.to_dict() doesn't include student info by default usually
    # Let's fetch Users who match these student records
    
    student_user_ids = [s.user_id for s in students]
    users = User.query.filter(User.id.in_(student_user_ids)).all()
    
    # Use a map to attach student details if needed, or just return users
    # Better: return User dict but inject student details like admission_no
    
    results = []
    for user in users:
        student_profile = next((s for s in students if s.user_id == user.id), None)
        user_dict = user.to_dict()
        if student_profile:
            user_dict['student_profile'] = student_profile.to_dict()
        results.append(user_dict)
        
    return jsonify({
        'students': results,
        'total': len(results)
    }), 200


@users_bp.route('/student-profiles', methods=['GET'])
@token_required
def get_student_profiles():
    """
    Get student profiles with role-based access:
    - Admin: All students
    - Teacher: Assigned students only
    - Routine Manager: All students (limited fields)
    """
    from datetime import datetime
    from app.models.routine import Routine
    
    user = request.current_user
    role = user['role']
    user_id = user['user_id']
    
    # Get year/month for activity summary
    year = request.args.get('year', type=int, default=datetime.now().year)
    month = request.args.get('month', type=int, default=datetime.now().month)
    
    # Calculate timestamp range
    start_date = datetime(year, month, 1)
    if month == 12:
        end_date = datetime(year + 1, 1, 1)
    else:
        end_date = datetime(year, month + 1, 1)
    start_ts = int(start_date.timestamp() * 1000)
    end_ts = int(end_date.timestamp() * 1000)
    
    # Get students based on role
    if role == 'admin':
        students = Student.query.all()
    elif role == 'teacher':
        students = Student.query.filter_by(assigned_teacher_id=user_id).all()
    elif role == 'routine_manager':
        students = Student.query.all()
    else:
        return jsonify({'error': 'Unauthorized'}), 403
    
    student_ids = [s.id for s in students]
    user_ids = [s.user_id for s in students]
    
    # Get users
    users = User.query.filter(User.id.in_(user_ids)).all()
    user_map = {u.id: u for u in users}
    
    # Get activity counts for each student this month
    routines = Routine.query.filter(
        Routine.student_id.in_(student_ids),
        Routine.request_time >= start_ts,
        Routine.request_time < end_ts
    ).all()
    
    # Group by student
    activity_map = {}
    for r in routines:
        if r.student_id not in activity_map:
            activity_map[r.student_id] = {'walks': 0, 'exits': 0, 'returns': 0}
        if r.type == 'walk':
            activity_map[r.student_id]['walks'] += 1
        elif r.type == 'exit':
            activity_map[r.student_id]['exits'] += 1
        elif r.type == 'return':
            activity_map[r.student_id]['returns'] += 1
    
    # Build results
    results = []
    for student in students:
        user = user_map.get(student.user_id)
        if not user:
            continue
        
        teacher_name = None
        if student.assigned_teacher:
            teacher_name = student.assigned_teacher.display_name
        
        data = {
            'id': student.id,
            'user_id': student.user_id,
            'display_name': user.display_name,
            'email': user.email,
            'room': student.room,
            'admission_no': student.admission_no,
            'assigned_teacher_name': teacher_name,
            'activities': activity_map.get(student.id, {'walks': 0, 'exits': 0, 'returns': 0})
        }
        
        # Routine manager gets limited data
        if role == 'routine_manager':
            data = {
                'id': student.id,
                'display_name': user.display_name,
                'room': student.room,
                'activities': activity_map.get(student.id, {'walks': 0, 'exits': 0, 'returns': 0})
            }
        
        results.append(data)
    
    return jsonify({
        'students': results,
        'year': year,
        'month': month,
        'total': len(results)
    }), 200


@users_bp.route('/student-profiles/<int:student_id>/activities', methods=['GET'])
@token_required
def get_student_activities(student_id):
    """
    Get detailed activity calendar for a specific student
    """
    from datetime import datetime
    from collections import defaultdict
    from app.models.routine import Routine
    
    user = request.current_user
    role = user['role']
    user_id = user['user_id']
    
    # Check access
    student = Student.query.get_or_404(student_id)
    
    if role == 'teacher' and student.assigned_teacher_id != user_id:
        return jsonify({'error': 'Not your assigned student'}), 403
    elif role not in ['admin', 'teacher', 'routine_manager']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    year = request.args.get('year', type=int, default=datetime.now().year)
    month = request.args.get('month', type=int, default=datetime.now().month)
    
    # Timestamp range
    start_date = datetime(year, month, 1)
    if month == 12:
        end_date = datetime(year + 1, 1, 1)
    else:
        end_date = datetime(year, month + 1, 1)
    start_ts = int(start_date.timestamp() * 1000)
    end_ts = int(end_date.timestamp() * 1000)
    
    routines = Routine.query.filter(
        Routine.student_id == student_id,
        Routine.request_time >= start_ts,
        Routine.request_time < end_ts
    ).order_by(Routine.request_time.desc()).all()
    
    # Group by date
    grouped = defaultdict(list)
    for r in routines:
        date_str = datetime.fromtimestamp(r.request_time / 1000).strftime('%Y-%m-%d')
        grouped[date_str].append(r.to_dict())
    
    # Summary per day
    summary = {}
    for date_str, items in grouped.items():
        summary[date_str] = {
            'total': len(items),
            'walks': len([i for i in items if i['type'] == 'walk']),
            'exits': len([i for i in items if i['type'] == 'exit']),
            'returns': len([i for i in items if i['type'] == 'return']),
        }
    
    return jsonify({
        'student_id': student_id,
        'student_name': student.user.display_name if student.user else None,
        'year': year,
        'month': month,
        'activities': dict(grouped),
        'summary': summary
    }), 200


@users_bp.route('/<int:user_id>', methods=['GET'])
@token_required
@role_required('admin')
def get_user(user_id):
    """Get user by ID (Admin only)"""
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict(include_sensitive=True)), 200


@users_bp.route('', methods=['POST'])
@token_required
@role_required('admin')
@validate_json('email', 'password', 'role')
def create_user():
    """
    Create new user (Admin only)
    
    Request:
        {
            "email": "newuser@example.com",
            "password": "SecurePass123",
            "role": "student",
            "display_name": "John Doe"
        }
    """
    data = request.get_json()
    
    # Check if email already exists
    if User.query.filter_by(email=data['email'].lower()).first():
        return jsonify({'error': 'Email already exists'}), 409
    
    # Validate role
    valid_roles = ['admin', 'teacher', 'routine_manager', 'student']
    if data['role'] not in valid_roles:
        return jsonify({'error': f'Invalid role. Must be one of: {", ".join(valid_roles)}'}), 400
    
    # Create user
    user = User(
        email=data['email'].lower(),
        password_hash=AuthService.hash_password(data['password']),
        role=data['role'],
        display_name=data.get('display_name')
    )
    
    db.session.add(user)
    db.session.flush()  # Get user ID
    
    # If student, create student profile
    if data['role'] == 'student':
        student = Student(
            user_id=user.id,
            admission_no=data.get('admission_no'),
            room=data.get('room'),
            assigned_teacher_id=data.get('assigned_teacher_id'),
			monthly_fee_amount=data.get('monthly_fee_amount')
        )
        db.session.add(student)
    
    # Audit log
    AuditLog.log(
        user_id=request.current_user.get('user_id'),
        action='CREATE_USER',
        entity='user',
        entity_id=user.id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify(user.to_dict()), 201



# User update and delete endpoints
@users_bp.route('/<int:user_id>', methods=['PATCH'])
@token_required
@role_required('admin')
def update_user(user_id):
    """
    Update user (Admin only)
    
    Request:
        {
            "email": "updated@example.com",
            "display_name": "Updated Name",
            "role": "teacher",
            "is_locked": false
        }
    """
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    data = request.get_json()
    
    # Update allowed fields
    if 'email' in data:
        # Check if email is already taken by another user
        existing = User.query.filter(User.email == data['email'].lower(), User.id != user_id).first()
        if existing:
            return jsonify({'error': 'Email already exists'}), 409
        user.email = data['email'].lower()
    
    if 'display_name' in data:
        user.display_name = data['display_name']
    
    if 'role' in data:
        valid_roles = ['admin', 'teacher', 'routine_manager', 'student']
        if data['role'] not in valid_roles:
            return jsonify({'error': f'Invalid role. Must be one of: {", ".join(valid_roles)}'}), 400
        user.role = data['role']
    
    if 'is_locked' in data:
        user.is_locked = data['is_locked']
        
    # Update Student fields if user is student
    if user.role == 'student':
        student = Student.query.filter_by(user_id=user.id).first()
        if student:
            if 'monthly_fee_amount' in data:
                student.monthly_fee_amount = data['monthly_fee_amount']
            if 'admission_no' in data:
                student.admission_no = data['admission_no']
            if 'room' in data:
                student.room = data['room']
            if 'assigned_teacher_id' in data:
                student.assigned_teacher_id = data['assigned_teacher_id']
    
    # Audit log
    AuditLog.log(
        user_id=request.current_user.get('user_id'),
        action='UPDATE_USER',
        entity='user',
        entity_id=user.id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify(user.to_dict()), 200


@users_bp.route('/<int:user_id>', methods=['DELETE'])
@token_required
@role_required('admin')
def delete_user(user_id):
    """Delete user (Admin only)"""
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    # Prevent self-deletion
    if user.id == request.current_user.get('user_id'):
        return jsonify({'error': 'Cannot delete your own account'}), 400
    
    # Audit log before deletion
    AuditLog.log(
        user_id=request.current_user.get('user_id'),
        action='DELETE_USER',
        entity='user',
        entity_id=user.id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.delete(user)
    db.session.commit()
    
    return jsonify({'message': 'User deleted successfully'}), 200


@users_bp.route('/<int:user_id>/lock', methods=['POST'])
@token_required
@role_required('admin')
def lock_user(user_id):
    """Lock/unlock user account (Admin only)"""
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    # Prevent locking self
    if user.id == request.current_user.get('user_id'):
        return jsonify({'error': 'Cannot lock your own account'}), 400
    
    data = request.get_json() or {}
    is_locked = data.get('is_locked', not user.is_locked)  # Toggle if not specified
    
    user.is_locked = is_locked
    
    AuditLog.log(
        user_id=request.current_user.get('user_id'),
        action='LOCK_USER' if is_locked else 'UNLOCK_USER',
        entity='user',
        entity_id=user.id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent')
    )
    
    db.session.commit()
    
    return jsonify({'message': f'User {"locked" if is_locked else "unlocked"} successfully', 'is_locked': is_locked}), 200

    return jsonify({'message': f'User {"locked" if is_locked else "unlocked"} successfully', 'is_locked': is_locked}), 200


@users_bp.route('/<int:user_id>/approve', methods=['POST'])
@token_required
@role_required('admin')
@validate_json('admission_no', 'room', 'assigned_teacher_id')
def approve_user(user_id):
    """
    Approve a pending student and assign details (Admin only)
    """
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
        
    if user.is_approved:
        return jsonify({'error': 'User is already approved'}), 400
        
    data = request.get_json()
    
    # Check if admission_no is unique
    if Student.query.filter_by(admission_no=data['admission_no']).first():
        return jsonify({'error': 'Admission number already exists'}), 409
        
    # Get Student profile
    student = Student.query.filter_by(user_id=user.id).first()
    if not student:
        # Should exist from registration, but create if missing
        student = Student(user_id=user.id)
        db.session.add(student)
        
    # Assign details
    student.admission_no = data['admission_no']
    student.room = data['room']
    student.assigned_teacher_id = data['assigned_teacher_id']
    if 'monthly_fee_amount' in data:
        student.monthly_fee_amount = data['monthly_fee_amount']
    
    # Approve user
    user.is_approved = True
    
    AuditLog.log(
        user_id=request.current_user.get('user_id'),
        action='APPROVE_USER',
        entity='user',
        entity_id=user.id,
        ip=request.remote_addr,
        device=request.headers.get('User-Agent'),
        details={
            'admission_no': data['admission_no'],
            'assigned_teacher': data['assigned_teacher_id']
        }
    )
    
    db.session.commit()
    
    return jsonify(user.to_dict()), 200
