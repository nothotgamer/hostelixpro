"""
Backup Metadata Model
"""
from app import db
from app.models.base import BaseModel

class BackupMeta(BaseModel):
    """
    Metadata for encrypted backup files
    """
    __tablename__ = 'backups'

    filename = db.Column(db.String(255), nullable=False)
    file_size_bytes = db.Column(db.BigInteger, nullable=False)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    
    # User who created the backup
    created_by = db.relationship('User', backref='backups')

    def to_dict(self):
        data = super().to_dict()
        data.update({
            'filename': self.filename,
            'file_size_bytes': self.file_size_bytes,
            'created_by': self.created_by.display_name if self.created_by else 'System'
        })
        return data
