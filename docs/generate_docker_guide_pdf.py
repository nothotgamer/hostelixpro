"""
Hostelix Pro — Docker Guide PDF Generator
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
PRIMARY      = HexColor("#007bff")  # Docker Blue
ACCENT       = HexColor("#17a2b8")
HIGHLIGHT    = HexColor("#28a745")
TABLE_HEADER = HexColor("#0056b3")
TABLE_ALT    = HexColor("#f8f9fa")
TEXT_DARK    = HexColor("#212529")
TEXT_MEDIUM  = HexColor("#495057")
TEXT_LIGHT   = HexColor("#6c757d")
BORDER       = HexColor("#dee2e6")
CODE_BG      = HexColor("#f1f3f5")
CODE_BORDER  = HexColor("#e9ecef")
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
    'CoverSub': S('CS','Normal', fontSize=14, leading=20, textColor=HexColor("#e9ecef"), alignment=TA_CENTER),
    'CoverMeta': S('CM','Normal', fontSize=11, leading=16, textColor=HexColor("#dee2e6"), alignment=TA_CENTER),
    'SectTitle': S('ST','Heading1', fontSize=18, leading=24, textColor=PRIMARY, spaceBefore=16, spaceAfter=8, fontName='Helvetica-Bold'),
    'SubTitle': S('SU','Heading2', fontSize=13, leading=17, textColor=ACCENT, spaceBefore=12, spaceAfter=5, fontName='Helvetica-Bold'),
    'Body': S('BD','Normal', fontSize=10, leading=15, textColor=TEXT_DARK, alignment=TA_JUSTIFY, spaceAfter=5),
    'Bullet': S('BL','Normal', fontSize=10, leading=15, textColor=TEXT_DARK, leftIndent=18, spaceAfter=3, bulletIndent=6),
    'TH': S('TH','Normal', fontSize=9, leading=12, textColor=WHITE, fontName='Helvetica-Bold'),
    'TC': S('TC','Normal', fontSize=9, leading=12, textColor=TEXT_DARK),
    'Code': S('CD','Normal', fontSize=9, leading=13, textColor=HexColor("#d63384"), fontName='Courier', backColor=CODE_BG, leftIndent=8, rightIndent=8, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=CODE_BORDER, borderPadding=6),
    'TOC': S('TO','Normal', fontSize=11, leading=22, textColor=ACCENT, leftIndent=10),
    'Tip': S('TP','Normal', fontSize=9, leading=13, textColor=HexColor("#0c5460"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=ACCENT, borderPadding=6, backColor=HexColor("#d1ecf1")),
    'Warn': S('WN','Normal', fontSize=9, leading=13, textColor=HexColor("#856404"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=HexColor("#ffc107"), borderPadding=6, backColor=HexColor("#fff3cd")),
    'Caption': S('CP','Normal', fontSize=9, leading=12, textColor=TEXT_MEDIUM, fontName='Helvetica-Oblique', spaceAfter=4),
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
        c.setStrokeColor(ACCENT); c.setLineWidth(1.5)
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
def warn(text): return Paragraph(f"⚠️ <b>NOTE:</b> {text}", ST['Warn'])

# ─── Page Templates ───────────────────────────────────────────
def cover_page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    canvas.setFillColor(ACCENT)
    canvas.circle(PAGE_W/2, PAGE_H/2, 120, fill=1, stroke=0)
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 34)
    canvas.drawCentredString(PAGE_W/2, PAGE_H*0.6, "HOSTELIX PRO")
    canvas.setFont("Helvetica", 14)
    canvas.drawCentredString(PAGE_W/2, PAGE_H*0.55, "Docker Deployment Guide")
    canvas.setFont("Helvetica", 11)
    canvas.drawCentredString(PAGE_W/2, 50, "Version 1.0  |  February 2026")
    canvas.restoreState()

def normal_page(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(PRIMARY); canvas.setLineWidth(1)
    canvas.line(MARGIN, PAGE_H - MARGIN + 10, PAGE_W - MARGIN, PAGE_H - MARGIN + 10)
    canvas.setFont("Helvetica-Bold", 8); canvas.setFillColor(TEXT_MEDIUM)
    canvas.drawString(MARGIN, PAGE_H - MARGIN + 14, "HOSTELIX PRO")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(PAGE_W - MARGIN, PAGE_H - MARGIN + 14, "Docker Guide")
    canvas.setStrokeColor(BORDER); canvas.setLineWidth(0.5)
    canvas.line(MARGIN, MARGIN - 10, PAGE_W - MARGIN, MARGIN - 10)
    canvas.drawCentredString(PAGE_W / 2, MARGIN - 22, f"Page {doc.page}")
    canvas.restoreState()

# ─── Build PDF ────────────────────────────────────────────────
def build():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Hostelix_Pro_Docker_Guide.pdf")
    doc = SimpleDocTemplate(out, pagesize=A4,
                            topMargin=MARGIN + 8 * mm, bottomMargin=MARGIN,
                            leftMargin=MARGIN, rightMargin=MARGIN,
                            title="Hostelix Pro — Docker Guide", author="Hostelix Pro Team")
    s = []

    # ═══════════════════ COVER ════════════════════════════════
    s.append(Spacer(1, PAGE_H * 0.3)) # Spacer for cover page handled by onFirstPage
    s.append(PageBreak())

    # ═══════════════════ CONTENT ══════════════════════════════
    s.append(sec("1", "Prerequisites"))
    s.append(sp(6))
    s.append(p("You need <b>Docker Desktop</b> installed and running."))
    s.append(b("Download: docker.com/products/docker-desktop"))
    s.append(b("Verify: <font face='Courier'>docker --version</font>"))
    s.append(sp(8))

    s.append(sec("2", "Quick Start (Windows)"))
    s.append(sp(6))
    s.append(p("We have provided a one-click script:"))
    s.append(b("Double-click <b>run_docker.bat</b> in the project root folder."))
    s.append(b("Wait for containers to build and start."))
    s.append(b("Look for <font face='Courier'>[INFO] Listening at: http://0.0.0.0:3000</font>."))
    s.append(sp(8))

    s.append(sec("3", "Manual Start (All Platforms)"))
    s.append(sp(6))
    s.append(code("cd project/backend\ndocker-compose up --build"))
    s.append(p("To run in background:"))
    s.append(code("docker-compose up --build -d"))
    s.append(sp(8))

    s.append(sec("4", "Architecture"))
    s.append(sp(6))
    s.append(tbl(
        ["Service", "Port", "Description"],
        [["backend", "3000", "Flask API (Gunicorn)"],
         ["db", "5432", "PostgreSQL 15"],
         ["redis", "6379", "Redis 7"]],
        [W*0.25, W*0.15, W*0.60]
    ))
    s.append(tip("Database data is persisted in Docker volume <b>postgres_data</b>. It survives restarts."))
    s.append(sp(8))

    s.append(sec("5", "Default Credentials"))
    s.append(sp(6))
    s.append(p("The database is seeded with these test accounts:"))
    s.append(tbl(
        ["Role", "Email", "Password"],
        [["Admin", "admin@example.com", "TestPass123"],
         ["Teacher", "teacher@example.com", "TestPass123"],
         ["Routine Mgr", "routine@example.com", "TestPass123"],
         ["Student", "student1@example.com", "TestPass123"]],
        [W*0.25, W*0.45, W*0.30]
    ))
    s.append(sp(6))
    s.append(warn("To run admin setup manually: <font face='Courier'>docker-compose exec backend python admin_setup.py</font>"))
    s.append(sp(8))

    s.append(sec("6", "Managing the Environment"))
    s.append(sp(6))
    s.append(sub("View Logs"))
    s.append(code("docker-compose logs -f backend"))
    s.append(sub("Reset Database (Fresh Start)"))
    s.append(code("docker-compose down -v\ndocker-compose up -d"))
    s.append(p("The <b>-v</b> flag removes the data volume."))

    # BUILD
    doc.build(s, onFirstPage=cover_page, onLaterPages=normal_page)
    print(f"PDF generated: {out} ({os.path.getsize(out)/1024:.0f} KB)")

if __name__ == "__main__":
    build()
