from fastapi import APIRouter, HTTPException
from core.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/integrations", tags=["integrations"])

from fastapi import Depends, HTTPException
from core.security import get_current_agent
from core.config import settings

@router.post("/sap/sync")
async def sync_sap(data: dict, agent=Depends(get_current_agent)):
    if not settings.ENVIRONMENT == "production":
        logger.info(f"SAP sync by {agent.id}: {len(data)} records")
        return {"status": "synced", "records": len(data)}
    raise HTTPException(503, "SAP integration not available")

@router.post("/surveillance/ingest")
async def ingest_surveillance(data: dict, agent=Depends(get_current_agent)):
    logger.info(f"Surveillance ingest by {agent.id}: {data.get('source', 'unknown')}")
    return {"status": "ingested", "id": data.get("id")}

@router.post("/satellite/ingest")
async def ingest_satellite(data: dict, agent=Depends(get_current_agent)):
    logger.info(f"Satellite ingest by {agent.id}: {data.get('satellite_id', 'unknown')}")
    return {"status": "ingested", "id": data.get("id")}

@router.post("/sigint/ingest")
async def ingest_sigint(data: dict, agent=Depends(get_current_agent)):
    logger.info(f"SIGINT ingest by {agent.id}: {data.get('source_type', 'unknown')}")
    return {"status": "ingested", "id": data.get("id")}
