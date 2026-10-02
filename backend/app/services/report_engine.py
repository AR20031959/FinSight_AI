import io
import datetime
from typing import Dict, Any, List
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.graphics.shapes import Drawing, Rect, String
from reportlab.graphics.charts.piecharts import Pie
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header border & text
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(36, 756, 576, 756)
        self.drawString(36, 762, "FinSight AI - Financial Analytics & Decision Intelligence Platform")
        self.drawRightString(576, 762, "Confidential Executive Statement")

        # Footer border & page number
        self.line(36, 45, 576, 45)
        self.drawString(36, 32, "Generated automatically by FinSight AI")
        self.drawRightString(576, 32, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def generate_pdf_report(
    user_name: str, 
    transactions: List[Dict[str, Any]], 
    summary: Dict[str, Any],
    start_date: str = None,
    end_date: str = None
) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=54,
        bottomMargin=54
    )
    story = []

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'DocTitle', parent=styles['Heading1'],
        fontName='Helvetica-Bold', fontSize=22, leading=26,
        textColor=colors.HexColor('#0F172A'), spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle', parent=styles['Normal'],
        fontName='Helvetica', fontSize=10, leading=14,
        textColor=colors.HexColor('#64748B'), spaceAfter=12
    )
    h2_style = ParagraphStyle(
        'H2', parent=styles['Heading2'],
        fontName='Helvetica-Bold', fontSize=13, leading=17,
        textColor=colors.HexColor('#1E293B'), spaceBefore=12, spaceAfter=8
    )
    body_style = ParagraphStyle(
        'Body', parent=styles['Normal'],
        fontName='Helvetica', fontSize=9, leading=13,
        textColor=colors.HexColor('#334155')
    )
    table_cell_style = ParagraphStyle(
        'TableCell', parent=styles['Normal'],
        fontName='Helvetica', fontSize=8.5, leading=11,
        textColor=colors.HexColor('#1E293B')
    )

    # Date range string display
    if not start_date:
        start_date = "Beginning"
    if not end_date:
        end_date = datetime.datetime.now().strftime("%Y-%m-%d")

    date_range_str = f"Date Period: {start_date} to {end_date}"
    gen_time_str = datetime.datetime.now().strftime("%B %d, %Y at %H:%M")

    # Document Header
    story.append(Paragraph("FinSight AI - Financial Decision Intelligence Report", title_style))
    story.append(Paragraph(f"Account Holder: <b>{user_name}</b> | {date_range_str} | Generated: {gen_time_str}", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#2563EB"), spaceAfter=14))

    # Calculate Period Totals from Filtered Transactions
    tot_income = sum((t.get("amount") or 0.0) for t in transactions if str(t.get("type") or "").lower() == "income")
    tot_expense = sum((t.get("amount") or 0.0) for t in transactions if str(t.get("type") or "").lower() == "expense")
    tot_investment = sum((t.get("amount") or 0.0) for t in transactions if str(t.get("type") or "").lower() == "investment")
    net_surplus = tot_income - tot_expense - tot_investment

    # Executive Summary Metric Cards
    cards_data = [
        [
            Paragraph(f"<b>Period Income</b><br/><font size=13 color='#16A34A'><b>INR {tot_income:,.2f}</b></font>", body_style),
            Paragraph(f"<b>Period Expenses</b><br/><font size=13 color='#DC2626'><b>INR {tot_expense:,.2f}</b></font>", body_style),
            Paragraph(f"<b>Investments</b><br/><font size=13 color='#0284C7'><b>INR {tot_investment:,.2f}</b></font>", body_style),
            Paragraph(f"<b>Net Cashflow</b><br/><font size=13 color='#2563EB'><b>INR {net_surplus:,.2f}</b></font>", body_style),
        ]
    ]
    t_cards = Table(cards_data, colWidths=[135, 135, 135, 135])
    t_cards.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#CBD5E1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_cards)
    story.append(Spacer(1, 14))

    # Health Score & AI Conversational Advisor Insights Box
    story.append(Paragraph("AI Conversational Insights & Period Assessment", h2_style))
    
    health_score = summary.get("health_score", 0.0)
    ai_insights = summary.get("ai_insights", [])
    
    insights_html = "<br/>".join([f"• {insight}" for insight in ai_insights]) if ai_insights else "• Account activity is cleanly tracked for this date period."
    
    hs_text = (
        f"<b>Financial Health Score: {health_score} / 100</b><br/>"
        f"{insights_html}"
    )
    t_hs = Table([[Paragraph(hs_text, body_style)]], colWidths=[540])
    t_hs.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#EFF6FF')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#93C5FD')),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(t_hs)
    story.append(Spacer(1, 14))

    # Category Visual Breakdown
    cat_breakdown = summary.get("category_breakdown", {})
    if cat_breakdown:
        story.append(Paragraph("Category Spending Allocation", h2_style))
        chart_drawing = Drawing(540, 130)
        pie = Pie()
        pie.x = 40
        pie.y = 5
        pie.width = 115
        pie.height = 115
        
        cats = list(cat_breakdown.keys())[:5]
        vals = [cat_breakdown[c] for c in cats]
        pie.data = vals
        pie.labels = cats
        
        slice_colors = [colors.HexColor('#EF4444'), colors.HexColor('#F59E0B'), colors.HexColor('#8B5CF6'), colors.HexColor('#06B6D4'), colors.HexColor('#10B981')]
        for i in range(len(cats)):
            pie.slices[i].fillColor = slice_colors[i % len(slice_colors)]
            
        chart_drawing.add(pie)
        story.append(chart_drawing)
        story.append(Spacer(1, 12))

    # Detailed Transactions Ledger Table
    story.append(Paragraph(f"Activity Ledger ({len(transactions)} Records in Selected Period)", h2_style))
    
    headers = [
        Paragraph("<b>Date</b>", table_cell_style),
        Paragraph("<b>Title / Description</b>", table_cell_style),
        Paragraph("<b>Category</b>", table_cell_style),
        Paragraph("<b>Type</b>", table_cell_style),
        Paragraph("<b>Amount (INR)</b>", table_cell_style),
    ]
    tx_rows = [headers]

    for t in transactions:
        tx_type = str(t.get("type") or "").upper()
        amt = float(t.get("amount") or 0.0)
        amt_str = f"INR {amt:,.2f}"
        
        tx_rows.append([
            Paragraph(str(t.get("date") or ""), table_cell_style),
            Paragraph(str(t.get("title") or ""), table_cell_style),
            Paragraph(str(t.get("category") or ""), table_cell_style),
            Paragraph(tx_type, table_cell_style),
            Paragraph(amt_str, table_cell_style),
        ])

    if len(transactions) == 0:
        tx_rows.append([
            Paragraph(f"No transactions recorded between {start_date} and {end_date}", table_cell_style),
            Paragraph("", table_cell_style),
            Paragraph("", table_cell_style),
            Paragraph("", table_cell_style),
            Paragraph("", table_cell_style)
        ])

    t_txs = Table(tx_rows, colWidths=[75, 195, 110, 75, 85])
    t_txs.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1E293B')),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#F8FAFC')]),
    ]))
    story.append(t_txs)

    doc.build(story, canvasmaker=NumberedCanvas)
    buffer.seek(0)
    return buffer.getvalue()

