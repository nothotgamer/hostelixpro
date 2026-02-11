"""
Routine service for handling logic
"""
from app import db
from app.models.routine import Routine
from app.models.student import Student
from app.services.time_service import TimeService
from app.models.audit_log import AuditLog

class RoutineService:
    @staticmethod
    def create_request(user_id, type, payload=None):
        """
        Create routine request (walk, exit)
        """
        student = Student.query.filter_by(user_id=user_id).first()
        if not student:
            return None, "Student profile not found"
            
        # Check for active requests (pending OR approved-but-not-returned)
        active_statuses = ['PENDING_ROUTINE_MANAGER', 'APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL']
        active = Routine.query.filter(
            Routine.student_id == student.id,
            Routine.status.in_(active_statuses)
        ).first()
        
        if active:
            if active.status == 'PENDING_ROUTINE_MANAGER':
                return None, f"You already have a pending {active.type} request"
            else:
                return None, f"You are currently out on {active.type}. Please request return first."
            
        routine = Routine(
            type=type,
            student_id=student.id,
            request_time=TimeService.now_ms(),
            status='PENDING_ROUTINE_MANAGER',
            payload_json=payload,
            expected_return_time=payload.get('expected_return_time') if payload else None
        )
        
        db.session.add(routine)
        
        AuditLog.log(
            user_id=user_id,
            action=f'CREATE_{type.upper()}_REQUEST',
            entity='routine',
            entity_id=None,
            details=payload
        )
        
        db.session.commit()
        return routine, None

    @staticmethod
    def approve_request(routine_id, actor_id):
        """
        Approve routine request
        If type is exit, status becomes APPROVED_PENDING_RETURN
        If walk, status becomes COMPLETED (or APPROVED, depends on requirements)
        """
        routine = Routine.query.get(routine_id)
        if not routine:
            return None, "Routine request not found"
            
        if routine.status != 'PENDING_ROUTINE_MANAGER':
            return None, "Request not pending approval"
            
        new_status = 'COMPLETED'
        if routine.type == 'exit':
            new_status = 'APPROVED_PENDING_RETURN'
            
        routine.status = new_status
        routine.update_timestamp()
        
        AuditLog.log(
            user_id=actor_id,
            action='APPROVE_ROUTINE',
            entity='routine',
            entity_id=routine.id,
            details={'type': routine.type, 'new_status': new_status}
        )
        
        db.session.commit()
        return routine, None

    @staticmethod
    def request_return(routine_id, user_id):
        """
        Student requests return from exit
        """
        routine = Routine.query.get(routine_id)
        if not routine:
            return None, "Reference routine not found"
            
        # Verify ownership
        student = Student.query.filter_by(user_id=user_id).first()
        if not student or routine.student_id != student.id:
            return None, "Unauthorized"
            
        if routine.status != 'APPROVED_PENDING_RETURN':
            return None, "Routine not in correct state for return"
            
        routine.status = 'PENDING_RETURN_APPROVAL'
        routine.update_timestamp()
        
        # Create a linked return record if needed, or just update status
        # For simplicity, we track state on the original exit request
        
        AuditLog.log(
            user_id=user_id,
            action='REQUEST_RETURN',
            entity='routine',
            entity_id=routine.id
        )
        
        db.session.commit()
        return routine, None
        
    @staticmethod
    def confirm_return(routine_id, actor_id):
        """
        Manager confirms return
        """
        routine = Routine.query.get(routine_id)
        if not routine:
            return None, "Routine not found"
            
        if routine.status != 'PENDING_RETURN_APPROVAL':
            return None, "Routine not pending return approval"
            
        routine.status = 'COMPLETED'
        routine.update_timestamp()
        
        AuditLog.log(
            user_id=actor_id,
            action='CONFIRM_RETURN',
            entity='routine',
            entity_id=routine.id
        )
        
        db.session.commit()
        return routine, None

    @staticmethod
    def reject_request(routine_id, actor_id, reason):
        """
        Manager rejects routine request
        """
        routine = Routine.query.get(routine_id)
        if not routine:
            return None, "Routine not found"
            
        if routine.status not in ['PENDING_ROUTINE_MANAGER', 'PENDING_RETURN_APPROVAL']:
            return None, "Routine not pending approval"
            
        new_status = 'REJECTED' if routine.status == 'PENDING_ROUTINE_MANAGER' else 'RETURN_REJECTED'
        routine.status = new_status
        routine.rejection_reason = reason
        
        routine.update_timestamp()
        
        AuditLog.log(
            user_id=actor_id,
            action='REJECT_ROUTINE',
            entity='routine',
            entity_id=routine.id,
            details={'reason': reason, 'new_status': new_status}
        )
        
        db.session.commit()
        return routine, None
