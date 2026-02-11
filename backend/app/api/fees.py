"""
Fee API endpoints
"""
from flask import request, jsonify, send_file, current_app
from app import db
from app.api import fees_bp
from app.models.fee import Fee
from app.models.fee_structure import FeeStructure
from app.models.student import Student
from app.services.fee_service import FeeService
from app.services.export_service import ExportService
from app.utils.decorators import token_required, role_required
from datetime import datetime
import os
import uuid
from werkzeug.utils import secure_filename

# --- Fee Structure Management (Admin) ---

@fees_bp.route('/structures', methods=['GET'])
@token_required
@role_required('admin')
def list_fee_structures():
    structures = FeeStructure.query.order_by(FeeStructure.is_active.desc(), FeeStructure.name).all()
    return jsonify([s.to_dict() for s in structures]), 200

@fees_bp.route('/structures', methods=['POST'])
@token_required
@role_required('admin')
def create_fee_structure():
    data = request.get_json()
    
    try:
        structure = FeeStructure(
            name=data['name'],
            monthly_amount=data['monthly_amount'],
            late_fee_per_day=data.get('late_fee_per_day', 0),
            due_day=data.get('due_day', 5),
            is_active=data.get('is_active', True),
            description=data.get('description')
        )
        db.session.add(structure)
        db.session.commit()
        return jsonify(structure.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 400

@fees_bp.route('/structures/<int:id>', methods=['PUT'])
@token_required
@role_required('admin')
def update_fee_structure(id):
    structure = FeeStructure.query.get_or_404(id)
    data = request.get_json()
    
    try:
        if 'name' in data: structure.name = data['name']
        if 'monthly_amount' in data: structure.monthly_amount = data['monthly_amount']
        if 'late_fee_per_day' in data: structure.late_fee_per_day = data['late_fee_per_day']
        if 'due_day' in data: structure.due_day = data['due_day']
        if 'is_active' in data: structure.is_active = data['is_active']
        if 'description' in data: structure.description = data['description']
        
        db.session.commit()
        return jsonify(structure.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 400

# --- Fee Management ---

@fees_bp.route('', methods=['GET'])
@token_required
def list_fees():
    """
    List fees with enhanced filtering
    """
    user = request.current_user
    role = user['role']
    
    query = Fee.query
    
    # Role-based access
    if role == 'student':
        student = Student.query.filter_by(user_id=user['user_id']).first()
        if not student:
            return jsonify({'error': 'Student profile not found'}), 404
        query = query.filter_by(student_id=student.id)
    elif role == 'admin':
        # Admin filters
        if request.args.get('student_id'):
            query = query.filter_by(student_id=request.args.get('student_id'))
        if request.args.get('status'):
            query = query.filter_by(status=request.args.get('status'))
        if request.args.get('month'):
            query = query.filter_by(month=request.args.get('month'))
        if request.args.get('year'):
            query = query.filter_by(year=request.args.get('year'))

    # Pagination
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    pagination = query.order_by(Fee.year.desc(), Fee.month.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'fees': [f.to_dict() for f in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages,
        'current_page': page
    }), 200

@fees_bp.route('/calendar', methods=['GET'])
@token_required
@role_required('admin', 'student')
def get_fee_calendar():
    """
    Get fee status matrix for students in a given year
    Admin: all students, Student: own fees only
    Returns detailed amounts per month and yearly totals
    """
    user = request.current_user
    year = request.args.get('year', datetime.now().year, type=int)
    
    # Get students based on role
    if user['role'] == 'student':
        # Student: only their own data
        student = Student.query.filter_by(user_id=user['user_id']).first()
        if not student:
            return jsonify({'error': 'Student profile not found'}), 404
        students = [student]
    else:
        # Admin: all active students with search filter
        query = Student.query.join(Student.user).filter_by(is_locked=False)
        
        search = request.args.get('search')
        if search:
            search_term = f"%{search}%"
            from app.models.user import User # Import here to avoid circular dependency if any
            query = query.filter(
                db.or_(
                    User.display_name.ilike(search_term),
                    Student.admission_no.ilike(search_term),
                    Student.room.ilike(search_term)
                )
            )
            
        students = query.all()
    
    # Get all fees for the year
    student_ids = [s.id for s in students]
    fees = Fee.query.filter(Fee.year == year, Fee.student_id.in_(student_ids)).all()
    
    # Build matrix: student_id -> month -> fee data
    fee_map = {}
    for f in fees:
        if f.student_id not in fee_map:
            fee_map[f.student_id] = {}
        fee_map[f.student_id][f.month] = {
            'id': f.id,
            'status': f.status,
            'expected_amount': float(f.expected_amount or 0),
            'paid_amount': float(f.paid_amount or 0),
            'remaining_amount': float((f.expected_amount or 0) - (f.paid_amount or 0))
        }
    
    result = []
    for s in students:
        # Get student's monthly fee (directly from student profile)
        monthly_expected = float(s.monthly_fee_amount or 0)
        
        months_data = {}
        yearly_expected = 0
        yearly_paid = 0
        
        for m in range(1, 13):
            month_fee = fee_map.get(s.id, {}).get(m)
            if month_fee:
                months_data[m] = month_fee
                yearly_expected += month_fee['expected_amount']
                yearly_paid += month_fee['paid_amount']
            else:
                # No fee record: unpaid with expected from structure
                months_data[m] = {
                    'id': None,
                    'status': 'UNPAID',
                    'expected_amount': float(monthly_expected),
                    'paid_amount': 0,
                    'remaining_amount': float(monthly_expected)
                }
                yearly_expected += float(monthly_expected)
                
        result.append({
            'student': {
                'id': s.id,
                'name': s.user.display_name,
                'admission_no': s.admission_no,
                'room': s.room,
                'monthly_fee': float(monthly_expected)
            },
            'fees': months_data,
            'summary': {
                'yearly_expected': yearly_expected,
                'yearly_paid': yearly_paid,
                'yearly_remaining': yearly_expected - yearly_paid
            }
        })
        
    return jsonify(result), 200

@fees_bp.route('/stats', methods=['GET'])
@token_required
@role_required('admin')
def get_fee_stats():
    """
    Get fee collection statistics for current month
    """
    now = datetime.now()
    month = request.args.get('month', now.month, type=int)
    year = request.args.get('year', now.year, type=int)
    
    total_students = Student.query.count()
    
    # Fees for this month
    fees = Fee.query.filter_by(month=month, year=year).all()
    
    paid_count = sum(1 for f in fees if f.status == 'APPROVED')
    pending_count = sum(1 for f in fees if f.status == 'PENDING_ADMIN')
    
    expected_collection = db.session.query(db.func.sum(FeeStructure.monthly_amount))\
        .filter(FeeStructure.is_active==True).scalar() or 0
        
    actual_collection = sum(f.paid_amount for f in fees if f.status == 'APPROVED' and f.paid_amount)
    
    return jsonify({
        'total_students': total_students,
        'paid_count': paid_count,
        'pending_count': pending_count,
        'unpaid_count': total_students - (paid_count + pending_count),
        'expected_collection': str(expected_collection * total_students), # Rough estimate
        'actual_collection': str(actual_collection)
    }), 200

@fees_bp.route('/upload-proof', methods=['POST'])
@token_required
@role_required('student', 'admin')
def upload_proof():
    """
    Upload payment proof image
    """
    if 'proof_file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
        
    file = request.files['proof_file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
        
    if file:
        filename = secure_filename(file.filename)
        unique_name = f"{uuid.uuid4()}_{filename}"
        
        # Save to static/uploads/proofs
        upload_dir = os.path.join(current_app.root_path, 'static', 'uploads', 'proofs')
        os.makedirs(upload_dir, exist_ok=True)
        
        file.save(os.path.join(upload_dir, unique_name))
        
        # Return path relative to static
        return jsonify({'path': f"/static/uploads/proofs/{unique_name}"}), 201

    return jsonify({'error': 'Upload failed'}), 500

@fees_bp.route('', methods=['POST'])
@token_required
@role_required('student')
def submit_fee():
    data = request.get_json()
    user_id = request.current_user['user_id']
    
    try:
        transaction, error = FeeService.add_transaction(
            user_id,
            data.get('month'),
            data.get('year'),
            data.get('amount'),
            data.get('proof_path'),
            data.get('payment_method', 'manual'),
            data.get('reference')
        )
        
        if error:
            return jsonify({'error': error}), 400
            
        return jsonify(transaction.to_dict()), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@fees_bp.route('/transactions/<int:id>/approve', methods=['POST'])
@token_required
@role_required('admin')
def approve_transaction(id):
    transaction, error = FeeService.approve_transaction(id, request.current_user['user_id'])
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(transaction.to_dict()), 200

@fees_bp.route('/transactions/<int:id>/reject', methods=['POST'])
@token_required
@role_required('admin')
def reject_transaction(id):
    data = request.get_json()
    reason = data.get('reason', 'Rejected by admin')
    
    transaction, error = FeeService.reject_transaction(id, request.current_user['user_id'], reason)
    
    if error:
        return jsonify({'error': error}), 400
        
    return jsonify(transaction.to_dict()), 200

@fees_bp.route('/<int:id>/transactions', methods=['GET'])
@token_required
def get_fee_transactions(id):
    """Get all transactions for a specific fee record"""
    from app.models.transaction import Transaction
    
    # Check permission
    fee = Fee.query.get_or_404(id)
    user = request.current_user
    if user['role'] == 'student':
        student = Student.query.filter_by(user_id=user['user_id']).first()
        if not student or fee.student_id != student.id:
            return jsonify({'error': 'Unauthorized'}), 403
            
    transactions = Transaction.query.filter_by(fee_id=id).order_by(Transaction.transaction_date.desc()).all()
    return jsonify([t.to_dict() for t in transactions]), 200

@fees_bp.route('/<int:id>/challan', methods=['GET'])
@token_required
def download_challan(id):
    """
    Download Fee Challan PDF
    """
    try:
        buffer = ExportService.generate_fee_challan(id)
        return send_file(
            buffer,
            as_attachment=True,
            download_name=f"fee_challan_{id}.pdf",
            mimetype='application/pdf'
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 400
