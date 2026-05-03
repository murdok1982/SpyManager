from fastapi import HTTPException
from core.config import settings
import logging

logger = logging.getLogger(__name__)

class CDSService:
    def __init__(self):
        self.classifications = settings.CDS_CLASSIFICATIONS

    def validate_transfer(self, user_clearance: str, data_classification: str):
        try:
            user_idx = self.classifications.index(user_clearance)
            data_idx = self.classifications.index(data_classification)
        except ValueError:
            raise HTTPException(400, "Invalid classification level")
        if user_idx < data_idx:
            raise HTTPException(403, "Insufficient clearance for CDS transfer")
        logger.info(f"CDS transfer validated: user={user_clearance}, data={data_classification}")
        return True

    def guard_transfer(self, data: dict, user_clearance: str, target_classification: str):
        self.validate_transfer(user_clearance, data.get("classification", "UNCLASSIFIED"))
        logger.info(f"CDS guard transfer to {target_classification}")
        return {"status": "transferred", "sanitized": True}

cds_service = CDSService()
