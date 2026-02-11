"""
Student profile model
"""
from app import db
from app.models.base import BaseModel


class Student(BaseModel):
    """
    Student profile with assigned teacher and room information
    """
    __tablename__ = 'students'
    
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False)
    assigned_teacher_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    room = db.Column(db.String(100))
    admission_no = db.Column(db.String(100), unique=True, index=True)
    monthly_fee_amount = db.Column(db.Numeric(10, 2), default=0.00)  # Custom monthly fee for this student
    profile_json = db.Column(db.JSON)  # Additional profile data as JSON
    
    # Relationship to assigned teacher
    assigned_teacher = db.relationship(
        'User',
        foreign_keys=[assigned_teacher_id],
        backref='assigned_students'
    )
    
    def to_dict(self):
        """Convert student to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'assigned_teacher_id': self.assigned_teacher_id,
            'room': self.room,
            'admission_no': self.admission_no,
            'monthly_fee_amount': str(self.monthly_fee_amount) if self.monthly_fee_amount else '0.00',
            'profile_json': self.profile_json,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
    
    def __repr__(self):
        return f'<Student {self.admission_no}>'
    
    # Relationship to fees
    fees = db.relationship('Fee', back_populates='student', cascade='all, delete-orphan')
    
    # Relationship to reports and routines
    reports = db.relationship('Report', back_populates='student', cascade='all, delete-orphan')
    routines = db.relationship('Routine', back_populates='student', cascade='all, delete-orphan')
