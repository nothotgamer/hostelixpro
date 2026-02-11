"""
Audit log model for comprehensive activity tracking
"""
from app import db
import time


class AuditLog(db.Model):
    """
    Comprehensive audit trail for all system actions
    Immutable records of who did what, when, where, and why
    """
    __tablename__ = 'audit_logs'
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    action = db.Column(db.String(100), nullable=False, index=True)
    entity = db.Column(db.String(100), index=True)  # e.g., 'report', 'user', 'fee'
    entity_id = db.Column(db.BigInteger)
    timestamp = db.Column(db.BigInteger, nullable=False, default=lambda: int(time.time() * 1000), index=True)
    ip = db.Column(db.String(45))  # IPv6 compatible
    device = db.Column(db.String(255))  # User agent or device info
    details_json = db.Column(db.JSON)  # Additional context as JSON
    reason = db.Column(db.Text)  # For destructive actions, admin must provide reason
    
    def to_dict(self):
        """Convert audit log to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'action': self.action,
            'entity': self.entity,
            'entity_id': self.entity_id,
            'timestamp': self.timestamp,
            'ip': self.ip,
            'device': self.device,
            'details_json': self.details_json,
            'reason': self.reason
        }
    
    @staticmethod
    def log(user_id, action, entity=None, entity_id=None, ip=None, device=None, details=None, reason=None):
        """
        Create an audit log entry
        
        Args:
            user_id: ID of user performing action (can be None for system actions)
            action: Action performed (e.g., 'LOGIN', 'APPROVE_REPORT', 'DELETE_USER')
            entity: Entity type affected (e.g., 'user', 'report', 'fee')
            entity_id: ID of affected entity
            ip: IP address of request
            device: User agent or device identifier
            details: Additional context as dictionary
            reason: Reason for action (required for destructive actions)
        """
        log_entry = AuditLog(
            user_id=user_id,
            action=action,
            entity=entity,
            entity_id=entity_id,
            ip=ip,
            device=device,
            details_json=details,
            reason=reason
        )
        db.session.add(log_entry)
        return log_entry
    
    def __repr__(self):
        return f'<AuditLog {self.action} by user {self.user_id} at {self.timestamp}>'
