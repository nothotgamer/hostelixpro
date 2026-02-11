"""
Fee model for student payments
"""
from app import db
from app.models.base import BaseModel


class Fee(BaseModel):
    """
    Student fee submission
    Unique constraint on (student_id, month, year)
    """
    __tablename__ = 'fees'
    
    student_id = db.Column(db.Integer, db.ForeignKey('students.id'), nullable=False, index=True)
    fee_structure_id = db.Column(db.Integer, db.ForeignKey('fee_structures.id'), nullable=True) # Optional for legacy data
    
    month = db.Column(db.Integer, nullable=False)
    year = db.Column(db.Integer, nullable=False)
    
    # Financials
    expected_amount = db.Column(db.Numeric(10, 2))  # Amount expected based on structure
    paid_amount = db.Column(db.Numeric(10, 2))      # Actual amount paid
    late_fee = db.Column(db.Numeric(10, 2), default=0)
    
    # Proof & Status
    proof_path = db.Column(db.String(255))
    status = db.Column(
        db.String(50), 
        nullable=False, 
        default='PENDING_ADMIN',
        index=True
    )
    
    # Dates & Meta
    due_date = db.Column(db.Date)
    paid_at = db.Column(db.BigInteger)      # When student paid
    approved_at = db.Column(db.BigInteger)  # When admin approved
    approved_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    rejection_reason = db.Column(db.Text)
    
    # Relationships
    student = db.relationship('Student', back_populates='fees')
    transactions = db.relationship('Transaction', back_populates='fee', cascade='all, delete-orphan')
    approved_by = db.relationship('User', foreign_keys=[approved_by_id])
    
    # Constraints
    __table_args__ = (
        db.UniqueConstraint('student_id', 'month', 'year', name='unique_fee_per_month'),
        db.CheckConstraint(
            status.in_(['UNPAID', 'PENDING_ADMIN', 'APPROVED', 'REJECTED', 'PAID', 'PARTIAL']),
            name='check_valid_fee_status'
        ),
    )
    
    def to_dict(self):
        """Convert fee to dictionary"""
        # Calculate pending details from transactions
        pending_txs = [t for t in self.transactions if t.status == 'PENDING']
        pending_amount = sum(float(t.amount) for t in pending_txs)
        pending_proofs = [t.proof_path for t in pending_txs if t.proof_path]
        
        return {
            'id': self.id,
            'student_id': self.student_id,
            'student_name': self.student.user.display_name if self.student and self.student.user else None,
            'student_admission_no': self.student.admission_no if self.student else None,
            'student_room': self.student.room if self.student else None,
            'student_image': self.student.profile_json.get('profile_picture') if self.student and self.student.profile_json else None,
            
            'structure_name': self.structure.name if self.fee_structure_id and getattr(self, 'structure', None) else None,
            'month': self.month,
            'year': self.year,
            'expected_amount': str(self.expected_amount) if self.expected_amount else None,
            'paid_amount': str(self.paid_amount) if self.paid_amount else None,
            'pending_amount': str(pending_amount),
            'pending_proofs': pending_proofs,
            
            'late_fee': str(self.late_fee) if self.late_fee else '0.00',
            'amount': str(self.paid_amount) if self.paid_amount else None, # Legacy compatibility
            'proof_path': self.proof_path,
            'status': self.status,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'paid_at': self.paid_at,
            'approved_at': self.approved_at,
            'approved_by': self.approved_by.display_name if self.approved_by else None,
            'rejection_reason': self.rejection_reason,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
