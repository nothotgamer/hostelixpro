"""
Routine model for walk, exit, and return requests
"""
from app import db
from app.models.base import BaseModel


class Routine(BaseModel):
    """
    Routine requests: Walf, Exit, Return
    """
    __tablename__ = 'routines'
    
    type = db.Column(db.String(20), nullable=False)  # walk, exit, return
    student_id = db.Column(db.Integer, db.ForeignKey('students.id'), nullable=False, index=True)
    request_time = db.Column(db.BigInteger, nullable=False)
    status = db.Column(
        db.String(50), 
        nullable=False,
        default='PENDING_ROUTINE_MANAGER',
        index=True
    )
    payload_json = db.Column(db.JSON)  # For exit reason, companions, return time, etc.
    
    # New columns for management
    rejection_reason = db.Column(db.String(255))
    manager_notes = db.Column(db.Text)
    expected_return_time = db.Column(db.BigInteger)
    actual_return_time = db.Column(db.BigInteger)
    
    # Relationships
    student = db.relationship('Student', back_populates='routines')
    
    # Constraints
    __table_args__ = (
        db.CheckConstraint(
            type.in_(['walk', 'exit', 'return']),
            name='check_valid_routine_type'
        ),
        db.CheckConstraint(
            status.in_([
                'PENDING_ROUTINE_MANAGER', 
                'APPROVED_PENDING_RETURN', 
                'COMPLETED', 
                'REJECTED',
                'PENDING_RETURN_APPROVAL',
                'RETURN_REJECTED'
            ]),
            name='check_valid_routine_status'
        ),
    )
    
    def to_dict(self):
        """Convert routine to dictionary"""
        return {
            'id': self.id,
            'type': self.type,
            'student_id': self.student_id,
            'student_name': self.student.user.display_name if self.student and self.student.user else None,
            'request_time': self.request_time,
            'status': self.status,
            'payload': self.payload_json,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'rejection_reason': self.rejection_reason,
            'manager_notes': self.manager_notes,
            'expected_return_time': self.expected_return_time,
            'actual_return_time': self.actual_return_time
        }
