"""
API blueprints package
"""
from flask import Blueprint

# Create blueprints
auth_bp = Blueprint('auth', __name__)
users_bp = Blueprint('users', __name__)
account_bp = Blueprint('account', __name__)
reports_bp = Blueprint('reports', __name__)
routines_bp = Blueprint('routines', __name__)
fees_bp = Blueprint('fees', __name__)
announcements_bp = Blueprint('announcements', __name__)
audit_bp = Blueprint('audit', __name__)
backups_bp = Blueprint('backups', __name__)
dashboard_bp = Blueprint('dashboard', __name__)
notifications_bp = Blueprint('notifications', __name__)

# Import routes (must be after blueprint creation to avoid circular imports)
from app.api import auth, users, account, reports, routines, fees, announcements, audit, backups, dashboard, notifications

__all__ = ['auth_bp', 'users_bp', 'account_bp', 'reports_bp', 'routines_bp', 'fees_bp', 'announcements_bp', 'audit_bp', 'backups_bp', 'dashboard_bp', 'notifications_bp']


