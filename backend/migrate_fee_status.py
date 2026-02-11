"""
Migration: Rebuild fees table to update CHECK constraint with PARTIAL status.
SQLite doesn't support ALTER CHECK CONSTRAINT, so we recreate the table.
"""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'instance', 'hostelixpro.db')

def migrate():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    print(f"Migrating database at: {DB_PATH}")
    
    # Drop leftover temp table if exists
    cur.execute("DROP TABLE IF EXISTS fees_new")
    
    # Get existing columns
    cur.execute("PRAGMA table_info(fees)")
    columns = [row[1] for row in cur.fetchall()]
    print(f"Existing columns: {columns}")
    column_list = ', '.join(columns)
    
    # 1. Create new table with updated CHECK constraint
    cur.execute("""
        CREATE TABLE fees_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            fee_structure_id INTEGER,
            month INTEGER NOT NULL,
            year INTEGER NOT NULL,
            expected_amount NUMERIC(10,2),
            paid_amount NUMERIC(10,2),
            late_fee NUMERIC(10,2) DEFAULT 0,
            proof_path VARCHAR(255),
            status VARCHAR(50) NOT NULL DEFAULT 'PENDING_ADMIN',
            due_date DATE,
            paid_at BIGINT,
            approved_at BIGINT,
            approved_by_id INTEGER,
            rejection_reason TEXT,
            created_at BIGINT,
            updated_at BIGINT,
            FOREIGN KEY (student_id) REFERENCES students(id),
            FOREIGN KEY (fee_structure_id) REFERENCES fee_structures(id),
            FOREIGN KEY (approved_by_id) REFERENCES users(id),
            UNIQUE (student_id, month, year),
            CHECK (status IN ('UNPAID', 'PENDING_ADMIN', 'APPROVED', 'REJECTED', 'PAID', 'PARTIAL'))
        )
    """)
    
    # 2. Copy data using explicit column names
    cur.execute(f"""
        INSERT INTO fees_new ({column_list})
        SELECT {column_list} FROM fees
    """)
    
    rows = cur.execute("SELECT COUNT(*) FROM fees_new").fetchone()[0]
    print(f"Copied {rows} fee records")
    
    # 3. Drop old table
    cur.execute("DROP TABLE fees")
    
    # 4. Rename new table
    cur.execute("ALTER TABLE fees_new RENAME TO fees")
    
    # 5. Recreate indexes
    cur.execute("CREATE INDEX IF NOT EXISTS ix_fees_student_id ON fees(student_id)")
    cur.execute("CREATE INDEX IF NOT EXISTS ix_fees_status ON fees(status)")
    
    conn.commit()
    conn.close()
    print("Migration complete! PARTIAL status is now valid.")

if __name__ == '__main__':
    migrate()
