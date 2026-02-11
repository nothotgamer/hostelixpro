"""
Hostelix Pro - Hostel Management System
Flask application factory and configuration
"""
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()


def create_app(config_name='development'):
    """
    Application factory pattern
    Creates and configures the Flask application
    """
    app = Flask(__name__)
    
    # Configuration
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-me')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
        'DATABASE_URL', 
        'sqlite:///hostelixpro.db'
    )
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret-change-me')
    
    # CORS configuration
    cors_origins = os.getenv('CORS_ORIGINS', 'http://localhost:8080').split(',')
    CORS(app, origins=cors_origins, supports_credentials=True)
    
    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Register blueprints
    from app.api import auth_bp, users_bp, account_bp, reports_bp, routines_bp, fees_bp, announcements_bp, audit_bp, backups_bp, dashboard_bp, notifications_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    app.register_blueprint(users_bp, url_prefix='/api/v1/users')
    app.register_blueprint(account_bp, url_prefix='/api/v1/account')
    app.register_blueprint(reports_bp, url_prefix='/api/v1/reports')
    app.register_blueprint(routines_bp, url_prefix='/api/v1/routines')
    app.register_blueprint(fees_bp, url_prefix='/api/v1/fees')
    app.register_blueprint(announcements_bp, url_prefix='/api/v1/announcements')
    app.register_blueprint(audit_bp, url_prefix='/api/v1/audit')
    app.register_blueprint(backups_bp, url_prefix='/api/v1/backups')
    app.register_blueprint(dashboard_bp, url_prefix='/api/v1/dashboard')
    app.register_blueprint(notifications_bp, url_prefix='/api/v1/notifications')
    
    # Health check endpoint
    @app.route('/api/v1/health', methods=['GET'])
    def health_check():
        """Health check endpoint with server timestamp"""
        import time
        return jsonify({
            'status': 'healthy',
            'timestamp': int(time.time() * 1000),
            'service': 'Hostelix Pro API'
        }), 200
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Resource not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500
    
    @app.errorhandler(403)
    def forbidden(error):
        return jsonify({'error': 'Access forbidden'}), 403
    
    @app.errorhandler(401)
    def unauthorized(error):
        return jsonify({'error': 'Unauthorized'}), 401
    
    return app
