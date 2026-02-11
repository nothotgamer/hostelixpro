"""
Base model with common fields for all database models
"""
from app import db
import time


class BaseModel(db.Model):
    """
    Abstract base model with common fields
    All timestamps stored as Unix epoch milliseconds (bigint)
    Server-authoritative - never accept timestamps from client
    """
    __abstract__ = True
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    created_at = db.Column(db.BigInteger, nullable=False, default=lambda: int(time.time() * 1000))
    updated_at = db.Column(db.BigInteger, onupdate=lambda: int(time.time() * 1000))
    
    def to_dict(self):
        """Convert model to dictionary (override in subclasses)"""
        return {
            'id': self.id,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
    
    def update_timestamp(self):
        """Manually update the updated_at timestamp"""
        self.updated_at = int(time.time() * 1000)
