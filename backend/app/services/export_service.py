"""
Export Service for PDF and Excel generation
"""
import io
import os
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from openpyxl import Workbook
from app.models.fee import Fee
from app.models.user import User
from app.models.report import Report

class ExportService:
    
    @staticmethod
    def generate_fee_challan(fee_id):
        """
        Generate PDF Fee Challan
        Returns bio (BytesIO)
        """
        fee = Fee.query.get(fee_id)
        if not fee:
            raise Exception("Fee not found")
        
        user = User.query.get(fee.user_id)
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        elements = []
        styles = getSampleStyleSheet()
        
        # Header
        elements.append(Paragraph(f"HOSTELIX PRO - FEE CHALLAN", styles['Title']))
        elements.append(Spacer(1, 20))
        
        # Info Table
        data = [
            ["Challan ID:", f"#{fee.id}"],
            ["Student Name:", user.display_name if user else "Unknown"],
            ["Email:", user.email if user else "Unknown"],
            ["Month/Year:", f"{datetime(fee.year, fee.month, 1).strftime('%B %Y')}"],
            ["Generated Date:", datetime.now().strftime("%Y-%m-%d")],
            ["Status:", fee.status]
        ]
        
        t = Table(data, colWidths=[150, 300])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ]))
        elements.append(t)
        elements.append(Spacer(1, 40))
        
        # Amount Box
        amount_data = [
            ["DESCRIPTION", "AMOUNT"],
            ["Hostel Monthly Fee", f"${fee.amount}"],
            ["Utility Charges", "$0.00"],
            ["Fine/Other", "$0.00"],
            ["TOTAL PAYABLE", f"${fee.amount}"]
        ]
        
        t2 = Table(amount_data, colWidths=[300, 150])
        t2.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (1, 0), colors.darkblue),
            ('TEXTCOLOR', (0, 0), (1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('BACKGROUND', (0, -1), (-1, -1), colors.lightgrey), # Total row
            ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ]))
        elements.append(t2)
        
        elements.append(Spacer(1, 50))
        elements.append(Paragraph("__________________________", styles['Normal']))
        elements.append(Paragraph("Authorized Signature", styles['Normal']))
        
        doc.build(elements)
        buffer.seek(0)
        return buffer

    @staticmethod
    def generate_reports_excel():
        """
        Generate Excel list of all student reports
        Returns bio (BytesIO)
        """
        reports = Report.query.order_by(Report.created_at.desc()).limit(1000).all()
        
        wb = Workbook()
        ws = wb.active
        ws.title = "Student Reports"
        
        # Headers
        headers = ["ID", "Student", "Room", "Status", "Wake Time", "Walk", "Exercise", "Late Mins"]
        ws.append(headers)
        
        for r in reports:
            student_name = "Unknown"
            student_room = "N/A"
            if r.student and r.student.user:
                student_name = r.student.user.display_name
                student_room = r.student.room
            
            wake_time_str = datetime.fromtimestamp(r.wake_time/1000).strftime('%Y-%m-%d %H:%M:%S')
            
            row = [
                r.id,
                student_name,
                student_room,
                r.status,
                wake_time_str,
                "Yes" if r.walk else "No",
                "Yes" if r.exercise else "No",
                r.late_minutes
            ]
            ws.append(row)
            
        buffer = io.BytesIO()
        wb.save(buffer)
        buffer.seek(0)
        return buffer
