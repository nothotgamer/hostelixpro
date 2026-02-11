from flask import Blueprint, jsonify, request
from app.models.user import User
from app.models.student import Student
from app.models.report import Report
from app.models.routine import Routine
from app.models.fee import Fee
from app.utils.decorators import token_required, role_required
from app.services.time_service import TimeService

from app.api import dashboard_bp

@dashboard_bp.route('/stats', methods=['GET'])
@token_required
def get_dashboard_stats():
    """
    Get dashboard statistics based on user role
    """
    user = request.current_user
    role = user['role']
    user_id = user['user_id']
    
    stats = {}
    
    if role == 'teacher':
        # Teacher Stats
        total_students = Student.query.filter_by(assigned_teacher_id=user_id).count()
        pending_reports = Report.query.join(Student).filter(
            Student.assigned_teacher_id == user_id,
            Report.status == 'pending_teacher'
        ).count()
        
        # Today's wake-up count
        today_start = TimeService.today_start_ms()
        today_reports = Report.query.join(Student).filter(
            Student.assigned_teacher_id == user_id,
            Report.wake_time >= today_start
        ).count()
        
        stats = {
            'total_students': total_students,
            'pending_reports': pending_reports,
            'today_reported': today_reports,
            'attendance_rate': round((today_reports / total_students * 100) if total_students > 0 else 0)
        }
        
    elif role == 'routine_manager':
        # Routine Manager Stats
        total_students = Student.query.count()
        
        currently_out = Routine.query.filter(
            Routine.status.in_(['APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL'])
        ).count()
        
        pending_requests = Routine.query.filter_by(status='PENDING_ROUTINE_MANAGER').count()
        
        # Late returns (placeholder - would need expected_return_time field)
        late_returns = 0
        
        in_hostel = total_students - currently_out
        
        stats = {
            'total_students': total_students,
            'in_hostel': in_hostel,
            'currently_out': currently_out,
            'pending_requests': pending_requests,
            'late_returns': late_returns
        }
        
    elif role == 'admin':
        # Admin Stats (Global)
        total_users = User.query.count()
        pending_users = User.query.filter_by(is_approved=False).count()
        pending_reports = Report.query.filter_by(status='pending_admin').count()
        
        stats = {
            'total_users': total_users,
            'pending_users': pending_users,
            'pending_approvals': pending_reports
        }
        
    elif role == 'student':
        # Student Stats
        student = Student.query.filter_by(user_id=user_id).first()
        if student:
            pass
            
    return jsonify(stats), 200


@dashboard_bp.route('/teacher/students-daily', methods=['GET'])
@token_required
@role_required('teacher')
def get_teacher_students_daily():
    """
    Get daily student data for teacher dashboard
    """
    user_id = request.current_user['user_id']
    today_start = TimeService.today_start_ms()
    
    # Get all assigned students
    students = Student.query.filter_by(assigned_teacher_id=user_id).all()
    
    students_data = []
    summary = {'total': 0, 'reported_today': 0, 'on_leave': 0, 'pending_action': 0}
    
    for student in students:
        summary['total'] += 1
        
        # Check today's wake report
        today_report = Report.query.filter(
            Report.student_id == student.id,
            Report.wake_time >= today_start
        ).first()
        
        # Check current routine status
        active_routine = Routine.query.filter(
            Routine.student_id == student.id,
            Routine.status.in_(['APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL', 'PENDING_ROUTINE_MANAGER'])
        ).first()
        
        current_status = 'in_hostel'
        if active_routine:
            if active_routine.status == 'PENDING_ROUTINE_MANAGER':
                current_status = 'pending_exit'
            elif active_routine.type == 'walk':
                current_status = 'on_walk'
            else:
                current_status = 'on_exit'
                summary['on_leave'] += 1
        
        # Check fee status
        pending_fees = Fee.query.filter_by(student_id=student.id, status='pending').count()
        overdue_fees = Fee.query.filter_by(student_id=student.id, status='overdue').count()
        
        fee_status = 'paid'
        if overdue_fees > 0:
            fee_status = 'overdue'
        elif pending_fees > 0:
            fee_status = 'pending'
        
        if today_report:
            summary['reported_today'] += 1
        
        # Check if action needed
        pending_reports = Report.query.filter_by(
            student_id=student.id,
            status='pending_teacher'
        ).count()
        
        if pending_reports > 0:
            summary['pending_action'] += 1
        
        students_data.append({
            'id': student.id,
            'user_id': student.user_id,
            'name': student.user.display_name if student.user else f'Student #{student.id}',
            'room_no': student.room,
            'wake_reported': today_report is not None,
            'wake_time': today_report.wake_time if today_report else None,
            'current_status': current_status,
            'pending_reports': pending_reports,
            'fee_status': fee_status
        })
    
    return jsonify({
        'date': TimeService.today_date_str(),
        'students': students_data,
        'summary': summary
    }), 200


@dashboard_bp.route('/routine-manager/daily-overview', methods=['GET'])
@token_required
@role_required('routine_manager')
def get_routine_manager_overview():
    """
    Get daily overview for routine manager dashboard
    """
    today_start = TimeService.today_start_ms()
    current_time = TimeService.now_ms()
    
    # Stats
    total_students = Student.query.count()
    
    on_walk = Routine.query.filter(
        Routine.type == 'walk',
        Routine.status.in_(['APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL'])
    ).count()
    
    on_exit = Routine.query.filter(
        Routine.type == 'exit',
        Routine.status.in_(['APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL'])
    ).count()
    
    pending_requests = Routine.query.filter_by(status='PENDING_ROUTINE_MANAGER').count()
    
    in_hostel = total_students - on_walk - on_exit
    
    # Late returns
    late_returns = Routine.query.filter(
        Routine.status == 'APPROVED_PENDING_RETURN',
        Routine.expected_return_time != None,
        Routine.expected_return_time < current_time
    ).count()
    
    # Recent activity (last 10 actions today)
    recent = Routine.query.filter(
        Routine.updated_at >= today_start
    ).order_by(Routine.updated_at.desc()).limit(10).all()
    
    recent_activity = [{
        'id': r.id,
        'type': r.type,
        'status': r.status,
        'student_name': r.student.user.display_name if r.student and r.student.user else None,
        'timestamp': r.updated_at
    } for r in recent]
    
    # Alerts (pending > 30 mins, late returns)
    alerts = []
    
    if late_returns > 0:
        alerts.append({
            'type': 'danger',
            'message': f'{late_returns} student(s) overdue for return'
        })
    
    old_pending = Routine.query.filter(
        Routine.status == 'PENDING_ROUTINE_MANAGER',
        Routine.created_at < current_time - 1800000  # 30 mins ago
    ).count()
    
    if old_pending > 0:
        alerts.append({
            'type': 'warning',
            'message': f'{old_pending} request(s) pending for over 30 minutes'
        })
    
    return jsonify({
        'date': TimeService.today_date_str(),
        'stats': {
            'total_students': total_students,
            'in_hostel': in_hostel,
            'on_walk': on_walk,
            'on_exit': on_exit,
            'pending_requests': pending_requests,
            'late_returns': late_returns
        },
        'recent_activity': recent_activity,
        'alerts': alerts
    }), 200

