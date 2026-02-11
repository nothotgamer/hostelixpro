"""
Transaction model for fee payments
"""
from app import db
from app.models.base import BaseModel
from datetime import datetime

class Transaction(BaseModel):
    """
    Individual fee payment transaction
    """
    __tablename__ = 'transactions'

    fee_id = db.Column(db.Integer, db.ForeignKey('fees.id'), nullable=False, index=True)
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    transaction_date = db.Column(db.BigInteger, nullable=False)  # Timestamp
    payment_method = db.Column(db.String(50), nullable=False)    # bank_transfer, cash, etc.
    transaction_reference = db.Column(db.String(100))            # Receipt No, TRX ID
    proof_path = db.Column(db.String(255))                       # Image path
    
    status = db.Column(
        db.String(20), 
        nullable=False, 
        default='PENDING',
        index=True
    )  # PENDING, APPROVED, REJECTED
    
    rejection_reason = db.Column(db.Text)
    approved_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    approved_at = db.Column(db.BigInteger)

    # Relationships
    fee = db.relationship('Fee', back_populates='transactions')
    approved_by = db.relationship('User', foreign_keys=[approved_by_id])

    def to_dict(self):
        return {
            'id': self.id,
            'fee_id': self.fee_id,
            'amount': str(self.amount),
            'transaction_date': self.transaction_date,
            'payment_method': self.payment_method,
            'transaction_reference': self.transaction_reference,
            'proof_path': self.proof_path,
            'status': self.status,
            'rejection_reason': self.rejection_reason,
            'approved_by': self.approved_by.display_name if self.approved_by else None,
            'approved_at': self.approved_at,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
