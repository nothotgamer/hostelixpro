"""
Hostelix Pro — Professional Features Document PDF Generator
Generates a high-quality, branded PDF from the project features.
"""

import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether
)
from reportlab.platypus.flowables import Flowable
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.fonts import addMapping

# ─── Color Palette ───────────────────────────────────────────────────────────
PRIMARY      = HexColor("#1a1a2e")   # Deep navy
ACCENT       = HexColor("#0f3460")   # Royal blue
HIGHLIGHT    = HexColor("#e94560")   # Electric red
LIGHT_BG     = HexColor("#f8f9fa")   # Light gray bg
TABLE_HEADER = HexColor("#16213e")   # Dark blue header
TABLE_ALT    = HexColor("#eef1f6")   # Alternating row
TEXT_DARK    = HexColor("#1a1a2e")
TEXT_MEDIUM  = HexColor("#4a5568")
TEXT_LIGHT   = HexColor("#718096")
BORDER       = HexColor("#cbd5e0")
SUCCESS      = HexColor("#38a169")
WHITE        = white

# ─── Page dimensions ─────────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4
MARGIN = 2 * cm

# ─── Styles ──────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

def create_styles():
    """Create custom paragraph styles for the document."""
    custom = {}
    
    custom['CoverTitle'] = ParagraphStyle(
        'CoverTitle', parent=styles['Title'],
        fontSize=36, leading=44, textColor=WHITE,
        alignment=TA_CENTER, spaceAfter=10,
        fontName='Helvetica-Bold'
    )
    custom['CoverSubtitle'] = ParagraphStyle(
        'CoverSubtitle', parent=styles['Normal'],
        fontSize=14, leading=20, textColor=HexColor("#a0aec0"),
        alignment=TA_CENTER, spaceAfter=6,
        fontName='Helvetica'
    )
    custom['CoverMeta'] = ParagraphStyle(
        'CoverMeta', parent=styles['Normal'],
        fontSize=11, leading=16, textColor=HexColor("#718096"),
        alignment=TA_CENTER, spaceAfter=4,
        fontName='Helvetica'
    )
    custom['SectionTitle'] = ParagraphStyle(
        'SectionTitle', parent=styles['Heading1'],
        fontSize=20, leading=26, textColor=PRIMARY,
        spaceBefore=20, spaceAfter=10,
        fontName='Helvetica-Bold',
        borderWidth=0, borderPadding=0,
        borderColor=HIGHLIGHT,
    )
    custom['SubsectionTitle'] = ParagraphStyle(
        'SubsectionTitle', parent=styles['Heading2'],
        fontSize=14, leading=18, textColor=ACCENT,
        spaceBefore=14, spaceAfter=6,
        fontName='Helvetica-Bold',
    )
    custom['BodyText'] = ParagraphStyle(
        'BodyText', parent=styles['Normal'],
        fontSize=10, leading=15, textColor=TEXT_DARK,
        alignment=TA_JUSTIFY, spaceAfter=6,
        fontName='Helvetica'
    )
    custom['BulletItem'] = ParagraphStyle(
        'BulletItem', parent=styles['Normal'],
        fontSize=10, leading=15, textColor=TEXT_DARK,
        leftIndent=18, spaceAfter=3,
        fontName='Helvetica',
        bulletIndent=6,
    )
    custom['TableHeader'] = ParagraphStyle(
        'TableHeader', parent=styles['Normal'],
        fontSize=9, leading=12, textColor=WHITE,
        fontName='Helvetica-Bold',
    )
    custom['TableCell'] = ParagraphStyle(
        'TableCell', parent=styles['Normal'],
        fontSize=9, leading=12, textColor=TEXT_DARK,
        fontName='Helvetica',
    )
    custom['Footer'] = ParagraphStyle(
        'Footer', parent=styles['Normal'],
        fontSize=8, leading=10, textColor=TEXT_LIGHT,
        alignment=TA_CENTER,
        fontName='Helvetica',
    )
    custom['TOCItem'] = ParagraphStyle(
        'TOCItem', parent=styles['Normal'],
        fontSize=11, leading=22, textColor=ACCENT,
        fontName='Helvetica',
        leftIndent=10,
    )
    custom['Caption'] = ParagraphStyle(
        'Caption', parent=styles['Normal'],
        fontSize=9, leading=12, textColor=TEXT_MEDIUM,
        alignment=TA_LEFT, spaceAfter=4, spaceBefore=2,
        fontName='Helvetica-Oblique',
    )
    return custom

S = create_styles()


# ─── Custom Flowables ────────────────────────────────────────────────────────
class ColoredBlock(Flowable):
    """A colored header block for section titles."""
    def __init__(self, text, width=None):
        Flowable.__init__(self)
        self.text = text
        self._width = width or (PAGE_W - 2 * MARGIN)
        self.height = 14 * mm
        
    def draw(self):
        self.canv.setFillColor(PRIMARY)
        self.canv.roundRect(0, 0, self._width, self.height, 3, fill=1, stroke=0)
        self.canv.setFillColor(HIGHLIGHT)
        self.canv.rect(0, 0, 4, self.height, fill=1, stroke=0)
        self.canv.setFillColor(WHITE)
        self.canv.setFont("Helvetica-Bold", 13)
        self.canv.drawString(14, self.height / 2 - 4, self.text)