def generate_excel_report(
    user_name: str, 
    transactions: List[Dict[str, Any]], 
    summary: Dict[str, Any],
    start_date: str = None,
    end_date: str = None
) -> bytes:
    wb = Workbook()
    ws = wb.active
    ws.title = "FinSight Financial Statement"

    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="2563EB", end_color="2563EB", fill_type="solid")

    ws.append(["FinSight AI Financial Decision Report"])
    ws.append([f"User: {user_name}", f"Period: {start_date or 'Start'} to {end_date or 'End'}"])
    ws.append([])

    ws.append(["Summary Metric", "Value (INR)"])
    ws.append(["Total Period Income", summary.get("monthly_income", 0)])
    ws.append(["Total Period Expense", summary.get("monthly_expense", 0)])
    ws.append(["Total Investments", summary.get("total_investments", 0)])
    ws.append(["Net Savings", summary.get("savings", 0)])
    ws.append(["Financial Health Score", summary.get("health_score", 0)])
    ws.append([])

    ws.append(["ID", "Date", "Title", "Category", "Type", "Amount (INR)", "Merchant"])
    # Row 11 is the table header row
    for cell in ws[11]:
        cell.font = header_font
        cell.fill = header_fill

    for t in transactions:
        ws.append([
            t.get("id", ""),
            t.get("date", ""),
            t.get("title", ""),
            t.get("category", ""),
            t.get("type", ""),
            float(t.get("amount") or 0.0),
            t.get("merchant", "")
        ])

    buffer = io.BytesIO()
    wb.save(buffer)
    buffer.seek(0)
    return buffer.getvalue()


