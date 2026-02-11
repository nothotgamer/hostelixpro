"""
Fee service for handling payments
"""
from app import db
from app.models.fee import Fee
from app.models.fee_structure import FeeStructure
from app.models.student import Student
from app.services.time_service import TimeService
from app.models.audit_log import AuditLog
from datetime import date

from app.models.transaction import Transaction

class FeeService:
    @staticmethod
    def add_transaction(user_id, month, year, amount, proof_path=None, payment_method='manual', reference=None):
        student = Student.query.filter_by(user_id=user_id).first()
        if not student:
            return None, "Student profile not found"
            
        # Get or Create Fee Record
        fee = Fee.query.filter_by(
            student_id=student.id,
            month=month,
            year=year
        ).first()
        
        if not fee:
            # Determine expected amount
            expected = student.monthly_fee_amount or 0
            if not expected and student.fee_structure_id:
                structure = FeeStructure.query.get(student.fee_structure_id)
                if structure:
                    expected = structure.monthly_amount
            
            # Create new Fee record
            fee = Fee(
                student_id=student.id,
                month=month,
                year=year,
                expected_amount=expected,
                paid_amount=0,
                status='PENDING_ADMIN', # Use default valid status instead of UNPAID
                created_at=TimeService.now_ms()
            )
            db.session.add(fee)
            db.session.flush() # Get ID
            
        # Check if already fully paid
        if fee.status == 'PAID' or fee.status == 'APPROVED':
            return None, "Fee for this month is already fully paid"

        # Create Transaction
        try:
            amount_val = float(amount)
        except (ValueError, TypeError):
            return None, "Invalid amount format"

        # Check Payment Limits
        # Calculate pending amount from other pending transactions
        pending_txs = Transaction.query.filter_by(fee_id=fee.id, status='PENDING').all()
        pending_sum = sum(t.amount for t in pending_txs)
        
        # Calculate max allowable payment
        remaining_limit = float(fee.expected_amount or 0) - float(fee.paid_amount or 0) - pending_sum
        
        # Allow small floating point margin or exact check. Using exact check for now.
        if amount_val > remaining_limit:
             return None, f"Amount exceeds remaining balance. Max allowed: {remaining_limit}"

        transaction = Transaction(
            fee_id=fee.id,
            amount=amount_val,
            transaction_date=TimeService.now_ms(),
            payment_method=payment_method,
            transaction_reference=reference,
            proof_path=proof_path,
            status='PENDING'
        )
        
        db.session.add(transaction)
        
        # Update Fee status to indicate pending action if not already partial/paid
        if fee.status == 'PENDING_ADMIN' or fee.status == 'UNPAID' or fee.status == 'REJECTED': 
             # Ensure it is PENDING_ADMIN (though initialized as such above)
             fee.status = 'PENDING_ADMIN'
            
        AuditLog.log(user_id, 'SUBMIT_FEE_TRANSACTION', 'transaction', transaction.id)
        db.session.commit()
        return transaction, None

    @staticmethod
    def approve_transaction(transaction_id, admin_id):
        trx = Transaction.query.get(transaction_id)
        if not trx:
            return None, "Transaction not found"
            
        if trx.status == 'APPROVED':
            return None, "Transaction already approved"
            
        fee = Fee.query.get(trx.fee_id)
        
        # Approve Transaction
        trx.status = 'APPROVED'
        trx.approved_at = TimeService.now_ms()
        trx.approved_by_id = admin_id
        
        # Update Fee Totals
        fee.paid_amount = (fee.paid_amount or 0) + trx.amount
        fee.approved_at = TimeService.now_ms()
        fee.approved_by_id = admin_id
        
        # Update Fee Status based on payment completeness
        if fee.paid_amount >= fee.expected_amount:
            fee.status = 'APPROVED'
            fee.paid_at = TimeService.now_ms()
        else:
            # Check if there are still pending transactions remaining
            db.session.flush()
            remaining_pending = Transaction.query.filter(
                Transaction.fee_id == fee.id,
                Transaction.id != trx.id,
                Transaction.status == 'PENDING'
            ).count()
            
            if remaining_pending > 0:
                fee.status = 'PENDING_ADMIN'  # Still has pending transactions
            else:
                fee.status = 'PARTIAL'  # Partially paid, no more pending
            
        AuditLog.log(admin_id, 'APPROVE_TRANSACTION', 'transaction', trx.id)
        db.session.commit()
        return trx, None

    @staticmethod
    def reject_transaction(transaction_id, admin_id, reason):
        trx = Transaction.query.get(transaction_id)
        if not trx:
            return None, "Transaction not found"
        
        if trx.status == 'REJECTED':
            return None, "Transaction already rejected"
            
        trx.status = 'REJECTED'
        trx.rejection_reason = reason
        trx.approved_by_id = admin_id 
        trx.approved_at = TimeService.now_ms()
        
        # Flush so the status change is visible in subsequent queries
        db.session.flush()
        
        fee = Fee.query.get(trx.fee_id)
        
        # Check remaining active transactions (excluding this one which is now REJECTED)
        remaining_pending = Transaction.query.filter(
            Transaction.fee_id == fee.id,
            Transaction.status == 'PENDING'
        ).count()
        
        remaining_approved = Transaction.query.filter(
            Transaction.fee_id == fee.id,
            Transaction.status == 'APPROVED'
        ).count()
        
        if remaining_pending == 0 and remaining_approved == 0 and (fee.paid_amount or 0) == 0:
            # No active transactions and nothing paid — mark fee as rejected
            fee.status = 'REJECTED'
            fee.rejection_reason = reason
        elif remaining_pending == 0 and (fee.paid_amount or 0) > 0:
            # Some amount was paid but no more pending — it's partial
            fee.status = 'PARTIAL'
        elif remaining_pending > 0:
            fee.status = 'PENDING_ADMIN'  # Still has pending transactions
        
        AuditLog.log(admin_id, 'REJECT_TRANSACTION', 'transaction', trx.id)
        db.session.commit()
        return trx, None
        
    @staticmethod
    def get_student_fees(student_id, year=None):
        query = Fee.query.filter_by(student_id=student_id)
        if year:
            query = query.filter_by(year=year)
        return query.order_by(Fee.year.desc(), Fee.month.desc()).all()
