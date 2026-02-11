import os
import sqlite3
from app import create_app, db

def check_db(path):
    print(f"Checking {path}...")
    if not os.path.exists(path):
        print(f"  File not found")
        return

    try:
        conn = sqlite3.connect(path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='fee_structures'")
        result = cursor.fetchone()
        print(f"  fee_structures exists: {result is not None}")
        
        if result:
            print("  Dropping fee_structures...")
            cursor.execute("DROP TABLE fee_structures")
            conn.commit()
            print("  Dropped.")
        conn.close()
    except Exception as e:
        print(f"  Error: {e}")

if __name__ == "__main__":
    app = create_app()
    uri = app.config['SQLALCHEMY_DATABASE_URI']
    print(f"Config URI: {uri}")
    
    # Try to resolve relative path
    if uri.startswith('sqlite:///'):
        rel_path = uri.replace('sqlite:///', '')
        abs_path = os.path.join(os.getcwd(), rel_path)
        print(f"Resolved path (cwd): {abs_path}")
        check_db(abs_path)
        
        # Also check instance folder check
        instance_path = os.path.join(os.getcwd(), 'instance', rel_path)
        print(f"Resolved path (instance): {instance_path}")
        check_db(instance_path)
