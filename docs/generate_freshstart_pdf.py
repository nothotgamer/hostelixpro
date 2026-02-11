"""
Hostelix Pro — Fresh Start & Admin Setup Guide PDF Generator
"""
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable
)
from reportlab.platypus.flowables import Flowable

# ─── Colors ───────────────────────────────────────────────────
PRIMARY      = HexColor("#1a1a2e")
ACCENT       = HexColor("#0f3460")
HIGHLIGHT    = HexColor("#e94560")
TEAL         = HexColor("#16a085")
TABLE_HEADER = HexColor("#16213e")
TABLE_ALT    = HexColor("#eef1f6")
TEXT_DARK    = HexColor("#1a1a2e")
TEXT_MEDIUM  = HexColor("#4a5568")
TEXT_LIGHT   = HexColor("#718096")
BORDER       = HexColor("#cbd5e0")
CODE_BG      = HexColor("#1e1e2e")
CODE_BORDER  = HexColor("#313244")
WHITE        = white

PAGE_W, PAGE_H = A4
MARGIN = 2 * cm
W = PAGE_W - 2 * MARGIN

# ─── Styles ───────────────────────────────────────────────────
def S(name, parent='Normal', **kw):
    from reportlab.lib.styles import getSampleStyleSheet
    base = getSampleStyleSheet()
    return ParagraphStyle(name, parent=base[parent], **kw)

ST = {
    'CoverTitle': S('CT','Title', fontSize=34, leading=42, textColor=WHITE, alignment=TA_CENTER, fontName='Helvetica-Bold'),
    'CoverSub': S('CS','Normal', fontSize=14, leading=20, textColor=HexColor("#a0aec0"), alignment=TA_CENTER),
    'CoverMeta': S('CM','Normal', fontSize=11, leading=16, textColor=HexColor("#718096"), alignment=TA_CENTER),
    'SectTitle': S('ST2','Heading1', fontSize=18, leading=24, textColor=PRIMARY, spaceBefore=16, spaceAfter=8, fontName='Helvetica-Bold'),
    'SubTitle': S('SU2','Heading2', fontSize=13, leading=17, textColor=ACCENT, spaceBefore=12, spaceAfter=5, fontName='Helvetica-Bold'),
    'Body': S('BD2','Normal', fontSize=10, leading=15, textColor=TEXT_DARK, alignment=TA_JUSTIFY, spaceAfter=5),
    'Bullet': S('BL2','Normal', fontSize=10, leading=15, textColor=TEXT_DARK, leftIndent=18, spaceAfter=3, bulletIndent=6),
    'TH': S('TH2','Normal', fontSize=9, leading=12, textColor=WHITE, fontName='Helvetica-Bold'),
    'TC': S('TC2','Normal', fontSize=9, leading=12, textColor=TEXT_DARK),
    'Code': S('CD2','Normal', fontSize=9, leading=13, textColor=HexColor("#a6e3a1"), fontName='Courier', backColor=CODE_BG, leftIndent=8, rightIndent=8, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=CODE_BORDER, borderPadding=6),
    'TOC': S('TO2','Normal', fontSize=11, leading=22, textColor=ACCENT, leftIndent=10),
    'Tip': S('TP2','Normal', fontSize=9, leading=13, textColor=HexColor("#16a085"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=TEAL, borderPadding=6),
    'Warn': S('WN2','Normal', fontSize=9, leading=13, textColor=HexColor("#d35400"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=HexColor("#e67e22"), borderPadding=6),
    'Imp': S('IM2','Normal', fontSize=9, leading=13, textColor=HexColor("#c0392b"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=HIGHLIGHT, borderPadding=6),
    'Caption': S('CP2','Normal', fontSize=9, leading=12, textColor=TEXT_MEDIUM, fontName='Helvetica-Oblique', spaceAfter=4),
}

# ─── Custom Flowables ─────────────────────────────────────────
class SectionBlock(Flowable):
    def __init__(self, text, w=None):
        Flowable.__init__(self)
        self.text = text
        self._width = w or W
        self.height = 13*mm
    def draw(self):
        c = self.canv
        c.setFillColor(PRIMARY)
        c.roundRect(0, 0, self._width, self.height, 3, fill=1, stroke=0)
        c.setFillColor(HIGHLIGHT)
        c.rect(0, 0, 4, self.height, fill=1, stroke=0)
        c.setFillColor(WHITE)
        c.setFont("Helvetica-Bold", 12)
        c.drawString(14, self.height / 2 - 4, self.text)

class AccentLine(Flowable):
    def __init__(self, w=None):
        Flowable.__init__(self)
        self._width = w or W
        self.height = 2
    def draw(self):
        c = self.canv
        c.setStrokeColor(HIGHLIGHT); c.setLineWidth(1.5)
        c.line(0, 0, self._width * 0.3, 0)
        c.setStrokeColor(BORDER); c.setLineWidth(0.5)
        c.line(self._width * 0.3, 0, self._width, 0)

# ─── Helpers ──────────────────────────────────────────────────
def tbl(headers, rows, widths=None):
    hdr = [Paragraph(h, ST['TH']) for h in headers]
    data = [hdr] + [[Paragraph(str(c), ST['TC']) for c in r] for r in rows]
    if widths is None:
        widths = [W / len(headers)] * len(headers)
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 7),
        ('TOPPADDING', (0, 0), (-1, 0), 7),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 5),
        ('TOPPADDING', (0, 1), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 7),
        ('RIGHTPADDING', (0, 0), (-1, -1), 7),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, TABLE_ALT]),
    ]))
    return t

