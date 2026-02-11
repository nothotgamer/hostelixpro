from app import create_app, db
from app.models.announcement import Announcement
from sqlalchemy import inspect

app = create_app()

with app.app_context():
    inspector = inspect(db.engine)
    columns = [c['name'] for c in inspector.get_columns('announcements')]
    print(f"Columns in announcements table: {columns}")
    
    if 'end_date' in columns:
        print("SUCCESS: end_date column exists.")
        # Try a query
        try:
            cnt = Announcement.query.count()
            print(f"Query successful. Count: {cnt}")
        except Exception as e:
            print(f"Query failed: {e}")
    else:
        print("FAILURE: end_date column MISSING.")
