from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.session_manager import get_db
from database.models import MeshMessage, Agent
from core.security import get_current_agent
from core.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/mesh", tags=["mesh"])

@router.post("/messages")
async def receive_mesh_message(
    sender_node_id: str,
    recipient_agent_id: int,
    payload: str,
    db: Session = Depends(get_db),
    agent=Depends(get_current_agent)
):
    msg = MeshMessage(
        sender_node_id=sender_node_id,
        recipient_agent_id=recipient_agent_id,
        payload=payload,
        status="pending"
    )
    db.add(msg)
    db.commit()
    logger.info(f"Mesh message received from node {sender_node_id} for agent {recipient_agent_id}")
    return {"status": "received", "message_id": msg.id}

@router.get("/messages/pending")
async def get_pending_mesh_messages(
    db: Session = Depends(get_db),
    agent=Depends(get_current_agent)
):
    messages = db.query(MeshMessage).filter(
        MeshMessage.recipient_agent_id == agent.id,
        MeshMessage.status == "pending"
    ).all()
    return {"pending": len(messages), "messages": [{"id": m.id, "from": m.sender_node_id, "timestamp": m.timestamp} for m in messages]}

@router.post("/messages/{msg_id}/ack")
async def acknowledge_mesh_message(
    msg_id: int,
    db: Session = Depends(get_db),
    agent=Depends(get_current_agent)
):
    msg = db.query(MeshMessage).filter(MeshMessage.id == msg_id, MeshMessage.recipient_agent_id == agent.id).first()
    if not msg:
        raise HTTPException(404, "Message not found")
    msg.status = "delivered"
    db.commit()
    return {"status": "acknowledged"}

@router.post("/forward")
async def forward_mesh_messages(
    db: Session = Depends(get_db),
    agent=Depends(get_current_agent)
):
    if not settings.ENVIRONMENT == "production":
        pending = db.query(MeshMessage).filter(MeshMessage.status == "pending").all()
        delivered = 0
        for msg in pending:
            msg.status = "forwarded"
            delivered += 1
        db.commit()
        return {"forwarded": delivered}
    return {"forwarded": 0}
