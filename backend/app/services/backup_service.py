"""
Backup and Restore Service
"""
import os
import shutil
import sqlite3
import time
from datetime import datetime
from flask import current_app
from app import db
from app.models.backup_meta import BackupMeta
from app.utils.encryption import BackupEncryption
from app.services.time_service import TimeService

class BackupService:
    @staticmethod
    def _get_db_path():
        """Get path to SQLite database file"""
        # Usually instance/hostelixpro.db
        uri = current_app.config['SQLALCHEMY_DATABASE_URI']
        if uri.startswith('sqlite:///'):
            path = uri.replace('sqlite:///', '')
            if not os.path.isabs(path):
                path = os.path.join(current_app.root_path, '..', path) # backend/app/../instance/db
                # Actually flask instance folder handling is specific
                # Let's try to resolve it relative to instance folder if not absolute
                if not os.path.exists(path):
                    # Try instance folder
                    path = os.path.join(current_app.instance_path, uri.replace('sqlite:///', ''))
            return os.path.normpath(path)
        return None

    @staticmethod
    def _get_backup_dir():
        """Get backup directory, create if not exists"""
        path = os.path.join(current_app.root_path, '..', 'backups')
        if not os.path.exists(path):
            os.makedirs(path)
        return path

    @staticmethod
    def create_backup(user_id, encryption_key_str=None):
        """
        Create encrypted backup
        Returns: BackupMeta object, key (if generated)
        """
        db_path = BackupService._get_db_path()
        if not db_path or not os.path.exists(db_path):
            raise Exception(f"Database file not found at {db_path}")

        backup_dir = BackupService._get_backup_dir()
        timestamp = TimeService.now_ms()
        temp_file = os.path.join(backup_dir, f"temp_{timestamp}.db")
        final_filename = f"backup_{timestamp}.enc"
        final_path = os.path.join(backup_dir, final_filename)

        # 1. Create a safe copy of SQLite DB
        # We use sqlite3 backup API to get a consistent snapshot
        try:
            # Source connection
            src = sqlite3.connect(db_path)
            # Destination connection
            dst = sqlite3.connect(temp_file)
            with dst:
                src.backup(dst)
            dst.close()
            src.close()
        except Exception as e:
            if os.path.exists(temp_file):
                os.remove(temp_file)
            raise Exception(f"Failed to copy database: {e}")

        # 2. Encrypt
        key = None
        if encryption_key_str:
            key = BackupEncryption.key_from_string(encryption_key_str)
        else:
            key = BackupEncryption.generate_key()
            
        try:
            BackupEncryption.encrypt_file(temp_file, final_path, key)
        finally:
            # Clean up temp
            if os.path.exists(temp_file):
                os.remove(temp_file)

        # 3. Create Record
        size = os.path.getsize(final_path)
        backup = BackupMeta(
            filename=final_filename,
            file_size_bytes=size,
            created_by_id=user_id
        )
        db.session.add(backup)
        db.session.commit()

        return backup, BackupEncryption.key_to_string(key)

    @staticmethod
    def restore_backup(backup_id, key_str):
        """
        Restore verification (Dry run decryption)
        Actual restore overwriting DB is dangerous in running app.
        For this MVP, we will simpler check if it decrypts successfully.
        """
        backup = BackupMeta.query.get(backup_id)
        if not backup:
            raise Exception("Backup not found")

        backup_dir = BackupService._get_backup_dir()
        file_path = os.path.join(backup_dir, backup.filename)
        
        if not os.path.exists(file_path):
            raise Exception("Backup file missing from disk")

        # Try decrypting
        try:
            key = BackupEncryption.key_from_string(key_str)
            timestamp = TimeService.now_ms()
            temp_restore_path = os.path.join(backup_dir, f"restore_verify_{timestamp}.db")
            
            BackupEncryption.decrypt_file(file_path, temp_restore_path, key)
            
            # Verify it's a valid DB
            conn = sqlite3.connect(temp_restore_path)
            cursor = conn.cursor()
            cursor.execute("SELECT count(*) FROM users")
            count = cursor.fetchone()[0]
            conn.close()
            
            # Cleanup
            if os.path.exists(temp_restore_path):
                os.remove(temp_restore_path)
                
            return True, f"Backup verified! Contain {count} users."
            
        except Exception as e:
            return False, f"Decryption/Verification failed: {e}"
