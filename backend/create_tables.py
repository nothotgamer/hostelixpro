"""
Script to create tables
"""
from app import create_app, db
from app.models.announcement import Announcement
from app.models.backup_meta import BackupMeta

def create_tables():
    app = create_app()
    with app.app_context():
        print("Creating tables...")
        db.create_all()
        print("Done!")

if __name__ == "__main__":
    create_tables()
