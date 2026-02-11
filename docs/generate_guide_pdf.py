"""
Hostelix Pro - Developer Setup & Deployment Guide PDF Generator
Generates both PDFs: FEATURES + DEVELOPER_SETUP_GUIDE
"""
import os, sys
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether, ListFlowable, ListItem
)
from reportlab.platypus.flowables import Flowable

# ─── Color Palette ────────────────────────────────────────────────
PRIMARY      = HexColor("#1a1a2e")
ACCENT       = HexColor("#0f3460")
HIGHLIGHT    = HexColor("#e94560")
TEAL         = HexColor("#16a085")
LIGHT_BG     = HexColor("#f8f9fa")
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

# ─── Styles ───────────────────────────────────────────────────────
def S(name, parent='Normal', **kw):
    from reportlab.lib.styles import getSampleStyleSheet
    base = getSampleStyleSheet()
    return ParagraphStyle(name, parent=base[parent], **kw)

STYLES = {
    'CoverTitle': S('CT','Title', fontSize=34, leading=42, textColor=WHITE, alignment=TA_CENTER, fontName='Helvetica-Bold'),
    'CoverSub': S('CS','Normal', fontSize=14, leading=20, textColor=HexColor("#a0aec0"), alignment=TA_CENTER),
    'CoverMeta': S('CM','Normal', fontSize=11, leading=16, textColor=HexColor("#718096"), alignment=TA_CENTER),
    'SectTitle': S('ST','Heading1', fontSize=18, leading=24, textColor=PRIMARY, spaceBefore=16, spaceAfter=8, fontName='Helvetica-Bold'),
    'SubTitle': S('SU','Heading2', fontSize=13, leading=17, textColor=ACCENT, spaceBefore=12, spaceAfter=5, fontName='Helvetica-Bold'),
    'Body': S('BD','Normal', fontSize=10, leading=15, textColor=TEXT_DARK, alignment=TA_JUSTIFY, spaceAfter=5),
    'Bullet': S('BL','Normal', fontSize=10, leading=15, textColor=TEXT_DARK, leftIndent=18, spaceAfter=3, bulletIndent=6),
    'TH': S('TH','Normal', fontSize=9, leading=12, textColor=WHITE, fontName='Helvetica-Bold'),
    'TC': S('TC','Normal', fontSize=9, leading=12, textColor=TEXT_DARK),
    'Code': S('CD','Normal', fontSize=9, leading=13, textColor=HexColor("#a6e3a1"), fontName='Courier', backColor=CODE_BG, leftIndent=8, rightIndent=8, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=CODE_BORDER, borderPadding=6),
    'Caption': S('CP','Normal', fontSize=9, leading=12, textColor=TEXT_MEDIUM, fontName='Helvetica-Oblique', spaceAfter=4),
    'TOC': S('TO','Normal', fontSize=11, leading=22, textColor=ACCENT, leftIndent=10),
    'Tip': S('TP','Normal', fontSize=9, leading=13, textColor=HexColor("#16a085"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=TEAL, borderPadding=6),
    'Warn': S('WN','Normal', fontSize=9, leading=13, textColor=HexColor("#d35400"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=HexColor("#e67e22"), borderPadding=6),
    'Important': S('IM','Normal', fontSize=9, leading=13, textColor=HexColor("#c0392b"), leftIndent=12, spaceBefore=4, spaceAfter=4, borderWidth=1, borderColor=HIGHLIGHT, borderPadding=6),
}

# ─── Custom Flowables ─────────────────────────────────────────────
class SectionBlock(Flowable):
    def __init__(self, text, w=None):
        Flowable.__init__(self)
        self.text = text
        self._width = w or W
        self.height = 13*mm
    def draw(self):
        c = self.canv
        c.setFillColor(PRIMARY)
        c.roundRect(0,0,self._width,self.height,3,fill=1,stroke=0)
        c.setFillColor(HIGHLIGHT)
        c.rect(0,0,4,self.height,fill=1,stroke=0)
        c.setFillColor(WHITE)
        c.setFont("Helvetica-Bold",12)
        c.drawString(14, self.height/2 - 4, self.text)

class AccentLine(Flowable):
    def __init__(self, w=None):
        Flowable.__init__(self)
        self._width = w or W
        self.height = 2
    def draw(self):
        c = self.canv
        c.setStrokeColor(HIGHLIGHT); c.setLineWidth(1.5)
        c.line(0,0,self._width*0.3,0)
        c.setStrokeColor(BORDER); c.setLineWidth(0.5)
        c.line(self._width*0.3,0,self._width,0)

# ─── Helpers ──────────────────────────────────────────────────────
def tbl(headers, rows, widths=None):
    hdr = [Paragraph(h, STYLES['TH']) for h in headers]
    data = [hdr] + [[Paragraph(str(c), STYLES['TC']) for c in r] for r in rows]
    if widths is None:
        n = len(headers)
        widths = [W/n]*n
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),TABLE_HEADER),
        ('TEXTCOLOR',(0,0),(-1,0),WHITE),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),
        ('FONTSIZE',(0,0),(-1,0),9),
        ('BOTTOMPADDING',(0,0),(-1,0),7),
        ('TOPPADDING',(0,0),(-1,0),7),
        ('BOTTOMPADDING',(0,1),(-1,-1),5),
        ('TOPPADDING',(0,1),(-1,-1),5),
        ('LEFTPADDING',(0,0),(-1,-1),7),
        ('RIGHTPADDING',(0,0),(-1,-1),7),
        ('GRID',(0,0),(-1,-1),0.5,BORDER),
        ('VALIGN',(0,0),(-1,-1),'TOP'),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[WHITE,TABLE_ALT]),
    ]))
    return t

