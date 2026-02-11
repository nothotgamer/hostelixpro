import time
import socket
import os
import sys

def wait_for_postgres(host, port, timeout=60):
    start_time = time.time()
    while True:
        try:
            with socket.create_connection((host, port), timeout=1):
                print(f"PostgreSQL at {host}:{port} is reachable!")
                return True
        except (OSError, ConnectionRefusedError):
            if time.time() - start_time > timeout:
                print(f"Timeout waiting for PostgreSQL at {host}:{port}")
                return False
            print(f"Waiting for PostgreSQL at {host}:{port}...")
            time.sleep(1)

if __name__ == "__main__":
    db_url = os.getenv("DATABASE_URL")
    if not db_url or "postgresql://" not in db_url:
        print("DATABASE_URL not set or not using PostgreSQL. Skipping wait.")
        sys.exit(0)

    # Extract host and port from DATABASE_URL
    # Format: postgresql://user:pass@host:port/db
    try:
        from urllib.parse import urlparse
        result = urlparse(db_url)
        host = result.hostname
        port = result.port or 5432
        
        if not wait_for_postgres(host, port):
            sys.exit(1)
    except Exception as e:
        print(f"Error parsing DATABASE_URL: {e}")
        # Proceed anyway if parsing fails, might be using SQLite or complex URL
        sys.exit(0)
