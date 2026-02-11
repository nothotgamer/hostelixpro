"""
Notification model for user-specific notifications
"""
from app import db
from app.models.base import BaseModel


class Notification(BaseModel):
    """
    User-specific notifications with read status
    """
    __tablename__ = 'notifications'
    
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    title = db.Column(db.String(255), nullable=False)
    message = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), default='info')  # info, success, warning, error
    is_read = db.Column(db.Boolean, default=False, nullable=False)
    action_url = db.Column(db.String(255))  # Optional deep link
    entity_type = db.Column(db.String(50))  # Optional: routine, fee, announcement
    entity_id = db.Column(db.Integer)  # Optional: ID of related entity
    
    # Relationships
    user = db.relationship('User', backref='notifications')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'message': self.message,
            'type': self.type,
            'is_read': self.is_read,
            'action_url': self.action_url,
            'entity_type': self.entity_type,
            'entity_id': self.entity_id,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
