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
    using PIL and Matplotlib visual rendering with dynamic height and zero text/graphic overlapping.
    """
    from PIL import Image, ImageDraw
    import io

    txs_to_show = transactions[:15]
    
    # Calculate required dynamic canvas height
    header_h = 130
    cards_h = 240
    health_h = 110
    chart_h = 420
    table_header_h = 50
    table_rows_h = len(txs_to_show) * 50
    footer_h = 60
    total_canvas_h = max(1400, 40 + header_h + 20 + cards_h + 20 + health_h + 20 + chart_h + 20 + table_header_h + table_rows_h + footer_h + 40)

    img = Image.new("RGB", (1200, total_canvas_h), color="#0F172A")
    draw = ImageDraw.Draw(img)

    y_cursor = 40

    # 1. Header Card
    draw.rectangle([40, y_cursor, 1160, y_cursor + header_h], fill="#1E293B", outline="#3B82F6", width=2)
    draw.text((60, y_cursor + 20), "FINSIGHT AI - EXECUTIVE FINANCIAL INFOGRAPHIC REPORT", fill="#38BDF8")
    
    period_str = f"{start_date or 'Beginning'} to {end_date or 'Present'}" if (start_date or end_date) else summary.get("period", "All Time")
    draw.text((60, y_cursor + 55), f"Account Holder: {user_name}  |  Report Period: {period_str}", fill="#94A3B8")
    draw.text((60, y_cursor + 85), f"Generated: {datetime.datetime.now().strftime('%d %B %Y, %I:%M %p')}", fill="#64748B")

    y_cursor += header_h + 20

    # 2. Metric Cards Grid
    income = float(summary.get("monthly_income") or 0.0)
    expense = float(summary.get("monthly_expense") or 0.0)
    invest = float(summary.get("total_investments") or 0.0)
    savings = float(summary.get("savings") or 0.0)
    health = float(summary.get("health_score") or 0.0)

    cards = [
        ("PERIOD INCOME", f"INR {income:,.2f}", "#10B981", (40, y_cursor, 580, y_cursor + 105)),
        ("PERIOD EXPENSES", f"INR {expense:,.2f}", "#EF4444", (620, y_cursor, 1160, y_cursor + 105)),
        ("INVESTMENTS", f"INR {invest:,.2f}", "#06B6D4", (40, y_cursor + 115, 580, y_cursor + 220)),
        ("NET SURPLUS SAVINGS", f"INR {savings:,.2f}", "#F59E0B", (620, y_cursor + 115, 1160, y_cursor + 220)),
    ]

    for label, val, color, bounds in cards:
        draw.rectangle(bounds, fill="#1E293B", outline=color, width=2)
        draw.text((bounds[0] + 20, bounds[1] + 20), label, fill="#94A3B8")
        draw.text((bounds[0] + 20, bounds[1] + 55), val, fill=color)

    y_cursor += cards_h + 20

    # 3. Health Score Box
    draw.rectangle([40, y_cursor, 1160, y_cursor + health_h], fill="#1E293B", outline="#8B5CF6", width=2)
    draw.text((60, y_cursor + 20), f"FINANCIAL HEALTH SCORE: {health:.1f} / 100", fill="#A855F7")
    
    ai_insights = summary.get("ai_insights", [])
    insight_text = ai_insights[0] if ai_insights else f"Account activity cleanly analyzed. {len(transactions)} entries recorded in period."
    if len(insight_text) > 100:
        insight_text = insight_text[:97] + "..."
    draw.text((60, y_cursor + 60), f"AI Executive Insight: {insight_text}", fill="#E2E8F0")

    y_cursor += health_h + 20

    # 4. Embedded Dynamic Visual Dual Charts via Matplotlib
    chart_y_start = y_cursor
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        cat_breakdown = summary.get("category_breakdown", {})
        cats = list(cat_breakdown.keys())
        vals = [float(cat_breakdown[k]) for k in cats]

        trend_data = summary.get("monthly_trend", [])
        if not trend_data and summary.get("yearly_trend"):
            trend_data = summary.get("yearly_trend", [])

        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 3.8), facecolor="#1E293B")
        fig.subplots_adjust(wspace=0.3)
        ax1.set_facecolor("#1E293B")
        ax2.set_facecolor("#1E293B")

        # Subplot 1: Category Breakdown Bar Chart
        if cats and any(v > 0 for v in vals):
            bars = ax1.bar(cats[:6], vals[:6], color="#38BDF8", edgecolor="#0284C7", width=0.45)
            ax1.set_title("Spending Breakdown", color="white", fontsize=11, fontweight="bold", pad=10)
            ax1.tick_params(colors="white", labelsize=8.5)
            ax1.tick_params(axis='x', rotation=25)
            for spine in ax1.spines.values():
                spine.set_color("#475569")
            ax1.grid(axis='y', linestyle='--', alpha=0.3, color='#64748B')
        else:
            ax1.text(0.5, 0.5, "No Expense Categories Recorded", color="#94A3B8", fontsize=10, ha="center", va="center")
            ax1.set_title("Spending Breakdown", color="white", fontsize=11, pad=10)
            ax1.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)
            for spine in ax1.spines.values():
                spine.set_color("#475569")

        # Subplot 2: Financial Trend Timeline
        if trend_data:
            x_labels = [str(item.get("month") or item.get("year") or "") for item in trend_data]
            inc_vals = [float(item.get("income") or 0.0) for item in trend_data]
            exp_vals = [float(item.get("expense") or 0.0) for item in trend_data]

            import numpy as np
            x_indices = np.arange(len(x_labels))
            bar_w = 0.35

            ax2.bar(x_indices - bar_w/2, inc_vals, width=bar_w, label="Income", color="#10B981")
            ax2.bar(x_indices + bar_w/2, exp_vals, width=bar_w, label="Expense", color="#EF4444")
            ax2.set_xticks(x_indices)
            ax2.set_xticklabels(x_labels, rotation=25, color="white", fontsize=8.5)
            ax2.set_title("Period Trend Timeline", color="white", fontsize=11, fontweight="bold", pad=10)
            ax2.tick_params(colors="white", labelsize=8.5)
            ax2.legend(facecolor="#1E293B", edgecolor="#475569", labelcolor="white", fontsize=8)
            for spine in ax2.spines.values():
                spine.set_color("#475569")
            ax2.grid(axis='y', linestyle='--', alpha=0.3, color='#64748B')
        else:
            ax2.text(0.5, 0.5, "No Timeline Activity Data", color="#94A3B8", fontsize=10, ha="center", va="center")
            ax2.set_title("Period Trend Timeline", color="white", fontsize=11, pad=10)
            ax2.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)
            for spine in ax2.spines.values():
                spine.set_color("#475569")

        chart_buf = io.BytesIO()
        plt.savefig(chart_buf, format="png", bbox_inches="tight", dpi=130)
        plt.close(fig)
        chart_buf.seek(0)

        chart_img = Image.open(chart_buf)
        img.paste(chart_img, (40, chart_y_start))
    except Exception:
        draw.rectangle([40, chart_y_start, 1160, chart_y_start + chart_h - 20], fill="#1E293B", outline="#475569", width=1)
        draw.text((60, chart_y_start + 180), "Visual Financial Analytics Charts", fill="#94A3B8")


    y_cursor += chart_h + 20

    # 5. Transaction Table Header
    draw.rectangle([40, y_cursor, 1160, y_cursor + table_header_h], fill="#2563EB")
    draw.text((60, y_cursor + 16), "DATE", fill="white")
    draw.text((220, y_cursor + 16), "DESCRIPTION / TITLE", fill="white")
    draw.text((650, y_cursor + 16), "CATEGORY", fill="white")
    draw.text((920, y_cursor + 16), "AMOUNT (INR)", fill="white")

    y_cursor += table_header_h

    # 6. Table Rows
    if not txs_to_show:
        draw.rectangle([40, y_cursor, 1160, y_cursor + 50], fill="#1E293B")
        draw.text((60, y_cursor + 16), "No transactions recorded for this period.", fill="#94A3B8")
        y_cursor += 50
    else:
        for idx, t in enumerate(txs_to_show):
            row_bg = "#1E293B" if idx % 2 == 0 else "#0F172A"
            draw.rectangle([40, y_cursor, 1160, y_cursor + 45], fill=row_bg)
            
            t_type = (t.get("type") or "").lower()
            amt = float(t.get("amount") or 0.0)
            amt_color = "#10B981" if t_type == "income" else ("#06B6D4" if t_type in ("investment", "savings") else "#EF4444")
            
            draw.text((60, y_cursor + 12), str(t.get("date") or "")[:10], fill="#94A3B8")
            draw.text((220, y_cursor + 12), str(t.get("title") or "")[:35], fill="white")
            draw.text((650, y_cursor + 12), str(t.get("category") or "")[:22], fill="#94A3B8")
            draw.text((920, y_cursor + 12), f"INR {amt:,.2f}", fill=amt_color)
            y_cursor += 48

    y_cursor += 20
    # 7. Report Footer
    draw.line([40, y_cursor, 1160, y_cursor], fill="#334155", width=1)
    draw.text((60, y_cursor + 15), "FinSight AI Decision Intelligence Platform  |  Automated Confidential Report", fill="#64748B")

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return buf.getvalue()