class AccentLine(Flowable):
    """A thin accent line separator."""
    def __init__(self, width=None, color=HIGHLIGHT):
        Flowable.__init__(self)
        self._width = width or (PAGE_W - 2 * MARGIN)
        self.height = 2
        self.color = color
        
    def draw(self):
        self.canv.setStrokeColor(self.color)
        self.canv.setLineWidth(1.5)
        self.canv.line(0, 0, self._width * 0.3, 0)
        self.canv.setStrokeColor(BORDER)
        self.canv.setLineWidth(0.5)
        self.canv.line(self._width * 0.3, 0, self._width, 0)


# ─── Helper Functions ────────────────────────────────────────────────────────

def make_table(headers, rows, col_widths=None):
    """Create a professionally styled table."""
    w = PAGE_W - 2 * MARGIN
    
    header_cells = [Paragraph(h, S['TableHeader']) for h in headers]
    data = [header_cells]
    for row in rows:
        data.append([Paragraph(str(cell), S['TableCell']) for cell in row])
    
    if col_widths is None:
        n = len(headers)
        col_widths = [w / n] * n
    
    t = Table(data, colWidths=col_widths, repeatRows=1)
    
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 5),
        ('TOPPADDING', (0, 1), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, TABLE_ALT]),
    ]
    t.setStyle(TableStyle(style_cmds))
    return t

def bullet(text):
    return Paragraph(f"•  {text}", S['BulletItem'])

def body(text):
    return Paragraph(text, S['BodyText'])

def section(num, title):
    return ColoredBlock(f"  {num}.  {title}")

def subsection(title):
    return Paragraph(title, S['SubsectionTitle'])

def spacer(h=6):
    return Spacer(1, h)

# ─── Page Templates ──────────────────────────────────────────────────────────

def cover_page(canvas, doc):
    """Draw the cover page background."""
    canvas.saveState()
    # Full page dark background
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    
    # Accent stripe at top
    canvas.setFillColor(HIGHLIGHT)
    canvas.rect(0, PAGE_H - 8, PAGE_W, 8, fill=1, stroke=0)
    
    # Geometric accent
    canvas.setFillColor(ACCENT)
    canvas.rect(0, PAGE_H * 0.38, PAGE_W, 2, fill=1, stroke=0)
    
    # Bottom bar
    canvas.setFillColor(HexColor("#0f3460"))
    canvas.rect(0, 0, PAGE_W, 60, fill=1, stroke=0)
    canvas.setFillColor(HexColor("#718096"))
    canvas.setFont("Helvetica", 8)
    canvas.drawCentredString(PAGE_W / 2, 28, "This document is confidential and intended for authorized personnel only.")
    canvas.drawCentredString(PAGE_W / 2, 16, "© 2026 Hostelix Pro. All rights reserved.")
    
    canvas.restoreState()

def normal_page(canvas, doc):
    """Header and footer for content pages."""
    canvas.saveState()
    
    # Header line
    canvas.setStrokeColor(PRIMARY)
    canvas.setLineWidth(1)
    canvas.line(MARGIN, PAGE_H - MARGIN + 10, PAGE_W - MARGIN, PAGE_H - MARGIN + 10)
    
    # Header accent
    canvas.setStrokeColor(HIGHLIGHT)
    canvas.setLineWidth(2)
    canvas.line(MARGIN, PAGE_H - MARGIN + 10, MARGIN + 40, PAGE_H - MARGIN + 10)
    
    # Header text
    canvas.setFont("Helvetica-Bold", 8)
    canvas.setFillColor(TEXT_MEDIUM)
    canvas.drawString(MARGIN, PAGE_H - MARGIN + 14, "HOSTELIX PRO")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(PAGE_W - MARGIN, PAGE_H - MARGIN + 14, "Product Features Document")
    
    # Footer
    canvas.setStrokeColor(BORDER)
    canvas.setLineWidth(0.5)
    canvas.line(MARGIN, MARGIN - 10, PAGE_W - MARGIN, MARGIN - 10)
    
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(TEXT_LIGHT)
    canvas.drawString(MARGIN, MARGIN - 22, "Hostelix Pro v1.0")
    canvas.drawCentredString(PAGE_W / 2, MARGIN - 22, f"Page {doc.page}")
    canvas.drawRightString(PAGE_W - MARGIN, MARGIN - 22, "February 2026")
    
    canvas.restoreState()


# ─── Document Builder ────────────────────────────────────────────────────────

