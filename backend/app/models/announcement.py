"""
Announcement model for broadcasting messages
"""
from app import db
from app.models.base import BaseModel

class Announcement(BaseModel):
    """
    Announcements sent by Admins or Teachers to users
    """
    __tablename__ = 'announcements'
    
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    priority = db.Column(db.String(20), default='normal')  # normal, high, critical
    
    # Announcement type: general, holiday, event
    announcement_type = db.Column(db.String(20), default='general')
    event_date = db.Column(db.Date, nullable=True)  # For holidays/events
    end_date = db.Column(db.Date, nullable=True)    # For multi-day events
    
    # Targeting
    target_role = db.Column(db.String(50), nullable=True)  # null = all, or specific role
    
    # Author
    author_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # Relationships
    author = db.relationship('User', backref='authored_announcements')
    
    def to_dict(self):
        """Convert to dictionary"""
        data = super().to_dict()
        data.update({
            'title': self.title,
            'content': self.content,
            'priority': self.priority,
            'announcement_type': self.announcement_type,
            'event_date': self.event_date.isoformat() if self.event_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'target_role': self.target_role,
            'author_id': self.author_id,
            'author_name': self.author.display_name if self.author else 'Unknown'
        })
        return data