def b(text): return Paragraph(f"•  {text}", STYLES['Bullet'])
def p(text): return Paragraph(text, STYLES['Body'])
def sec(num, title): return SectionBlock(f"  {num}.  {title}")
def sub(title): return Paragraph(title, STYLES['SubTitle'])
def sp(h=6): return Spacer(1,h)
def code(text): return Paragraph(text.replace('\n','<br/>').replace(' ','&nbsp;'), STYLES['Code'])
def tip(text): return Paragraph(f"💡 <b>TIP:</b> {text}", STYLES['Tip'])
def warn(text): return Paragraph(f"⚠️ <b>WARNING:</b> {text}", STYLES['Warn'])
def imp(text): return Paragraph(f"❗ <b>IMPORTANT:</b> {text}", STYLES['Important'])

# ─── Page Templates ───────────────────────────────────────────────
def cover_page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0,0,PAGE_W,PAGE_H,fill=1,stroke=0)
    canvas.setFillColor(HIGHLIGHT)
    canvas.rect(0,PAGE_H-8,PAGE_W,8,fill=1,stroke=0)
    canvas.setFillColor(ACCENT)
    canvas.rect(0,PAGE_H*0.38,PAGE_W,2,fill=1,stroke=0)
    canvas.setFillColor(HexColor("#0f3460"))
    canvas.rect(0,0,PAGE_W,55,fill=1,stroke=0)
    canvas.setFillColor(HexColor("#718096"))
    canvas.setFont("Helvetica",8)
    canvas.drawCentredString(PAGE_W/2,26,"Confidential — For Development Team Use Only")
    canvas.drawCentredString(PAGE_W/2,14,"© 2026 Hostelix Pro. All rights reserved.")
    canvas.restoreState()

