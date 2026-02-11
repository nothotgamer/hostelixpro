"""
Report model for student daily discipline reports
"""
from app import db
from app.models.base import BaseModel
import time


class Report(BaseModel):
    """
    Daily report submitted by student
    Workflow: PENDING_TEACHER -> PENDING_ADMIN -> APPROVED (or REJECTED)
    """
    __tablename__ = 'reports'
    
    student_id = db.Column(db.Integer, db.ForeignKey('students.id'), nullable=False, index=True)
    wake_time = db.Column(db.BigInteger, nullable=False)  # Server timestamp of creation
    walk = db.Column(db.Boolean, default=False)
    exercise = db.Column(db.Boolean, default=False)
    late_minutes = db.Column(db.Integer, default=0)
    status = db.Column(
        db.String(50), 
        nullable=False, 
        default='PENDING_TEACHER',
        index=True
    )
    
    # Relationships
    student = db.relationship('Student', back_populates='reports')
    actions = db.relationship('ReportAction', backref='report', cascade='all, delete-orphan')
    
    # Constraints
    __table_args__ = (
        db.CheckConstraint(
            status.in_(['PENDING_TEACHER', 'PENDING_ADMIN', 'APPROVED', 'REJECTED']),
            name='check_valid_report_status'
        ),
    )
    
    def to_dict(self):
        """Convert report to dictionary"""
        return {
            'id': self.id,
            'student_id': self.student_id,
            'student_name': self.student.user.display_name if self.student and self.student.user else None,
            'student_room': self.student.room if self.student else None,
            'student_admission_no': self.student.admission_no if self.student else None,
            'wake_time': self.wake_time,
            'walk': self.walk,
            'exercise': self.exercise,
            'late_minutes': self.late_minutes,
            'status': self.status,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'actions': [action.to_dict() for action in self.actions]
        }
