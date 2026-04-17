"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import datetime

import structlog
from fastapi import APIRouter, Depends, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.abac_engine import UserAttributes
from app.core.security import verify_pki_and_auth
from app.database.session_manager import get_db
from app.schemas.wearable import (
    WearableEvent,
    WearableEventResponse,
    WearableHeartbeat,
)
from app.services.agent_sync_service import AgentSyncService

logger = structlog.get_logger(__name__)
limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/wearable", tags=["WearOS"])


def _get_sync_service(request: Request) -> AgentSyncService:
    return AgentSyncService(encryption=request.app.state.encryption)


@router.post("/events", response_model=WearableEventResponse, status_code=201)
@limiter.limit("60/minute")
async def receive_wearable_event(
    request: Request,
    event: WearableEvent,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> WearableEventResponse:
    """
    Recibe un evento de wearable (ubicacion, biometricos, intel).
    Rate limit: 60 req/min por IP.
    """
    # Verificar que el agente del evento coincide con el autenticado
    if event.agent_id != user.user_id and user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="AGENT_ID_MISMATCH")

    sync = _get_sync_service(request)
    log = await sync.process_wearable_event(event, db)

    # Entrada de auditoria
    audit = request.app.state.audit
    last_hash = await audit.get_last_hash(db)
    audit_result = audit.create_entry(
        user_id=user.user_id,
        action="WEARABLE_EVENT",
        resource_id=log.id,
        reason_code=event.event_type.value,
        device_id=event.device_id,
        previous_hash=last_hash,
    )
    from app.database.models import AccessLog
    db.add(AccessLog(
        user_id=user.user_id,
        action="WEARABLE_EVENT",
        resource_id=log.id,
        reason_code=event.event_type.value,
        device_id=event.device_id,
        integrity_hash=audit_result["integrity_hash"],
        previous_hash=last_hash,
    ))

    return WearableEventResponse(
        status="SIGNAL_ACK",
        event_id=log.id,
        received_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    )


@router.post("/emergency", response_model=WearableEventResponse, status_code=201)
@limiter.limit("10/minute")
async def receive_emergency(
    request: Request,
    event: WearableEvent,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> WearableEventResponse:
    """
    SOS de emergencia — maxima prioridad.
    Rate limit: 10 req/min (el SOS genuino es raro; limitar evita flood).
    """
    if event.agent_id != user.user_id and user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="AGENT_ID_MISMATCH")

    sync = _get_sync_service(request)
    log = await sync.process_emergency(event, db)

    audit = request.app.state.audit
    last_hash = await audit.get_last_hash(db)
    audit_result = audit.create_entry(
        user_id=user.user_id,
        action="EMERGENCY_SOS",
        resource_id=log.id,
        reason_code="EMERGENCY",
        device_id=event.device_id,
        previous_hash=last_hash,
    )
    from app.database.models import AccessLog
    db.add(AccessLog(
        user_id=user.user_id,
        action="EMERGENCY_SOS",
        resource_id=log.id,
        reason_code="EMERGENCY",
        device_id=event.device_id,
        integrity_hash=audit_result["integrity_hash"],
        previous_hash=last_hash,
    ))

    return WearableEventResponse(
        status="EMERGENCY_ACK",
        event_id=log.id,
        received_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    )


@router.get("/config/{device_id}")
@limiter.limit("30/minute")
async def get_device_config(
    request: Request,
    device_id: str,
    _user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Obtiene la configuracion de un dispositivo wearable."""
    sync = _get_sync_service(request)
    config = await sync.get_device_config(device_id, db)
    if config is None:
        raise HTTPException(status_code=404, detail="DEVICE_NOT_FOUND")
    return config


@router.post("/heartbeat", status_code=204)
@limiter.limit("120/minute")
async def device_heartbeat(
    request: Request,
    heartbeat: WearableHeartbeat,
    _user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    Heartbeat de dispositivo activo.
    Actualiza last_heartbeat en DB. Rate limit: 120/min (cada 30s aprox).
    """
    sync = _get_sync_service(request)
    await sync.register_heartbeat(heartbeat.device_id, db)