def normal_page(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(PRIMARY); canvas.setLineWidth(1)
    canvas.line(MARGIN,PAGE_H-MARGIN+10,PAGE_W-MARGIN,PAGE_H-MARGIN+10)
    canvas.setStrokeColor(HIGHLIGHT); canvas.setLineWidth(2)
    canvas.line(MARGIN,PAGE_H-MARGIN+10,MARGIN+40,PAGE_H-MARGIN+10)
    canvas.setFont("Helvetica-Bold",8); canvas.setFillColor(TEXT_MEDIUM)
    canvas.drawString(MARGIN,PAGE_H-MARGIN+14,"HOSTELIX PRO")
    canvas.setFont("Helvetica",8)
    canvas.drawRightString(PAGE_W-MARGIN,PAGE_H-MARGIN+14,"Developer Setup & Deployment Guide")
    canvas.setStrokeColor(BORDER); canvas.setLineWidth(0.5)
    canvas.line(MARGIN,MARGIN-10,PAGE_W-MARGIN,MARGIN-10)
    canvas.setFont("Helvetica",8); canvas.setFillColor(TEXT_LIGHT)
    canvas.drawString(MARGIN,MARGIN-22,"Hostelix Pro v1.0")
    canvas.drawCentredString(PAGE_W/2,MARGIN-22,f"Page {doc.page}")
    canvas.drawRightString(PAGE_W-MARGIN,MARGIN-22,"February 2026")
    canvas.restoreState()

# ─── Build PDF ────────────────────────────────────────────────────
def build():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Hostelix_Pro_Developer_Guide.pdf")
    doc = SimpleDocTemplate(out, pagesize=A4, topMargin=MARGIN+8*mm, bottomMargin=MARGIN, leftMargin=MARGIN, rightMargin=MARGIN,
                            title="Hostelix Pro — Developer Setup & Deployment Guide", author="Hostelix Pro Team")
    s = []

    # ═══════════════════ COVER ════════════════════════════════════
    s.append(Spacer(1, PAGE_H*0.22))
    s.append(Paragraph("HOSTELIX PRO", STYLES['CoverTitle']))
    s.append(sp(6))
    s.append(Paragraph("Developer Setup &amp; Deployment Guide", STYLES['CoverSub']))
    s.append(sp(20))
    s.append(AccentLine())
    s.append(sp(20))
    s.append(Paragraph("Complete guide for new developers to set up, configure,", STYLES['CoverSub']))
    s.append(Paragraph("build, and deploy the Hostelix Pro platform", STYLES['CoverSub']))
    s.append(sp(40))
    s.append(Paragraph("Version 1.0  |  February 2026", STYLES['CoverMeta']))
    s.append(Paragraph("Flask Backend  •  Flutter Frontend  •  Cross-Platform", STYLES['CoverMeta']))
    s.append(PageBreak())

    # ═══════════════════ TOC ══════════════════════════════════════
    s.append(Paragraph("Table of Contents", STYLES['SectTitle']))
    s.append(AccentLine())
    s.append(sp(8))
    for item in [
        "1.   Prerequisites",
        "2.   Project Structure Overview",
        "3.   Backend Setup (Flask API)",
        "4.   Creating the Admin User",
        "5.   Frontend Setup (Flutter App)",
        "6.   Connecting Frontend to Backend",
        "7.   Building for Production",
        "8.   Remote Access with Ngrok",
        "9.   Cloud Deployment",
        "10.  Email / SMTP Configuration",
        "11.  API Reference Quick Start",
        "12.  Troubleshooting",
    ]:
        s.append(Paragraph(item, STYLES['TOC']))
    s.append(PageBreak())

    # ═══════════════════ 1. PREREQUISITES ═════════════════════════
    s.append(sec("1","Prerequisites"))
    s.append(sp(8))
    s.append(p("Ensure the following tools are installed on your machine before starting:"))
    s.append(sp(4))
    s.append(sub("Required Software"))
    s.append(tbl(
        ["Tool","Min Version","Purpose"],
        [["Python","3.10+","Backend API server"],
         ["pip","Latest","Python package manager"],
         ["Flutter SDK","3.10+","Mobile/Desktop/Web frontend"],
         ["Git","Any","Version control"]],
        [W*0.20, W*0.20, W*0.60]
    ))
    s.append(sp(6))
    s.append(sub("Optional Software"))
    s.append(tbl(
        ["Tool","Purpose","When Needed"],
        [["Android Studio","Android emulator + SDK","Building Android APK"],
         ["Xcode (macOS)","iOS build tools","Building iOS app"],
         ["Visual Studio","C++ workload","Windows desktop builds"],
         ["Chrome","Web browser","Flutter web debugging"],
         ["Ngrok","Secure tunneling","Remote device access"],
         ["PostgreSQL","Production database","Cloud deployment"],
         ["Docker","Containerization","Docker deployment"]],
        [W*0.25, W*0.35, W*0.40]
    ))
    s.append(sp(6))
    s.append(sub("Verify Your Environment"))
    s.append(code("python --version          # Should show 3.10+\npip --version\nflutter --version         # Should show 3.10+\nflutter doctor            # Shows platform readiness"))
    s.append(sp(4))
    s.append(imp("If <b>flutter doctor</b> shows issues, resolve them before proceeding. Run <b>flutter doctor -v</b> for detailed diagnostics."))

    s.append(PageBreak())

    # ═══════════════════ 2. PROJECT STRUCTURE ═════════════════════
    s.append(sec("2","Project Structure Overview"))
    s.append(sp(8))
    s.append(tbl(
        ["Directory","Contents","Description"],
        [["backend/app/api/","11 modules","API route blueprints (auth, users, fees, etc.)"],
         ["backend/app/models/","11 models","SQLAlchemy data models"],
         ["backend/app/services/","9 services","Business logic layer"],
         ["backend/scripts/","seed_db.py","Database seeding utilities"],
         ["backend/migrations/","Alembic","Database migration history"],
         ["hostelixpro/lib/pages/","22 pages","Flutter UI screens (6 directories by role)"],
         ["hostelixpro/lib/services/","14 services","API clients and business logic"],
         ["hostelixpro/lib/providers/","3 providers","State management (Provider pattern)"],
         ["hostelixpro/lib/widgets/","9 directories","Reusable UI components"],
         ["hostelixpro/assets/","images/","Images and icons"],
         ["docs/","guides","FEATURES.md + this guide"]],
        [W*0.28, W*0.22, W*0.50]
    ))

    s.append(PageBreak())

    # ═══════════════════ 3. BACKEND SETUP ═════════════════════════
    s.append(sec("3","Backend Setup (Flask API)"))
    s.append(sp(8))

    s.append(sub("Step 1: Create Virtual Environment"))
    s.append(code("cd project/backend\npython -m venv .venv"))
    s.append(sp(4))
    s.append(sub("Step 2: Activate Virtual Environment"))
    s.append(tbl(
        ["Platform","Command"],
        [["Windows (PowerShell)",".venv\\Scripts\\Activate.ps1"],
         ["Windows (CMD)",".venv\\Scripts\\activate.bat"],
         ["macOS / Linux","source .venv/bin/activate"]],
        [W*0.35, W*0.65]
    ))
    s.append(sp(2))
    s.append(tip("You'll see <b>(.venv)</b> at the start of your terminal prompt when activated."))
    s.append(sp(4))

    s.append(sub("Step 3: Install Dependencies"))
    s.append(code("pip install -r requirements.txt"))
    s.append(sp(2))
    s.append(p("This installs Flask, SQLAlchemy, Flask-Migrate, Flask-CORS, bcrypt, PyJWT, pyotp, reportlab, qrcode, openpyxl, cryptography, and all other required packages."))
    s.append(sp(4))

    s.append(sub("Step 4: Configure Environment Variables"))
    s.append(code("copy .env.example .env     # Windows\ncp .env.example .env       # macOS/Linux"))
    s.append(sp(2))
    s.append(p("Edit the <b>.env</b> file with your settings:"))
    s.append(tbl(
        ["Variable","Default / Example","Purpose"],
        [["FLASK_APP","app.py","Flask entry point"],
         ["PORT","3000","Server port"],
         ["SECRET_KEY","(generate random string)","Flask session secret"],
         ["DATABASE_URL","sqlite:///hostelixpro.db","Database connection string"],
         ["JWT_SECRET_KEY","(generate random string)","JWT signing key"],
         ["CORS_ORIGINS","*","Allowed CORS origins (use * for dev)"],
         ["MAIL_SERVER","smtp.gmail.com","SMTP server (optional for dev)"],
         ["MAIL_PORT","587","SMTP port"],
         ["MAIL_USERNAME","your-email@gmail.com","Email for sending OTPs"],
         ["MAIL_PASSWORD","your-app-password","Gmail App Password"]],
        [W*0.25, W*0.35, W*0.40]
    ))
    s.append(sp(2))
    s.append(imp("When SMTP is <b>not configured</b>, OTPs print to the terminal as:<br/><b>[DEV MODE] OTP for user@email.com: 482917</b>"))
    s.append(sp(4))

    s.append(sub("Step 5: Initialize Database"))
    s.append(code("python create_tables.py"))
    s.append(sp(4))

    s.append(sub("Step 6: Start the Server"))
    s.append(code("python app.py"))
    s.append(p("Server runs at <b>http://0.0.0.0:3000</b>. Verify:"))
    s.append(code("curl http://localhost:3000/api/v1/health\n# Response: {\"status\": \"healthy\", \"service\": \"Hostelix Pro API\"}"))

    s.append(PageBreak())

    # ═══════════════════ 4. ADMIN USER ════════════════════════════
    s.append(sec("4","Creating the Admin User"))
    s.append(sp(8))

    s.append(sub("Method A: Seed Script (Recommended)"))
    s.append(code("python scripts/seed_db.py"))
    s.append(sp(2))
    s.append(p("This creates a full set of test accounts:"))
    s.append(tbl(
        ["Role","Email","Password","Details"],
        [["Admin","admin@example.com","TestPass123","System Administrator"],
         ["Teacher","teacher@example.com","TestPass123","Mr. Johnson"],
         ["Routine Mgr","routine@example.com","TestPass123","Alice Brown"],
         ["Student 1","student1@example.com","TestPass123","John Doe — Room A101"],
         ["Student 2","student2@example.com","TestPass123","Jane Smith — Room A102"],
         ["Student 3","student3@example.com","TestPass123","Mike Wilson — Room B201"],
         ["Student 4","student4@example.com","TestPass123","Sarah Davis — Room B202"],
         ["Student 5","student5@example.com","TestPass123","Tom Anderson — Room C301"]],
        [W*0.15, W*0.28, W*0.17, W*0.40]
    ))
    s.append(sp(2))
    s.append(warn("Change all passwords before using in production!"))
    s.append(sp(6))

    s.append(sub("Method B: Manual (Flask Shell)"))
    s.append(code("python\n>>> from app import create_app, db\n>>> from app.models.user import User\n>>> from app.services.auth_service import AuthService\n>>> app = create_app()\n>>> with app.app_context():\n...     db.create_all()\n...     admin = User(\n...         email='admin@yourdomain.com',\n...         password_hash=AuthService.hash_password('YourPassword'),\n...         role='admin',\n...         display_name='Admin Name'\n...     )\n...     db.session.add(admin)\n...     db.session.commit()"))

    s.append(PageBreak())

    # ═══════════════════ 5. FRONTEND SETUP ════════════════════════
    s.append(sec("5","Frontend Setup (Flutter App)"))
    s.append(sp(8))

    s.append(sub("Step 1: Verify Flutter"))
    s.append(code("flutter doctor"))
    s.append(sp(2))
    s.append(tbl(
        ["Platform","Requirements"],
        [["Android","Android Studio + Android SDK + emulator or device"],
         ["iOS","macOS + Xcode + CocoaPods"],
         ["Web","Chrome browser"],
         ["Windows","Visual Studio with 'Desktop development with C++' workload"],
         ["Linux","clang, cmake, ninja-build, libgtk-3-dev"],
         ["macOS","Xcode"]],
        [W*0.20, W*0.80]
    ))
    s.append(sp(4))

    s.append(sub("Step 2: Install Dependencies"))
    s.append(code("cd project/hostelixpro\nflutter pub get"))
    s.append(sp(2))
    s.append(p("This installs all packages from <b>pubspec.yaml</b>: http, provider, go_router, shared_preferences, intl, path_provider, file_picker, permission_handler, flutter_form_builder, and more."))
    s.append(sp(4))

    s.append(sub("Step 3: Run in Development"))
    s.append(code("flutter run                    # Default device\nflutter run -d chrome          # Web\nflutter run -d windows         # Windows desktop\nflutter run -d <device-id>     # Specific device\nflutter devices                # List all devices"))
    s.append(sp(4))

    s.append(sub("Step 4: Generate App Icon (Optional)"))
    s.append(code("dart run flutter_launcher_icons"))
    s.append(p("Generates platform icons from <b>assets/images/logo.png</b>."))

    s.append(PageBreak())

    # ═══════════════════ 6. CONNECTING FE ↔ BE ════════════════════
    s.append(sec("6","Connecting Frontend to Backend"))
    s.append(sp(8))
    s.append(p("The Flutter app connects via <b>ApiClient</b> in <b>lib/services/api_client.dart</b>. Default: <b>http://127.0.0.1:3000/api/v1</b>"))
    s.append(sp(4))
    s.append(tbl(
        ["Platform","URL to Use","Notes"],
        [["Chrome / Desktop","http://127.0.0.1:3000","Works out of the box"],
         ["Android Emulator","http://10.0.2.2:3000","Emulator maps 10.0.2.2 → host localhost"],
         ["iOS Simulator","http://127.0.0.1:3000","Works out of the box"],
         ["Physical Device (same WiFi)","http://192.168.x.x:3000","Use computer's LAN IP"],
         ["Remote / Different Network","Ngrok URL","See Section 8"]],
        [W*0.28, W*0.34, W*0.38]
    ))
    s.append(sp(4))
    s.append(sub("Changing the URL"))
    s.append(b("<b>In-App (no code change):</b> Settings → Backend Configuration → Enter new URL → Save → Restart"))
    s.append(b("<b>In Code:</b> Edit <b>defaultHost</b> in <b>lib/services/api_client.dart</b>"))
    s.append(sp(2))
    s.append(imp("Android Emulator cannot reach <b>127.0.0.1</b>. You <b>must</b> use <b>10.0.2.2</b> instead."))

    s.append(PageBreak())

    # ═══════════════════ 7. BUILDS ════════════════════════════════
    s.append(sec("7","Building for Production"))
    s.append(sp(8))
    s.append(tbl(
        ["Platform","Build Command","Output Location"],
        [["Android APK","flutter build apk --release","build/app/outputs/flutter-apk/app-release.apk"],
         ["Split APKs","flutter build apk --split-per-abi","arm64, armeabi, x86_64 APKs"],
         ["Play Store Bundle","flutter build appbundle --release","build/app/outputs/bundle/release/app-release.aab"],
         ["iOS","flutter build ios --release","Open ios/Runner.xcworkspace in Xcode"],
         ["Windows Desktop","flutter build windows --release","build/windows/x64/runner/Release/"],
         ["macOS Desktop","flutter build macos --release","build/macos/Build/Products/Release/"],
         ["Linux Desktop","flutter build linux --release","build/linux/x64/release/bundle/"],
         ["Web App","flutter build web --release","build/web/"]],
        [W*0.22, W*0.38, W*0.40]
    ))
    s.append(sp(6))
    s.append(tip("<b>Android:</b> The <b>arm64-v8a</b> APK is recommended for most modern phones."))
    s.append(sp(2))
    s.append(tip("<b>Web:</b> Serve with <b>python -m http.server 8080</b> from <b>build/web/</b>, or deploy to Netlify, Vercel, Firebase Hosting, etc."))
    s.append(sp(2))
    s.append(tip("<b>Windows Desktop:</b> Copy the entire <b>Release/</b> folder to distribute the app."))

    s.append(PageBreak())

    # ═══════════════════ 8. NGROK ═════════════════════════════════
    s.append(sec("8","Remote Access with Ngrok"))
    s.append(sp(8))
    s.append(b("<b>Step 1:</b> Install ngrok from <b>ngrok.com/download</b>"))
    s.append(b("<b>Step 2:</b> Sign up at <b>dashboard.ngrok.com</b> and get your auth token"))
    s.append(b("<b>Step 3:</b> Configure: <b>ngrok config add-authtoken YOUR_TOKEN</b>"))
    s.append(b("<b>Step 4:</b> Start backend: <b>python app.py</b>  (Terminal 1)"))
    s.append(b("<b>Step 5:</b> Start tunnel: <b>ngrok http 3000</b>  (Terminal 2)"))
    s.append(b("<b>Step 6:</b> Copy the <b>https://xxxx.ngrok-free.app</b> URL"))
    s.append(b("<b>Step 7:</b> In Flutter app → Settings → Backend Configuration → Paste URL"))
    s.append(sp(4))
    s.append(tip("The <b>ngrok-skip-browser-warning</b> header is already added to all API requests — no extra configuration needed."))
    s.append(warn("Free ngrok URLs change on restart. Consider a paid plan for a fixed subdomain."))

    s.append(sp(10))

    # ═══════════════════ 9. CLOUD DEPLOY ══════════════════════════
    s.append(sec("9","Cloud Deployment"))
    s.append(sp(8))
    s.append(sub("Docker Deployment"))
    s.append(code("cd project/backend\ndocker build -t hostelixpro-api .\ndocker run -d -p 3000:3000 \\\n  -e DATABASE_URL=postgresql://... \\\n  -e SECRET_KEY=your-secret \\\n  -e JWT_SECRET_KEY=your-jwt \\\n  -e CORS_ORIGINS=* \\\n  hostelixpro-api"))
    s.append(sp(4))
    s.append(sub("Platform-as-a-Service"))
    s.append(tbl(
        ["Platform","Root Dir","Start Command","Database"],
        [["Render","backend","gunicorn --bind 0.0.0.0:3000 --workers 4 app:app","Render PostgreSQL"],
         ["Railway","backend","(auto-detected from Dockerfile)","Railway PostgreSQL"],
         ["Fly.io","backend","(Dockerfile)","Fly PostgreSQL"]],
        [W*0.15, W*0.15, W*0.45, W*0.25]
    ))
    s.append(sp(4))
    s.append(sub("Manual VPS Deployment"))
    s.append(code("git clone <repo-url>\ncd project/backend\npython -m venv .venv && source .venv/bin/activate\npip install -r requirements.txt\ncp .env.example .env && nano .env\npython create_tables.py\npython scripts/seed_db.py\ngunicorn --bind 0.0.0.0:3000 --workers 4 app:app"))
    s.append(sp(2))
    s.append(tip("For auto-restart on crashes, create a <b>systemd service</b> or use <b>supervisor</b>."))

    s.append(PageBreak())

    # ═══════════════════ 10. EMAIL ════════════════════════════════
    s.append(sec("10","Email / SMTP Configuration"))
    s.append(sp(8))
    s.append(sub("Development Mode (No Setup Needed)"))
    s.append(p("When SMTP is not configured, OTPs print directly to the backend terminal:"))
    s.append(code("[DEV MODE] OTP for admin@example.com: 482917"))
    s.append(sp(4))
    s.append(sub("Production Mode (Gmail)"))
    s.append(b("1. Enable <b>2-Step Verification</b> on your Google Account"))
    s.append(b("2. Generate an <b>App Password</b> at myaccount.google.com/apppasswords"))
    s.append(b("3. Add MAIL_SERVER, MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD to <b>.env</b>"))
    s.append(sp(4))
    s.append(sub("Other SMTP Providers"))
    s.append(tbl(
        ["Provider","Server","Port"],
        [["Gmail","smtp.gmail.com","587"],
         ["Outlook","smtp-mail.outlook.com","587"],
         ["Yahoo","smtp.mail.yahoo.com","587"],
         ["SendGrid","smtp.sendgrid.net","587"],
         ["Mailgun","smtp.mailgun.org","587"]],
        [W*0.25, W*0.45, W*0.30]
    ))

    s.append(sp(10))

    # ═══════════════════ 11. API REFERENCE ════════════════════════
    s.append(sec("11","API Reference Quick Start"))
    s.append(sp(8))
    s.append(sub("Authentication Flow"))
    s.append(code("# 1. Login (sends OTP)\ncurl -X POST http://localhost:3000/api/v1/auth/login \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\"email\":\"admin@example.com\",\"password\":\"TestPass123\"}'\n\n# 2. Verify OTP (check terminal for code)\ncurl -X POST http://localhost:3000/api/v1/auth/verify-otp \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\"tx_id\":\"uuid-from-step1\",\"otp\":\"123456\"}'\n\n# 3. Use JWT token for all requests\ncurl http://localhost:3000/api/v1/dashboard/stats \\\n  -H \"Authorization: Bearer YOUR_JWT_TOKEN\""))
    s.append(sp(6))
    s.append(sub("All API Modules (61 Endpoints)"))
    s.append(tbl(
        ["Module","Base Path","Endpoints"],
        [["Auth","/api/v1/auth","7"],
         ["Users","/api/v1/users","9"],
         ["Account","/api/v1/account","6"],
         ["Dashboard","/api/v1/dashboard","3"],
         ["Reports","/api/v1/reports","5"],
         ["Routines","/api/v1/routines","8"],
         ["Fees","/api/v1/fees","10"],
         ["Announcements","/api/v1/announcements","4"],
         ["Notifications","/api/v1/notifications","4"],
         ["Audit","/api/v1/audit","1"],
         ["Backups","/api/v1/backups","4"],
         ["Total","","61"]],
        [W*0.25, W*0.45, W*0.30]
    ))

    s.append(PageBreak())

    # ═══════════════════ 12. TROUBLESHOOTING ══════════════════════
    s.append(sec("12","Troubleshooting"))
    s.append(sp(8))

    s.append(sub("Backend Issues"))
    s.append(tbl(
        ["Problem","Solution"],
        [["ModuleNotFoundError","Run pip install -r requirements.txt"],
         ["Port 3000 in use","Kill process or change PORT in .env"],
         ["Database errors","Run python create_tables.py"],
         ["CORS errors","Set CORS_ORIGINS=* in .env"],
         ["OTP not received","Check terminal for [DEV MODE] OTP output"],
         ["ImportError","Ensure virtual environment is activated"]],
        [W*0.35, W*0.65]
    ))
    s.append(sp(6))

    s.append(sub("Flutter Issues"))
    s.append(tbl(
        ["Problem","Solution"],
        [["flutter pub get fails","flutter clean then flutter pub get"],
         ["Can't connect to backend","Check Settings → Backend Configuration URL"],
         ["Android build fails","Run flutter doctor --android-licenses"],
         ["Web build blank page","Add --base-href=/ to build command"],
         ["Windows build fails","Install Visual Studio C++ workload"],
         ["Gradle error","Delete .gradle folder and rebuild"]],
        [W*0.35, W*0.65]
    ))
    s.append(sp(6))

    s.append(sub("Connection Issues"))
    s.append(tbl(
        ["Symptom","Solution"],
        [["Connection refused","Is backend running? Is URL correct?"],
         ["Android emulator fails","Use http://10.0.2.2:3000 not 127.0.0.1"],
         ["Physical device fails","Use computer's LAN IP (192.168.x.x)"],
         ["Ngrok tunnel not found","Restart: ngrok http 3000"],
         ["401 Unauthorized","JWT token expired — log in again"],
         ["403 Forbidden","User role lacks permission for endpoint"]],
        [W*0.35, W*0.65]
    ))

    s.append(sp(20))
    s.append(HRFlowable(width="100%", color=PRIMARY, thickness=1))
    s.append(sp(8))
    s.append(Paragraph("<i>End of Document — Hostelix Pro Developer Setup &amp; Deployment Guide v1.0</i>", STYLES['Caption']))

    # BUILD
    doc.build(s, onFirstPage=cover_page, onLaterPages=normal_page)
    print(f"\n{'='*55}")
    print(f"  PDF generated successfully!")
    print(f"  Location: {out}")
    print(f"  Size: {os.path.getsize(out)/1024:.0f} KB")
    print(f"{'='*55}")
    return out

if __name__ == "__main__":
    build()