def p(text): return Paragraph(text, ST['Body'])
def b(text): return Paragraph(f"•  {text}", ST['Bullet'])
def sec(num, title): return SectionBlock(f"  {num}.  {title}")
def sub(title): return Paragraph(title, ST['SubTitle'])
def sp(h=6): return Spacer(1, h)
def code(text): return Paragraph(text.replace('\n', '<br/>').replace(' ', '&nbsp;'), ST['Code'])
def tip(text): return Paragraph(f"💡 <b>TIP:</b> {text}", ST['Tip'])
def warn(text): return Paragraph(f"⚠️ <b>WARNING:</b> {text}", ST['Warn'])
def imp(text): return Paragraph(f"❗ <b>IMPORTANT:</b> {text}", ST['Imp'])

# ─── Page Templates ───────────────────────────────────────────
def cover_page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    canvas.setFillColor(HIGHLIGHT)
    canvas.rect(0, PAGE_H - 8, PAGE_W, 8, fill=1, stroke=0)
    canvas.setFillColor(ACCENT)
    canvas.rect(0, PAGE_H * 0.38, PAGE_W, 2, fill=1, stroke=0)
    canvas.setFillColor(HexColor("#0f3460"))
    canvas.rect(0, 0, PAGE_W, 55, fill=1, stroke=0)
    canvas.setFillColor(HexColor("#718096"))
    canvas.setFont("Helvetica", 8)
    canvas.drawCentredString(PAGE_W / 2, 26, "Confidential — For Development Team Use Only")
    canvas.drawCentredString(PAGE_W / 2, 14, "© 2026 Hostelix Pro. All rights reserved.")
    canvas.restoreState()

