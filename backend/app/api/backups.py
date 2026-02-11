"""
Backup API endpoints
"""
from flask import request, jsonify, send_file
# Remove Blueprint import as we import the instance
# from flask import Blueprint 
from app import db
from app.api import backups_bp
from app.models.backup_meta import BackupMeta
from app.models.audit_log import AuditLog
from app.services.backup_service import BackupService
from app.utils.decorators import token_required, role_required

# backups_bp definition removed, imported above

@backups_bp.route('/', methods=['POST'])
@token_required
@role_required('admin')
def create_backup():
    """
    Create a new encrypted backup
    Returns: Backup metadata and encryption key
    """
    user_id = request.current_user.get('user_id')
    try:
        backup, key = BackupService.create_backup(user_id)
        
        # Log action
        ip = request.remote_addr
        device = request.headers.get('User-Agent', '')
        AuditLog.log(
            user_id=user_id,
            action='BACKUP_CREATE',
            entity='backup',
            entity_id=backup.id,
            ip=ip,
            device=device,
            details={'filename': backup.filename, 'size': backup.file_size_bytes}
        )
        db.session.commit()
        
        return jsonify({
            'message': 'Backup created successfully',
            'backup': backup.to_dict(),
            'encryption_key': key # IMPORTANT: User must save this!
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@backups_bp.route('/', methods=['GET'])
@token_required
@role_required('admin')
def list_backups():
    """List all backups"""
    backups = BackupMeta.query.order_by(BackupMeta.created_at.desc()).all()
    return jsonify([b.to_dict() for b in backups]), 200

@backups_bp.route('/<int:id>/download', methods=['GET'])
@token_required
@role_required('admin')
def download_backup(id):
    """Download encrypted backup file"""
    backup = BackupMeta.query.get_or_404(id)
    backup_dir = BackupService._get_backup_dir()
    import os
    path = os.path.join(backup_dir, backup.filename)
    
    if not os.path.exists(path):
        return jsonify({'error': 'File not found'}), 404
        
    return send_file(
        path,
        as_attachment=True,
        download_name=backup.filename,
        mimetype='application/octet-stream'
    )

@backups_bp.route('/restore', methods=['POST'])
@token_required
@role_required('admin')
def restore_backup():
    """
    Verify and restore backup
    """
    data = request.get_json()
    backup_id = data.get('backup_id')
    key = data.get('key')
    
    if not backup_id or not key:
        return jsonify({'error': 'backup_id and key are required'}), 400
        
    try:
        success, message = BackupService.restore_backup(backup_id, key)
        
        # Log action
        user_id = request.current_user.get('user_id')
        ip = request.remote_addr
        device = request.headers.get('User-Agent', '')
        AuditLog.log(
            user_id=user_id,
            action='BACKUP_RESTORE_VERIFY', # We are only verifying for now
            entity='backup',
            entity_id=backup_id,
            ip=ip,
            device=device,
            details={'success': success, 'message': message}
        )
        db.session.commit()
        
        if success:
            return jsonify({'message': message}), 200
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500
