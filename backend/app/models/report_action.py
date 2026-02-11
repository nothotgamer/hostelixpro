"""
Report action model for tracking approvals and rejections
"""
from app import db
import time


class ReportAction(db.Model):
    """
    Track history of actions on a report (approvals, rejections)
    """
    __tablename__ = 'report_actions'
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    report_id = db.Column(db.Integer, db.ForeignKey('reports.id'), nullable=False)
    actor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    action = db.Column(db.String(50), nullable=False)  # APPROVE, REJECT, COMMENT
    notes = db.Column(db.Text)
    timestamp = db.Column(db.BigInteger, nullable=False, default=lambda: int(time.time() * 1000))
    
    # Relationships
    actor = db.relationship('User', backref='report_actions')
    
    def to_dict(self):
        """Convert action to dictionary"""
        return {
            'id': self.id,
            'report_id': self.report_id,
            'actor_id': self.actor_id,
            'actor_name': self.actor.display_name if self.actor else 'Unknown',
            'actor_role': self.actor.role if self.actor else 'unknown',
            'action': self.action,
            'notes': self.notes,
            'timestamp': self.timestamp
        }