def generate_image_report(user_name: str, transactions: List[Dict[str, Any]], summary: Dict[str, Any], start_date: str = None, end_date: str = None) -> bytes:
    """
    Generates a high-resolution visual financial infographic image report (PNG format)
    using PIL and Matplotlib visual rendering.
    """
    # pyrefly: ignore [missing-import]
    from PIL import Image, ImageDraw
    import io

    # Create high-res canvas (1200 x 1600)
    img = Image.new("RGB", (1200, 1600), color="#0F172A")
    draw = ImageDraw.Draw(img)

    # Header Card
    draw.rectangle([40, 40, 1160, 160], fill="#1E293B", outline="#3B82F6", width=2)
    draw.text((60, 60), "FINSIGHT AI - VISUAL FINANCIAL INFOGRAPHIC REPORT", fill="#38BDF8")
    draw.text((60, 95), f"Account Holder: {user_name}  |  Period: {start_date or 'Start'} to {end_date or 'End'}", fill="#94A3B8")
    draw.text((60, 125), f"Generated: {datetime.datetime.now().strftime('%d %B %Y, %I:%M %p')}", fill="#64748B")

    # Metric Cards Grid
    income = float(summary.get("monthly_income") or 0.0)
    expense = float(summary.get("monthly_expense") or 0.0)
    invest = float(summary.get("total_investments") or 0.0)
    savings = float(summary.get("savings") or 0.0)
    health = summary.get("health_score", 85.0)

    cards = [
        ("PERIOD INCOME", f"INR {income:,.2f}", "#10B981", (40, 180, 580, 280)),
        ("PERIOD EXPENSES", f"INR {expense:,.2f}", "#EF4444", (620, 180, 1160, 280)),
        ("INVESTMENTS", f"INR {invest:,.2f}", "#06B6D4", (40, 300, 580, 400)),
        ("SURPLUS SAVINGS", f"INR {savings:,.2f}", "#F59E0B", (620, 300, 1160, 400)),
    ]

    for label, val, color, bounds in cards:
        draw.rectangle(bounds, fill="#1E293B", outline=color, width=2)
        draw.text((bounds[0] + 20, bounds[1] + 20), label, fill="#94A3B8")
        draw.text((bounds[0] + 20, bounds[1] + 50), val, fill=color)

    # Health Score Box
    draw.rectangle([40, 420, 1160, 520], fill="#1E293B", outline="#8B5CF6", width=2)
    draw.text((60, 440), f"FINANCIAL HEALTH SCORE: {health} / 100", fill="#A855F7")
    draw.text((60, 475), f"AI Insight: Account activity cleanly analyzed. {len(transactions)} activities in period.", fill="#E2E8F0")

    # Embedded Chart via Matplotlib
    try:
        # pyrefly: ignore [missing-import]
        import matplotlib
        matplotlib.use("Agg")
        # pyrefly: ignore [missing-import]
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots(figsize=(10, 4), facecolor="#1E293B")
        ax.set_facecolor("#1E293B")
        
        cats = list(summary.get("category_breakdown", {}).keys()) or ["Food", "Rent", "EMI", "Shopping"]
        vals = list(summary.get("category_breakdown", {}).values()) or [8500, 32000, 14200, 6890]
        
        ax.bar(cats, vals, color="#38BDF8")
        ax.set_title("Spending Category Distribution", color="white", fontsize=14)
        ax.tick_params(colors="white")
        for spine in ax.spines.values():
            spine.set_color("#475569")

        chart_buf = io.BytesIO()
        plt.savefig(chart_buf, format="png", bbox_inches="tight", dpi=130)
        plt.close(fig)
        chart_buf.seek(0)

        chart_img = Image.open(chart_buf)
        img.paste(chart_img, (40, 530))
    except Exception:
        draw.rectangle([40, 530, 1160, 830], fill="#1E293B", outline="#475569", width=1)
        draw.text((60, 670), "Visual Category Analytics Chart", fill="#94A3B8")

    # Transaction Table Header
    draw.rectangle([40, 860, 1160, 910], fill="#2563EB")
    draw.text((60, 875), "DATE", fill="white")
    draw.text((220, 875), "DESCRIPTION / TITLE", fill="white")
    draw.text((650, 875), "CATEGORY", fill="white")
    draw.text((900, 875), "AMOUNT (INR)", fill="white")

    # Table Rows
    y = 920
    for idx, t in enumerate(transactions[:11]):
        row_bg = "#1E293B" if idx % 2 == 0 else "#0F172A"
        draw.rectangle([40, y, 1160, y + 45], fill=row_bg)
        
        t_type = (t.get("type") or "").lower()
        amt = float(t.get("amount") or 0.0)
        amt_color = "#10B981" if t_type == "income" else ("#06B6D4" if t_type == "investment" else "#EF4444")
        
        draw.text((60, y + 12), str(t.get("date") or "")[:10], fill="#94A3B8")
        draw.text((220, y + 12), str(t.get("title") or "")[:32], fill="white")
        draw.text((650, y + 12), str(t.get("category") or "")[:20], fill="#94A3B8")
        draw.text((900, y + 12), f"INR {amt:,.2f}", fill=amt_color)
        y += 50

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return buf.getvalue()

