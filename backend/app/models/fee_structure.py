"""
Fee Structure model for defining monthly fee configurations
"""
from app import db
from app.models.base import BaseModel

class FeeStructure(BaseModel):
    """
    Configuration for monthly fees
    """
    __tablename__ = 'fee_structures'
    
    name = db.Column(db.String(100), nullable=False)  # e.g. "Standard Room Fee 2024"
    monthly_amount = db.Column(db.Numeric(10, 2), nullable=False)
    late_fee_per_day = db.Column(db.Numeric(10, 2), default=0)
    due_day = db.Column(db.Integer, default=5)  # Day of month when fee is due
    is_active = db.Column(db.Boolean, default=True, index=True)
    description = db.Column(db.Text)
    
    # Relationships
    fees = db.relationship('Fee', backref='structure', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'monthly_amount': str(self.monthly_amount),
            'late_fee_per_day': str(self.late_fee_per_day),
            'due_day': self.due_day,
            'is_active': self.is_active,
            'description': self.description,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
    
    def __repr__(self):
        return f'<FeeStructure {self.name}>'
