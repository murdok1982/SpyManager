from core.config import settings
import logging

logger = logging.getLogger(__name__)

class Link16Service:
    def __init__(self):
        self.enabled = settings.STANAG_ENABLED

    def export_intel(self, intel: dict) -> str:
        if not self.enabled:
            return ""
        msg = f"STANAG5516|{intel.get('id', '')}|{intel.get('timestamp', '')}|{intel.get('classification', '')}|{intel.get('content', '')[:100]}"
        logger.info(f"Link 16 export: intel {intel.get('id')}")
        return msg

    def import_intel(self, link16_msg: str) -> dict:
        if not self.enabled:
            return {}
        try:
            parts = link16_msg.split("|")
            if len(parts) < 5 or parts[0] != "STANAG5516":
                raise ValueError("Invalid STANAG 5516 format")
            return {
                "id": parts[1],
                "timestamp": parts[2],
                "classification": parts[3],
                "content": parts[4]
            }
        except Exception as e:
            logger.error(f"Link 16 import error: {e}")
            return {}

link16_service = Link16Service()
