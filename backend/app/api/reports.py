from flask import request, jsonify, send_file
from app.api import reports_bp
from app import db
from app.models.report import Report
from app.models.student import Student
from app.services.report_service import ReportService
from app.services.export_service import ExportService
from app.utils.decorators import token_required, role_required, validate_json

@reports_bp.route('', methods=['GET'])
@token_required
def list_reports():
    """
    List reports based on role
    Student: Own reports
    Teacher: Reports of assigned students
    Admin: All reports (filterable)
    """
    user = request.current_user
    role = user['role']
    user_id = user['user_id']
    
    query = Report.query
    
    if role == 'student':
        # Find student profile
        student = Student.query.filter_by(user_id=user_id).first()
        if not student:
            return jsonify({'error': 'Student profile not found'}), 404
        query = query.filter_by(student_id=student.id)
        
    elif role == 'teacher':
        # Filter by assigned students + status PENDING_TEACHER (default view) or all
        # Ideally, we get teacher's ID, then find students where assigned_teacher_id = teacher_user_id
        # Note: Student.assigned_teacher_id links to User.id
        status = request.args.get('status')
        query = query.join(Student).filter(Student.assigned_teacher_id == user_id)
        if status:
            query = query.filter(Report.status == status)
            
    elif role == 'admin':
        # Admin can see all, filter by status if provided
        status = request.args.get('status')
        if status:
            query = query.filter_by(status=status)
            
    # Pagination could be added here
    reports = query.order_by(Report.created_at.desc()).limit(100).all()
    
    return jsonify({
        'reports': [r.to_dict() for r in reports]
    }), 200


@reports_bp.route('', methods=['POST'])
@token_required
@role_required('student')
def create_report():
    """
    Student creates daily report (Wake Up)
    """
    user_id = request.current_user['user_id']
    student = Student.query.filter_by(user_id=user_id).first()
    
    if not student:
        return jsonify({'error': 'Student profile not found'}), 404
        
    report, error = ReportService.create_daily_report(user_id, student.id)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(report.to_dict()), 201

@reports_bp.route('/<int:report_id>/approve', methods=['POST'])
@token_required
def approve_report(report_id):
    """
    Approve report (Teacher or Admin)
    """
    user = request.current_user
    role = user['role']
    
    if role not in ['teacher', 'admin']:
        return jsonify({'error': 'Unauthorized'}), 403
        
    data = request.get_json() or {}
    notes = data.get('notes')
    
    report, error = ReportService.approve_report(report_id, user['user_id'], role, notes)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(report.to_dict()), 200

@reports_bp.route('/<int:report_id>/reject', methods=['POST'])
@token_required
def reject_report(report_id):
    """
    Reject report (Teacher or Admin)
    """
    user = request.current_user
    role = user['role']
    
    if role not in ['teacher', 'admin']:
        return jsonify({'error': 'Unauthorized'}), 403
        
    data = request.get_json() or {}
    notes = data.get('notes')
    
    if not notes:
        return jsonify({'error': 'Reason (notes) required for rejection'}), 400
    
    report, error = ReportService.reject_report(report_id, user['user_id'], notes)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(report.to_dict()), 200

@reports_bp.route('/export', methods=['GET'])
@token_required
@role_required('admin')
def export_reports():
    """
    Export reports as Excel
    """
    try:
        buffer = ExportService.generate_reports_excel()
        return send_file(
            buffer,
            as_attachment=True,
            download_name=f"reports_export.xlsx",
            mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 400
