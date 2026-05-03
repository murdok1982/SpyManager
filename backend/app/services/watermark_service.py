from PyPDF2 import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from io import BytesIO
from core.config import settings
import hashlib
import logging

logger = logging.getLogger(__name__)

class WatermarkService:
    def __init__(self):
        self.master_key = settings.IMC_MASTER_KEY

    def add_pdf_watermark(self, input_path: str, output_path: str, classification: str, agent_id: int):
        try:
            reader = PdfReader(input_path)
            writer = PdfWriter()
            watermark_text = f"CONFIDENTIAL | Agent:{agent_id} | {classification}"
            hash_mark = hashlib.sha256(f"{watermark_text}{self.master_key}".encode()).hexdigest()[:16]
            packet = BytesIO()
            can = canvas.Canvas(packet, pagesize=letter)
            can.setFillColorRGB(0.9, 0.9, 0.9, alpha=0.1)
            can.setFont("Helvetica", 8)
            can.drawString(50, 30, watermark_text)
            can.drawString(450, 30, f"HASH:{hash_mark}")
            can.save()
            packet.seek(0)
            watermark = PdfReader(packet).pages[0]
            for page in reader.pages:
                page.merge_page(watermark)
                page.metadata = {
                    "/Author": "SpyManager",
                    "/Classification": classification,
                    "/Watermark": watermark_text,
                    "/Hash": hash_mark
                }
                writer.add_page(page)
            with open(output_path, "wb") as f:
                writer.write(f)
            logger.info(f"PDF watermarked: {classification} for agent {agent_id}")
            return output_path
        except Exception as e:
            logger.error(f"Watermark error: {e}")
            raise

    def embed_text_watermark(self, text: str, agent_id: int, classification: str) -> str:
        hash_mark = hashlib.sha256(f"{agent_id}{classification}{self.master_key}".encode()).hexdigest()[:16]
        watermark_line = f"\n--- SpyManager | Agent:{agent_id} | {classification} | {hash_mark} ---\n"
        return text + watermark_line

watermark_service = WatermarkService()
