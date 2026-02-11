"""
Server-authoritative time service
All timestamps must be generated server-side
"""
import time
from datetime import datetime, timezone


class TimeService:
    """
    Centralized time service for server-authoritative timestamps
    Returns Unix epoch milliseconds as bigint
    """
    
    @staticmethod
    def now_ms():
        """Get current timestamp in Unix epoch milliseconds"""
        return int(time.time() * 1000)
    
    @staticmethod
    def now_seconds():
        """Get current timestamp in Unix epoch seconds"""
        return int(time.time())
    
    @staticmethod
    def from_seconds(seconds):
        """Convert seconds to milliseconds"""
        return int(seconds * 1000)
    
    @staticmethod
    def to_seconds(milliseconds):
        """Convert milliseconds to seconds"""
        return int(milliseconds / 1000)
    
    @staticmethod
    def today_start_ms():
        """Get start of today (midnight) in Unix epoch milliseconds"""
        now = datetime.now(timezone.utc)
        start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
        return int(start_of_day.timestamp() * 1000)
    
    @staticmethod
    def today_date_str():
        """Get today's date as YYYY-MM-DD string"""
        return datetime.now(timezone.utc).strftime('%Y-%m-%d')

