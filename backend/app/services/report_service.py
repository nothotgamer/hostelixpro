"""
Report service for workflow logic
"""
from app import db
from app.models.report import Report
from app.models.report_action import ReportAction
from app.models.student import Student
from app.services.time_service import TimeService
from app.models.audit_log import AuditLog
from datetime import datetime, timedelta

class ReportService:
    """
    Business logic for student reports
    """
    
    @staticmethod
    def get_todays_report(student_id):
        """
        Get student's report for the current 24h period
        Logic: Check for report created in last 20 hours (approx day)
        """
        # Simple check: Is there a report from "today" (since midnight local or last 24h)
        # Using 18 hours as a safe "same day" window for wake up reports
        cutoff_time = TimeService.now_ms() - (18 * 60 * 60 * 1000)
        
        return Report.query.filter(
            Report.student_id == student_id,
            Report.wake_time > cutoff_time
        ).first()

    @staticmethod
    def create_daily_report(user_id, student_id):
        """
        Create a new daily report (Wake Up)
        Enforces one report per day rule
        """
        # Check if report already exists for today
        existing = ReportService.get_todays_report(student_id)
        if existing:
            return None, "Report already submitted for today"
            
        # Create report
        report = Report(
            student_id=student_id,
            wake_time=TimeService.now_ms(),
            status='PENDING_TEACHER'
        )
        
        db.session.add(report)
        
        # Log action
        AuditLog.log(
            user_id=user_id,
            action='CREATE_REPORT',
            entity='report',
            entity_id=None, # ID available after flush
            details={'student_id': student_id}
        )
        
        db.session.commit()
        return report, None

    @staticmethod
    def approve_report(report_id, actor_id, actor_role, notes=None):
        """
        Approve report based on role
        Teacher -> PENDING_ADMIN
        Admin -> APPROVED
        """
        report = Report.query.get(report_id)
        if not report:
            return None, "Report not found"
            
        old_status = report.status
        new_status = old_status
        action_type = "APPROVE"
        
        # Role-based transition logic
        if actor_role == 'teacher':
            if report.status != 'PENDING_TEACHER':
                return None, "Report not pending teacher approval"
            new_status = 'PENDING_ADMIN'
            
        elif actor_role == 'admin':
            if report.status != 'PENDING_ADMIN':
                # Admins can technically override, but let's follow flow for now
                 if report.status == 'PENDING_TEACHER':
                     # Admin effectively auto-approves teacher step too
                     pass 
                 elif report.status == 'APPROVED':
                     return None, "Report already approved"
            new_status = 'APPROVED'
        else:
            return None, "Unauthorized role for approval"
            
        # Update report
        report.status = new_status
        report.update_timestamp()
        
        # Record action
        action = ReportAction(
            report_id=report.id,
            actor_id=actor_id,
            action=action_type,
            notes=notes,
            timestamp=TimeService.now_ms()
        )
        db.session.add(action)
        
        # Audit log
        AuditLog.log(
            user_id=actor_id,
            action=f'APPROVE_REPORT_{actor_role.upper()}',
            entity='report',
            entity_id=report.id,
            details={'old_status': old_status, 'new_status': new_status}
        )
        
        db.session.commit()
        return report, None

    @staticmethod
    def reject_report(report_id, actor_id, notes):
        """
        Reject a report
        """
        report = Report.query.get(report_id)
        if not report:
            return None, "Report not found"
            
        report.status = 'REJECTED'
        report.update_timestamp()
        
        action = ReportAction(
            report_id=report.id,
            actor_id=actor_id,
            action='REJECT',
            notes=notes,
            timestamp=TimeService.now_ms()
        )
        db.session.add(action)
        
        AuditLog.log(
            user_id=actor_id,
            action='REJECT_REPORT',
            entity='report',
            entity_id=report.id,
            details={'reason': notes}
        )
        
        db.session.commit()
        return report, None