def normal_page(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(PRIMARY); canvas.setLineWidth(1)
    canvas.line(MARGIN, PAGE_H - MARGIN + 10, PAGE_W - MARGIN, PAGE_H - MARGIN + 10)
    canvas.setStrokeColor(HIGHLIGHT); canvas.setLineWidth(2)
    canvas.line(MARGIN, PAGE_H - MARGIN + 10, MARGIN + 40, PAGE_H - MARGIN + 10)
    canvas.setFont("Helvetica-Bold", 8); canvas.setFillColor(TEXT_MEDIUM)
    canvas.drawString(MARGIN, PAGE_H - MARGIN + 14, "HOSTELIX PRO")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(PAGE_W - MARGIN, PAGE_H - MARGIN + 14, "Fresh Start & Admin Setup Guide")
    canvas.setStrokeColor(BORDER); canvas.setLineWidth(0.5)
    canvas.line(MARGIN, MARGIN - 10, PAGE_W - MARGIN, MARGIN - 10)
    canvas.setFont("Helvetica", 8); canvas.setFillColor(TEXT_LIGHT)
    canvas.drawString(MARGIN, MARGIN - 22, "Hostelix Pro v1.0")
    canvas.drawCentredString(PAGE_W / 2, MARGIN - 22, f"Page {doc.page}")
    canvas.drawRightString(PAGE_W - MARGIN, MARGIN - 22, "February 2026")
    canvas.restoreState()

# ─── Build PDF ────────────────────────────────────────────────
def build():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Hostelix_Pro_Fresh_Start_Guide.pdf")
    doc = SimpleDocTemplate(out, pagesize=A4,
                            topMargin=MARGIN + 8 * mm, bottomMargin=MARGIN,
                            leftMargin=MARGIN, rightMargin=MARGIN,
                            title="Hostelix Pro — Fresh Start & Admin Setup Guide",
                            author="Hostelix Pro Team")
    s = []

    # ═══════════════════ COVER ════════════════════════════════
    s.append(Spacer(1, PAGE_H * 0.22))
    s.append(Paragraph("HOSTELIX PRO", ST['CoverTitle']))
    s.append(sp(6))
    s.append(Paragraph("Fresh Start &amp; Admin Setup Guide", ST['CoverSub']))
    s.append(sp(20))
    s.append(AccentLine())
    s.append(sp(20))
    s.append(Paragraph("How to reset the database, start fresh,", ST['CoverSub']))
    s.append(Paragraph("and set up admin accounts using admin_setup.py", ST['CoverSub']))
    s.append(sp(40))
    s.append(Paragraph("Version 1.0  |  February 2026", ST['CoverMeta']))
    s.append(Paragraph("Database Reset  •  Admin Setup  •  First Run", ST['CoverMeta']))
    s.append(PageBreak())

    # ═══════════════════ TOC ══════════════════════════════════
    s.append(Paragraph("Table of Contents", ST['SectTitle']))
    s.append(AccentLine())
    s.append(sp(8))
    for item in [
        "1.   Stop the Backend Server",
        "2.   Delete the Old Database",
        "3.   Recreate the Database Tables",
        "4.   Set Up Admin Accounts (admin_setup.py)",
        "5.   Verify the Setup",
        "6.   Start Using the System",
        "7.   Quick Reference — One-Shot Reset",
    ]:
        s.append(Paragraph(item, ST['TOC']))
    s.append(PageBreak())

    # ═══════════════════ 1. STOP SERVER ═══════════════════════
    s.append(sec("1", "Stop the Backend Server"))
    s.append(sp(8))
    s.append(p("Before deleting the database, stop any running backend process:"))
    s.append(sp(4))
    s.append(b("<b>Terminal:</b> Press <b>Ctrl + C</b> in the terminal running the server"))
    s.append(b("<b>Systemd service:</b> <font face='Courier'>sudo systemctl stop hostelixpro</font>"))
    s.append(b("<b>Docker:</b> <font face='Courier'>docker stop hostelixpro</font>"))
    s.append(sp(6))
    s.append(warn("Deleting the database will <b>permanently erase ALL data</b> — users, students, fees, reports, routines, announcements, notifications, and audit logs. <b>Make a backup first</b> if you need any existing data."))
    s.append(sp(4))
    s.append(imp("All user accounts, usernames, and passwords are stored <b>only</b> in the database. When you delete the database file, <b>every account is permanently gone</b> — including all admin, teacher, routine manager, and student accounts. There is no separate credential store. You <b>must</b> run <b>admin_setup.py</b> to create new accounts before anyone can log in."))

    s.append(sp(10))

    # ═══════════════════ 2. DELETE DB ═════════════════════════
    s.append(sec("2", "Delete the Old Database"))
    s.append(sp(8))

    s.append(sub("SQLite (Default Local Setup)"))
    s.append(p("The database file is at <b>backend/hostelixpro.db</b>:"))
    s.append(sp(4))
    s.append(tbl(
        ["Platform", "Command"],
        [["Windows (CMD)", "cd project\\backend\ndel hostelixpro.db"],
         ["Windows (PowerShell)", "cd project\\backend\nRemove-Item hostelixpro.db"],
         ["macOS / Linux", "cd project/backend\nrm hostelixpro.db"]],
        [W * 0.30, W * 0.70]
    ))
    s.append(sp(4))
    s.append(p("To also clear migration history (for a completely clean slate):"))
    s.append(code("# Windows\nrmdir /s /q migrations\\versions\nmkdir migrations\\versions\n\n# macOS / Linux\nrm -rf migrations/versions/*"))
    s.append(sp(6))

    s.append(sub("PostgreSQL"))
    s.append(code("psql -U postgres\nDROP DATABASE hostelixpro;\nCREATE DATABASE hostelixpro OWNER your_user;\n\\q"))

    s.append(PageBreak())

    # ═══════════════════ 3. RECREATE TABLES ═══════════════════
    s.append(sec("3", "Recreate the Database Tables"))
    s.append(sp(8))
    s.append(p("Navigate to the backend and activate the virtual environment:"))
    s.append(sp(4))
    s.append(tbl(
        ["Platform", "Commands"],
        [["Windows (PowerShell)", "cd project\\backend\n.venv\\Scripts\\Activate.ps1"],
         ["Windows (CMD)", "cd project\\backend\n.venv\\Scripts\\activate.bat"],
         ["macOS / Linux", "cd project/backend\nsource .venv/bin/activate"]],
        [W * 0.30, W * 0.70]
    ))
    s.append(sp(6))
    s.append(p("Create all 11 database tables:"))
    s.append(code("python create_tables.py"))
    s.append(sp(2))
    s.append(p("Expected output:"))
    s.append(code("Creating tables...\nDone!"))
    s.append(sp(4))
    s.append(p("This creates: <b>users</b>, <b>students</b>, <b>fees</b>, <b>fee_structures</b>, <b>transactions</b>, <b>reports</b>, <b>routines</b>, <b>announcements</b>, <b>notifications</b>, <b>audit_logs</b>, <b>backup_meta</b>."))

    s.append(sp(10))

    # ═══════════════════ 4. ADMIN SETUP ═══════════════════════
    s.append(sec("4", "Set Up Admin Accounts"))
    s.append(sp(8))
    s.append(p("Use <b>admin_setup.py</b> to create admin accounts. The script is located at <b>backend/admin_setup.py</b>."))
    s.append(sp(4))

    s.append(sub("All Available Commands"))
    s.append(tbl(
        ["Command", "Mode", "Description"],
        [["python admin_setup.py", "Interactive", "Prompts for email, name, and password with validation"],
         ["python admin_setup.py --quick", "Quick", "Creates default admin instantly (admin@hostelixpro.com)"],
         ["python admin_setup.py --list", "List", "Shows all existing admin accounts"],
         ["python admin_setup.py --help", "Help", "Displays usage information"]],
        [W * 0.38, W * 0.15, W * 0.47]
    ))
    s.append(sp(8))

    s.append(sub("Option A: Interactive Mode (Recommended)"))
    s.append(code("python admin_setup.py"))
    s.append(sp(2))
    s.append(p("The script will prompt you step by step:"))
    s.append(sp(4))
    s.append(code("═══════════════════════════════════════════\n  HOSTELIX PRO — Admin Account Setup\n═══════════════════════════════════════════\n\n  Enter admin email: admin@yourschool.com\n  Enter display name: Dr. Ahmed Khan\n\n  Password requirements:\n    • At least 8 characters\n    • At least 1 uppercase letter (A-Z)\n    • At least 1 lowercase letter (a-z)\n    • At least 1 digit (0-9)\n\n  Enter password: ********\n  Confirm password: ********\n\n  Create this admin account? (y/n): y\n\n  ✓ Admin account created successfully!\n    ID:    1\n    Email: admin@yourschool.com\n    Name:  Dr. Ahmed Khan"))
    s.append(sp(6))

    s.append(sub("Option B: Quick Setup (For Testing)"))
    s.append(code("python admin_setup.py --quick"))
    s.append(sp(2))
    s.append(p("This creates a default admin account:"))
    s.append(tbl(
        ["Field", "Value"],
        [["Email", "admin@hostelixpro.com"],
         ["Password", "Admin@1234"],
         ["Display Name", "System Administrator"]],
        [W * 0.30, W * 0.70]
    ))
    s.append(sp(2))
    s.append(warn("Change the default password immediately after first login in production!"))
    s.append(sp(6))

    s.append(sub("Option C: View Existing Admins"))
    s.append(code("python admin_setup.py --list"))
    s.append(sp(2))
    s.append(p("Shows all admin accounts with their ID, email, name, and lock status."))

    s.append(PageBreak())

    # ═══════════════════ 5. VERIFY ════════════════════════════
    s.append(sec("5", "Verify the Setup"))
    s.append(sp(8))

    s.append(sub("Start the Backend"))
    s.append(code("python app.py"))
    s.append(sp(4))

    s.append(sub("Test Health Endpoint"))
    s.append(code("curl http://localhost:3000/api/v1/health\n\n# Expected:\n# {\"status\": \"healthy\", \"service\": \"Hostelix Pro API\"}"))
    s.append(sp(4))

    s.append(sub("Test Admin Login"))
    s.append(code("curl -X POST http://localhost:3000/api/v1/auth/login \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\"email\":\"admin@hostelixpro.com\",\"password\":\"Admin@1234\"}'"))
    s.append(sp(2))
    s.append(p("Expected: A response with <b>tx_id</b> and <b>otp_sent: true</b>."))
    s.append(sp(4))
    s.append(tip("Since email is likely not configured on a fresh setup, OTPs print to the backend terminal. Look for:<br/><b>[DEV MODE] OTP for admin@hostelixpro.com: 482917</b>"))

    s.append(sp(10))

    # ═══════════════════ 6. FIRST RUN ═════════════════════════
    s.append(sec("6", "Start Using the System"))
    s.append(sp(8))
    s.append(p("After admin setup, configure the system in this order:"))
    s.append(sp(4))
    s.append(tbl(
        ["Step", "Action", "Where"],
        [["1", "Log in with admin account", "Flutter App → Login page"],
         ["2", "Create teacher accounts", "Admin → Users → Add User"],
         ["3", "Create routine manager accounts", "Admin → Users → Add User"],
         ["4", "Set up fee structures", "Admin → Fees → Fee Structures"],
         ["5", "Create announcements", "Admin → Announcements"],
         ["6", "Students register via the app", "Login page → Register"],
         ["7", "Admin approves students", "Admin → Users → Pending"],
         ["8", "Assign students to teachers", "Admin → Users → Assign"]],
        [W * 0.08, W * 0.40, W * 0.52]
    ))
    s.append(sp(6))

    s.append(sub("User Roles Quick Reference"))
    s.append(tbl(
        ["Role", "Access Level"],
        [["Admin", "Full system access — users, fees, reports, backups, audit logs"],
         ["Teacher", "View assigned students, approve reports, manage routines"],
         ["Routine Manager", "Manage walk/exit requests, return confirmations"],
         ["Student", "Submit reports, request exits, view fees, pay fees"]],
        [W * 0.22, W * 0.78]
    ))

    s.append(PageBreak())

    # ═══════════════════ 7. QUICK REF ═════════════════════════
    s.append(sec("7", "Quick Reference — One-Shot Reset"))
    s.append(sp(8))
    s.append(p("Copy-paste this to do a <b>complete fresh start</b> in one go:"))
    s.append(sp(6))

    s.append(sub("Windows (PowerShell)"))
    s.append(code("cd project\\backend\n.venv\\Scripts\\Activate.ps1\n\n# Delete old database\nRemove-Item hostelixpro.db -ErrorAction SilentlyContinue\n\n# Recreate tables\npython create_tables.py\n\n# Set up admin (interactive)\npython admin_setup.py\n\n# Start server\npython app.py"))
    s.append(sp(6))

    s.append(sub("macOS / Linux"))
    s.append(code("cd project/backend\nsource .venv/bin/activate\n\n# Delete old database\nrm -f hostelixpro.db\n\n# Recreate tables\npython create_tables.py\n\n# Set up admin (interactive)\npython admin_setup.py\n\n# Start server\npython app.py"))

    s.append(sp(20))
    s.append(HRFlowable(width="100%", color=PRIMARY, thickness=1))
    s.append(sp(8))
    s.append(Paragraph("<i>End of Document — Hostelix Pro Fresh Start &amp; Admin Setup Guide v1.0</i>", ST['Caption']))

    # BUILD
    doc.build(s, onFirstPage=cover_page, onLaterPages=normal_page)
    print(f"\n{'=' * 55}")
    print(f"  PDF generated successfully!")
    print(f"  Location: {out}")
    print(f"  Size: {os.path.getsize(out) / 1024:.0f} KB")
    print(f"{'=' * 55}")


if __name__ == "__main__":
    build()