def build_document():
    """Build the complete PDF document."""
    
    output_path = os.path.join(os.path.dirname(__file__), "Hostelix_Pro_Features.pdf")
    
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        topMargin=MARGIN + 8 * mm,
        bottomMargin=MARGIN,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        title="Hostelix Pro — Product Features Document",
        author="Hostelix Pro Team",
        subject="Complete Feature Documentation",
    )
    
    story = []
    w = PAGE_W - 2 * MARGIN
    
    # ══════════════════════════════════════════════════════════════════════════
    # COVER PAGE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, PAGE_H * 0.22))
    story.append(Paragraph("HOSTELIX PRO", S['CoverTitle']))
    story.append(Spacer(1, 6))
    story.append(Paragraph("Product Features Document", S['CoverSubtitle']))
    story.append(Spacer(1, 20))
    story.append(AccentLine(w, HexColor("#e94560")))
    story.append(Spacer(1, 20))
    story.append(Paragraph("Comprehensive Hostel Management Platform", S['CoverSubtitle']))
    story.append(Paragraph("for Educational Institutions", S['CoverSubtitle']))
    story.append(Spacer(1, 40))
    story.append(Paragraph("Version 1.0  |  February 2026", S['CoverMeta']))
    story.append(Paragraph("Cross-Platform Mobile (Android & iOS) + RESTful Backend", S['CoverMeta']))
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # TABLE OF CONTENTS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Table of Contents", S['SectionTitle']))
    story.append(AccentLine(w))
    story.append(spacer(10))
    
    toc_items = [
        "1.   Executive Summary",
        "2.   System Architecture",
        "3.   User Roles & Permissions",
        "4.   Authentication & Security",
        "5.   Dashboard Module",
        "6.   User Management",
        "7.   Student Profiles",
        "8.   Fee Management",
        "9.   Routine Management",
        "10.  Daily Reports",
        "11.  Announcements & Holidays",
        "12.  Notifications",
        "13.  Audit Logs",
        "14.  Backup & Restore",
        "15.  Account Self-Service",
        "16.  Settings & Configuration",
        "17.  Data Export",
        "18.  Remote Access & Deployment",
        "19.  Technical Specifications",
    ]
    for item in toc_items:
        story.append(Paragraph(item, S['TOCItem']))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 1. EXECUTIVE SUMMARY
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("1", "Executive Summary"))
    story.append(spacer(8))
    story.append(body(
        "<b>Hostelix Pro</b> is a comprehensive hostel management platform designed for educational "
        "institutions. It provides end-to-end digital management of student residences, including "
        "fee tracking, daily routine monitoring, activity reporting, and secure multi-role access control."
    ))
    story.append(body(
        "The system serves <b>four distinct user roles</b> — Administrators, Teachers, Routine Managers, "
        "and Students — each with tailored dashboards, permissions, and workflows. Built with a modern "
        "Flutter frontend and a Python Flask backend, Hostelix Pro delivers a seamless, real-time "
        "experience across Android and iOS devices."
    ))
    story.append(spacer(6))
    story.append(Paragraph("Key Highlights", S['SubsectionTitle']))
    story.append(make_table(
        ["Capability", "Description"],
        [
            ["Multi-Factor Authentication", "Email OTP + optional TOTP 2FA via authenticator apps"],
            ["Role-Based Access Control", "Four roles with granular permissions per endpoint"],
            ["Real-Time Dashboards", "Role-specific statistics and activity feeds"],
            ["Fee Lifecycle Management", "Structure definition → Submission → Approval → PDF Challan"],
            ["Routine Tracking", "Walk/Exit requests with approval workflows and return monitoring"],
            ["Encrypted Backups", "Full database backup with AES encryption and key-based restore"],
            ["Remote Access", "Ngrok tunnel integration for access from any network"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 2. SYSTEM ARCHITECTURE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("2", "System Architecture"))
    story.append(spacer(8))
    story.append(body(
        "Hostelix Pro follows a <b>client-server architecture</b> with a Flutter mobile frontend "
        "communicating with a Flask RESTful API backend over HTTPS. The system supports both local "
        "development (SQLite) and production deployment (PostgreSQL)."
    ))
    story.append(spacer(6))
    story.append(Paragraph("Technology Stack", S['SubsectionTitle']))
    story.append(make_table(
        ["Layer", "Technology", "Purpose"],
        [
            ["Frontend", "Flutter 3.x / Dart", "Cross-platform mobile application"],
            ["Backend", "Python 3.x / Flask 3.0", "RESTful API server"],
            ["Database", "SQLite (dev) / PostgreSQL (prod)", "Persistent data storage"],
            ["ORM", "SQLAlchemy + Flask-Migrate", "Database abstraction and migrations"],
            ["Auth", "PyJWT + bcrypt + PyOTP", "JWT tokens, password hashing, TOTP"],
            ["Email", "SMTP (configurable)", "OTP delivery and password reset"],
            ["Export", "ReportLab (PDF) / OpenPyXL (Excel)", "Document generation"],
            ["Tunnel", "Ngrok", "Secure remote access"],
        ],
        [w * 0.15, w * 0.35, w * 0.50]
    ))
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 3. USER ROLES & PERMISSIONS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("3", "User Roles & Permissions"))
    story.append(spacer(8))
    story.append(body(
        "Hostelix Pro implements a strict <b>Role-Based Access Control (RBAC)</b> system "
        "with four predefined roles, each with specific capabilities and restrictions."
    ))
    story.append(spacer(6))

    # Admin
    story.append(subsection("3.1  Administrator (admin)"))
    story.append(body("The top-level role with full system access:"))
    for item in [
        "Create, update, delete, lock/unlock user accounts",
        "Approve pending student registrations",
        "Manage fee structures and approve/reject fee submissions",
        "View all reports, routines, and audit logs",
        "Create and manage announcements",
        "Create encrypted backups and perform restores",
        "Export data to Excel and PDF formats",
        "Access the full administrative dashboard",
    ]:
        story.append(bullet(item))
    
    story.append(spacer(4))
    
    # Teacher
    story.append(subsection("3.2  Teacher (teacher)"))
    story.append(body("Responsible for overseeing assigned students:"))
    for item in [
        "View profiles of assigned students only",
        "Approve or reject daily reports from assigned students",
        "Create announcements targeted at their students",
        "Access the teacher dashboard with daily student overview",
        "View routine history for assigned students",
    ]:
        story.append(bullet(item))
    
    story.append(spacer(4))
    
    # Routine Manager
    story.append(subsection("3.3  Routine Manager (routine_manager)"))
    story.append(body("Manages student movement in and out of the hostel:"))
    for item in [
        "Approve or reject walk and exit requests",
        "Confirm student returns to the hostel",
        "Track students currently out of the hostel",
        "Monitor late returns with time-based alerts",
        "Access the routine manager dashboard with live status",
    ]:
        story.append(bullet(item))
    
    story.append(spacer(4))
    
    # Student
    story.append(subsection("3.4  Student (student)"))
    story.append(body("The end-user of the hostel system:"))
    for item in [
        "Self-register with email (pending admin approval)",
        "Submit daily wake-up reports",
        "Create walk and exit requests with return confirmation",
        "Submit monthly fee payments with proof uploads",
        "View personal fee calendar, routines, and report history",
        "View announcements from admin, teacher, and managers",
        "Manage personal profile (bio, skills, status message)",
    ]:
        story.append(bullet(item))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 4. AUTHENTICATION & SECURITY
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("4", "Authentication & Security"))
    story.append(spacer(8))
    
    story.append(subsection("4.1  Registration Flow"))
    story.append(body(
        "Students self-register with email, password, and display name. Accounts are created "
        "with <b>is_approved = false</b> and require explicit admin approval. During approval, "
        "the admin assigns room number, admission number, and a supervising teacher."
    ))
    story.append(spacer(4))
    
    story.append(subsection("4.2  Multi-Factor Authentication (MFA) Login"))
    story.append(body(
        "Login follows a <b>two-step MFA process</b>:"
    ))
    story.append(bullet("<b>Step 1:</b> Email + password verification → 6-digit OTP sent to registered email"))
    story.append(bullet("<b>Step 2:</b> OTP verification → JWT token issued with user claims"))
    story.append(bullet("OTP has a <b>5-minute expiry</b> window with max 5 attempts per transaction"))
    story.append(bullet("JWT tokens carry user ID, role, and expiration claims"))
    story.append(spacer(4))
    
    story.append(subsection("4.3  Account Lockout Protection"))
    story.append(make_table(
        ["Parameter", "Value"],
        [
            ["Max failed login attempts", "5"],
            ["Lockout duration", "30 minutes"],
            ["Auto-unlock", "Yes (time-based)"],
            ["Admin manual lock/unlock", "Yes"],
        ],
        [w * 0.40, w * 0.60]
    ))
    story.append(spacer(4))
    
    story.append(subsection("4.4  Two-Factor Authentication (TOTP)"))
    story.append(body(
        "Users can enable TOTP-based 2FA via authenticator apps (Google Authenticator, Authy). "
        "QR code generated server-side using <i>pyotp</i> and <i>qrcode</i>. Setup requires "
        "initial code verification. Disabling 2FA requires password confirmation. All 2FA "
        "actions are logged in the audit trail."
    ))
    story.append(spacer(4))
    
    story.append(subsection("4.5  Password Reset Flow"))
    story.append(bullet("User submits email via forgot-password endpoint"))
    story.append(bullet("Backend sends 6-digit OTP to the email address"))
    story.append(bullet("User submits OTP + new password to reset"))
    story.append(bullet("OTP validated, password updated, lockout counters reset"))
    story.append(bullet("Branded HTML email template with security notices"))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 5. DASHBOARD MODULE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("5", "Dashboard Module"))
    story.append(spacer(8))
    story.append(body(
        "Each user role has a tailored dashboard providing real-time insights and quick actions. "
        "Dashboards feature a cyberpunk-themed animated UI with dark mode optimization."
    ))
    story.append(spacer(4))
    
    story.append(subsection("5.1  Admin Dashboard"))
    story.append(make_table(
        ["Widget", "Data Displayed"],
        [
            ["Total Users", "Count of all registered users"],
            ["Total Students", "Count of active students"],
            ["Fee Collection", "Monthly collection summary and statistics"],
            ["Pending Reports", "Reports awaiting teacher/admin action"],
            ["Active Routines", "Currently active walk/exit requests"],
            ["Recent Announcements", "Latest system-wide announcements"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))

    story.append(subsection("5.2  Teacher Dashboard"))
    story.append(make_table(
        ["Widget", "Data Displayed"],
        [
            ["Assigned Students", "List of students under supervision"],
            ["Daily Status", "Per-student wake-up report status for today"],
            ["Pending Reports", "Reports pending teacher approval"],
            ["Quick Actions", "Approve/reject reports inline"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))

    story.append(subsection("5.3  Routine Manager Dashboard"))
    story.append(make_table(
        ["Widget", "Data Displayed"],
        [
            ["Pending Requests", "Walk/exit requests awaiting approval"],
            ["Currently Out", "Live count and list of students outside"],
            ["Late Returns", "Students past expected return time"],
            ["Today's Activity", "Summary of approved/rejected/completed routines"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))

    story.append(subsection("5.4  Student Dashboard"))
    story.append(make_table(
        ["Widget", "Data Displayed"],
        [
            ["Daily Report", "Today's wake-up report status"],
            ["Active Routine", "Current walk/exit status"],
            ["Fee Summary", "Outstanding and upcoming fee amounts"],
            ["Quick Actions", "Submit report, request walk/exit"],
        ],
        [w * 0.30, w * 0.70]
    ))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 6. USER MANAGEMENT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("6", "User Management"))
    story.append(spacer(8))
    story.append(Paragraph("<i>Access: Admin only</i>", S['Caption']))
    story.append(spacer(4))
    
    story.append(subsection("6.1  User CRUD Operations"))
    story.append(make_table(
        ["Operation", "Endpoint", "Description"],
        [
            ["List Users", "GET /users", "List all users with role and status filters"],
            ["Get User", "GET /users/{id}", "Retrieve full user profile by ID"],
            ["Create User", "POST /users", "Create user with email, password, role, name"],
            ["Update User", "PATCH /users/{id}", "Update email, name, role, lock status"],
            ["Delete User", "DELETE /users/{id}", "Permanently remove user and data"],
            ["Lock/Unlock", "POST /users/{id}/lock", "Toggle account lock status"],
            ["Approve", "POST /users/{id}/approve", "Approve pending registration"],
        ],
        [w * 0.18, w * 0.30, w * 0.52]
    ))
    story.append(spacer(4))
    
    story.append(subsection("6.2  Student Approval Workflow"))
    story.append(body("When approving a student, the admin assigns:"))
    story.append(bullet("<b>Admission Number</b> — Unique identifier within the institution"))
    story.append(bullet("<b>Room Number</b> — Hostel room assignment"))
    story.append(bullet("<b>Assigned Teacher</b> — Teacher responsible for daily reports"))
    
    story.append(spacer(10))
    
    # ══════════════════════════════════════════════════════════════════════════
    # 7. STUDENT PROFILES
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("7", "Student Profiles"))
    story.append(spacer(8))
    
    story.append(subsection("7.1  Role-Based Access"))
    story.append(make_table(
        ["Role", "Access Level"],
        [
            ["Admin", "All student profiles, full details"],
            ["Teacher", "Assigned students only"],
            ["Routine Manager", "All students, limited fields"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))
    
    story.append(subsection("7.2  Student Profile Fields"))
    story.append(make_table(
        ["Field", "Type", "Description"],
        [
            ["admission_no", "String", "Unique admission number"],
            ["room", "String", "Assigned hostel room"],
            ["assigned_teacher_id", "Integer", "Supervising teacher's user ID"],
            ["profile_json", "JSON", "Extended profile data"],
            ["bio", "Text", "Student bio / interests"],
            ["skills", "Text", "Skills and competencies"],
            ["status_message", "String", "Current status"],
        ],
        [w * 0.25, w * 0.15, w * 0.60]
    ))
    story.append(spacer(4))
    
    story.append(subsection("7.3  Student Activity Calendar"))
    story.append(body(
        "Detailed activity history grouped by date, including reports, routines, and fee "
        "submissions. Admin can access via <b>GET /users/{id}/activities</b>."
    ))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 8. FEE MANAGEMENT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("8", "Fee Management"))
    story.append(spacer(8))
    
    story.append(subsection("8.1  Fee Structure Definition"))
    story.append(body(
        "Admins define reusable fee structures with name, amount, and description. "
        "Structures can be created, updated, and listed. Each student's monthly fee "
        "references a fee structure."
    ))
    story.append(spacer(4))
    
    story.append(subsection("8.2  Fee Lifecycle"))
    story.append(body(
        "The fee payment follows a structured workflow:"
    ))
    story.append(bullet("<b>UNPAID</b> → Fee record created for the month"))
    story.append(bullet("<b>PENDING_ADMIN</b> → Student submits payment with proof"))
    story.append(bullet("<b>APPROVED / PAID</b> → Admin approves the submission"))
    story.append(bullet("<b>REJECTED</b> → Admin rejects (with reason); student can resubmit"))
    story.append(bullet("<b>PARTIAL</b> → Partial payment submitted"))
    story.append(spacer(4))
    
    story.append(subsection("8.3  Fee Calendar (Matrix View)"))
    story.append(body(
        "The fee calendar provides a <b>student × month matrix</b> showing fee status for "
        "an entire year. Each cell includes status, expected amount, paid amount, and pending "
        "amount. Admins see all students; students see only their own row. Yearly totals "
        "are calculated automatically."
    ))
    story.append(spacer(4))
    
    story.append(subsection("8.4  Additional Fee Features"))
    story.append(make_table(
        ["Feature", "Description"],
        [
            ["Fee Statistics", "Current month collection summary with outstanding balances"],
            ["Proof Upload", "Students upload payment proof images via multipart upload"],
            ["Transaction History", "All transactions per fee with status tracking"],
            ["Fee Challan (PDF)", "Professional PDF challan generated with ReportLab"],
            ["Approve / Reject", "Admin reviews and acts on individual transactions"],
        ],
        [w * 0.30, w * 0.70]
    ))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 9. ROUTINE MANAGEMENT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("9", "Routine Management"))
    story.append(spacer(8))
    
    story.append(subsection("9.1  Request Types"))
    story.append(make_table(
        ["Type", "Description", "Who Creates"],
        [
            ["Walk", "Short-duration outing within campus vicinity", "Student"],
            ["Exit", "Extended departure requiring formal approval", "Student"],
            ["Return", "Check-in confirmation after walk/exit", "Student → Manager"],
        ],
        [w * 0.15, w * 0.55, w * 0.30]
    ))
    story.append(spacer(4))
    
    story.append(subsection("9.2  Routine Lifecycle"))
    story.append(body("The routine follows a multi-step approval workflow:"))
    story.append(bullet("<b>PENDING_ROUTINE_MANAGER</b> → Student submits walk/exit request"))
    story.append(bullet("<b>APPROVED_PENDING_RETURN</b> → Manager approves the request"))
    story.append(bullet("<b>PENDING_RETURN_APPROVAL</b> → Student requests return check-in"))
    story.append(bullet("<b>COMPLETED</b> → Manager confirms the return"))
    story.append(bullet("<b>REJECTED / RETURN_REJECTED</b> → Manager rejects (with reason)"))
    story.append(spacer(4))
    
    story.append(subsection("9.3  Live Monitoring"))
    story.append(make_table(
        ["Feature", "Description"],
        [
            ["Currently Out", "Real-time list of students outside the hostel"],
            ["Late Returns", "Students who exceeded expected return time"],
            ["Pending Approvals", "Requests awaiting manager action"],
            ["Calendar View", "Monthly view of routines grouped by date with daily summaries"],
        ],
        [w * 0.28, w * 0.72]
    ))
    
    story.append(spacer(10))
    
    # ══════════════════════════════════════════════════════════════════════════
    # 10. DAILY REPORTS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("10", "Daily Reports"))
    story.append(spacer(8))
    
    story.append(subsection("10.1  Report Flow"))
    story.append(body(
        "Students submit daily wake-up reports which go through a <b>multi-tier approval</b> "
        "process. Reports flow from Student → Teacher → Admin."
    ))
    story.append(spacer(4))
    
    story.append(subsection("10.2  Report Status"))
    story.append(make_table(
        ["Status", "Description"],
        [
            ["PENDING_TEACHER", "Awaiting assigned teacher's review"],
            ["APPROVED", "Teacher or admin approved the report"],
            ["REJECTED", "Teacher or admin rejected (reason required)"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))
    
    story.append(subsection("10.3  Role-Based Access"))
    story.append(make_table(
        ["Role", "Visible Reports"],
        [
            ["Student", "Own reports only"],
            ["Teacher", "Reports from assigned students (filterable)"],
            ["Admin", "All reports (filterable by status)"],
        ],
        [w * 0.25, w * 0.75]
    ))
    story.append(spacer(4))
    story.append(body("Admin can export all reports to <b>Excel (.xlsx)</b> format."))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 11. ANNOUNCEMENTS & HOLIDAYS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("11", "Announcements & Holidays"))
    story.append(spacer(8))
    
    story.append(subsection("11.1  Announcement Types & Priorities"))
    story.append(make_table(
        ["Type", "Priority Levels", "Description"],
        [
            ["general", "low / normal / high / urgent", "Standard informational announcement"],
            ["holiday", "normal / high", "Holiday declaration with date range"],
            ["event", "normal / high", "Event notification with specific date"],
            ["urgent", "urgent", "High-priority alert (top of feed)"],
        ],
        [w * 0.15, w * 0.30, w * 0.55]
    ))
    story.append(spacer(4))
    
    story.append(subsection("11.2  Targeting & Visibility"))
    story.append(make_table(
        ["Creator Role", "Visibility Scope"],
        [
            ["Admin", "All users (or targeted by role)"],
            ["Routine Manager", "All users (or targeted by role)"],
            ["Teacher", "Only their assigned students"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))
    story.append(body(
        "Students only see announcements from admins, routine managers, and their assigned teacher. "
        "Holiday calendar endpoint returns all holiday announcements for a given year."
    ))
    
    story.append(spacer(10))
    
    # ══════════════════════════════════════════════════════════════════════════
    # 12-14: NOTIFICATIONS, AUDIT, BACKUP
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("12", "Notifications"))
    story.append(spacer(8))
    story.append(make_table(
        ["Feature", "Description"],
        [
            ["Per-User Inbox", "Each user has a personal notification feed"],
            ["Read/Unread State", "Notifications track individual read status"],
            ["Badge Count", "Unread count via dedicated endpoint"],
            ["Mark as Read", "Individual or bulk mark-all-as-read support"],
            ["Filtering", "Filter by unread status with configurable limits"],
        ],
        [w * 0.28, w * 0.72]
    ))
    
    story.append(spacer(10))
    
    story.append(section("13", "Audit Logs"))
    story.append(spacer(8))
    story.append(Paragraph("<i>Access: Admin only</i>", S['Caption']))
    story.append(spacer(4))
    story.append(body(
        "Every sensitive action in the system is logged with comprehensive metadata."
    ))
    story.append(make_table(
        ["Action Category", "Examples"],
        [
            ["Authentication", "LOGIN_SUCCESS, LOGIN_FAILED, LOGOUT"],
            ["User Management", "USER_CREATE, USER_UPDATE, USER_DELETE, USER_LOCK"],
            ["Profile Changes", "UPDATE_PROFILE, CHANGE_PASSWORD"],
            ["Security", "ENABLE_2FA, DISABLE_2FA"],
            ["Fee Operations", "FEE_APPROVE, FEE_REJECT"],
            ["Announcements", "ANNOUNCEMENT_CREATE, ANNOUNCEMENT_DELETE"],
            ["Backups", "BACKUP_CREATE, BACKUP_RESTORE_VERIFY"],
        ],
        [w * 0.30, w * 0.70]
    ))
    story.append(spacer(4))
    story.append(body(
        "Each entry captures: User ID, Action, Entity, Entity ID, IP Address, "
        "User-Agent, Details (JSON), and Timestamp. Results are filterable and paginated."
    ))
    
    story.append(PageBreak())
    
    story.append(section("14", "Backup & Restore"))
    story.append(spacer(8))
    story.append(Paragraph("<i>Access: Admin only</i>", S['Caption']))
    story.append(spacer(4))
    story.append(make_table(
        ["Operation", "Description"],
        [
            ["Create Backup", "Full database export with AES encryption; returns unique key"],
            ["List Backups", "View all backups with metadata (size, timestamp)"],
            ["Download Backup", "Download encrypted backup file"],
            ["Restore Backup", "Verify and restore using the original encryption key"],
        ],
        [w * 0.25, w * 0.75]
    ))
    story.append(spacer(4))
    story.append(body(
        "Backup files are encrypted at rest. Restoration requires the exact encryption key "
        "provided during creation. All operations are logged in the audit trail."
    ))
    
    story.append(spacer(10))
    
    # ══════════════════════════════════════════════════════════════════════════
    # 15-17: ACCOUNT, SETTINGS, EXPORT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("15", "Account Self-Service"))
    story.append(spacer(8))
    story.append(make_table(
        ["Feature", "Details"],
        [
            ["Profile Edit", "Display name, email, bio, skills, status message"],
            ["Password Change", "Requires current password; min 6 characters"],
            ["2FA Setup", "Generate QR code + secret; verify with authenticator code"],
            ["2FA Disable", "Requires current password confirmation"],
        ],
        [w * 0.25, w * 0.75]
    ))
    
    story.append(spacer(10))
    
    story.append(section("16", "Settings & Configuration"))
    story.append(spacer(8))
    story.append(make_table(
        ["Setting", "Description"],
        [
            ["Theme Mode", "Dark (default) / Light mode toggle with persistence"],
            ["Backend URL", "Configurable API host for remote access"],
            ["URL Cleanup", "Auto-strips trailing slashes and /api/v1 suffixes"],
            ["Reset Option", "One-tap reset to default host URL"],
        ],
        [w * 0.25, w * 0.75]
    ))
    
    story.append(spacer(10))
    
    story.append(section("17", "Data Export"))
    story.append(spacer(8))
    story.append(make_table(
        ["Data Type", "Format", "Access", "Technology"],
        [
            ["Reports", ".xlsx (Excel)", "Admin", "OpenPyXL"],
            ["Fee Challans", ".pdf", "Admin / Student", "ReportLab"],
        ],
        [w * 0.20, w * 0.20, w * 0.25, w * 0.35]
    ))
    
    story.append(PageBreak())
    
    # ══════════════════════════════════════════════════════════════════════════
    # 18. REMOTE ACCESS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("18", "Remote Access & Deployment"))
    story.append(spacer(8))
    
    story.append(subsection("18.1  Ngrok Integration"))
    story.append(bullet("Automated setup via <b>run_remote.bat</b> script"))
    story.append(bullet("Auto-detects ngrok binary (PATH or local directory)"))
    story.append(bullet("Configures auth token and launches tunnel automatically"))
    story.append(bullet("<b>ngrok-skip-browser-warning</b> header added to all API requests"))
    story.append(bullet("CORS configured for all origins"))
    story.append(spacer(4))
    
    story.append(subsection("18.2  Deployment Options"))
    story.append(make_table(
        ["Platform", "Type", "Complexity"],
        [
            ["Ngrok", "Quick tunnel (dev/testing)", "Low"],
            ["Local Network", "Direct IP on shared WiFi", "Low"],
            ["Render", "Cloud PaaS (production)", "Medium"],
            ["Railway", "Cloud PaaS (production)", "Medium"],
            ["Fly.io", "Edge deployment (production)", "Medium"],
        ],
        [w * 0.25, w * 0.45, w * 0.30]
    ))
    
    story.append(spacer(10))
    
    # ══════════════════════════════════════════════════════════════════════════
    # 19. TECHNICAL SPECIFICATIONS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section("19", "Technical Specifications"))
    story.append(spacer(8))
    
    story.append(subsection("19.1  API Endpoint Summary"))
    story.append(make_table(
        ["Module", "Base Path", "Endpoints"],
        [
            ["Auth", "/api/v1/auth", "7"],
            ["Users", "/api/v1/users", "9"],
            ["Account", "/api/v1/account", "6"],
            ["Dashboard", "/api/v1/dashboard", "3"],
            ["Reports", "/api/v1/reports", "5"],
            ["Routines", "/api/v1/routines", "8"],
            ["Fees", "/api/v1/fees", "10"],
            ["Announcements", "/api/v1/announcements", "4"],
            ["Notifications", "/api/v1/notifications", "4"],
            ["Audit", "/api/v1/audit", "1"],
            ["Backups", "/api/v1/backups", "4"],
            ["Total", "", "61"],
        ],
        [w * 0.25, w * 0.45, w * 0.30]
    ))
    story.append(spacer(4))
    
    story.append(subsection("19.2  Data Models"))
    story.append(make_table(
        ["Model", "Table", "Purpose"],
        [
            ["User", "users", "Authentication and RBAC"],
            ["Student", "students", "Extended student profile"],
            ["Fee", "fees", "Monthly fee records"],
            ["FeeStructure", "fee_structures", "Fee templates"],
            ["Transaction", "transactions", "Payment transactions"],
            ["Report", "reports", "Daily wake-up reports"],
            ["Routine", "routines", "Walk/exit/return requests"],
            ["Announcement", "announcements", "System announcements"],
            ["Notification", "notifications", "User notification inbox"],
            ["AuditLog", "audit_logs", "Security audit trail"],
            ["BackupMeta", "backup_meta", "Backup file metadata"],
        ],
        [w * 0.22, w * 0.28, w * 0.50]
    ))
    story.append(spacer(4))
    
    story.append(subsection("19.3  Frontend Page Map"))
    story.append(make_table(
        ["Directory", "Pages", "Description"],
        [
            ["pages/auth/", "6", "Login, Signup, OTP, Forgot/Reset Password, Splash"],
            ["pages/admin/", "6", "Dashboard, Users, Fees, Audit, Backup, Activities"],
            ["pages/common/", "4", "Announcements, Reports, Student Profiles, Settings"],
            ["pages/student/", "3", "Dashboard, Fee Page, Routine Page"],
            ["pages/teacher/", "2", "Dashboard, My Students"],
            ["pages/manager/", "1", "Routine Manager Dashboard"],
            ["Total", "22", ""],
        ],
        [w * 0.25, w * 0.10, w * 0.65]
    ))
    
    story.append(spacer(20))
    story.append(HRFlowable(width="100%", color=PRIMARY, thickness=1))
    story.append(spacer(8))
    story.append(Paragraph(
        "<i>End of Document — Hostelix Pro v1.0 Product Features</i>",
        S['Caption']
    ))
    
    # ══════════════════════════════════════════════════════════════════════════
    # BUILD
    # ══════════════════════════════════════════════════════════════════════════
    doc.build(
        story,
        onFirstPage=cover_page,
        onLaterPages=normal_page,
    )
    
    print(f"\n✅ PDF generated successfully!")
    print(f"📄 Location: {output_path}")
    print(f"📊 Size: {os.path.getsize(output_path) / 1024:.0f} KB")
    return output_path


if __name__ == "__main__":
    build_document()
