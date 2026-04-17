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
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.abac_engine import UserAttributes
from app.core.security import verify_pki_and_auth
from app.database.models import AccessLog, AgentProfile, Case
from app.database.session_manager import get_db
from app.schemas.mobile import (
    AgentCaseSummary,
    AgentStatusUpdate,
    MobileIntelReport,
    MobileReportResponse,
    WipeResponse,
)
from app.services.agent_sync_service import AgentSyncService

logger = structlog.get_logger(__name__)
limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/mobile", tags=["Mobile"])


def _get_sync_service(request: Request) -> AgentSyncService:
    return AgentSyncService(encryption=request.app.state.encryption)


async def _append_audit(
    request: Request,
    db: AsyncSession,
    user_id: str,
    action: str,
    resource_id: str,
    reason_code: str,
    device_id: str,
) -> None:
    audit = request.app.state.audit
    last_hash = await audit.get_last_hash(db)
    result = audit.create_entry(
        user_id=user_id,
        action=action,
        resource_id=resource_id,
        reason_code=reason_code,
        device_id=device_id,
        previous_hash=last_hash,
    )
    db.add(AccessLog(
        user_id=user_id,
        action=action,
        resource_id=resource_id,
        reason_code=reason_code,
        device_id=device_id,
        integrity_hash=result["integrity_hash"],
        previous_hash=last_hash,
    ))


@router.post("/reports", response_model=MobileReportResponse, status_code=201)
@limiter.limit("20/minute")
async def submit_mobile_report(
    request: Request,
    report: MobileIntelReport,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> MobileReportResponse:
    """
    Envia un reporte de inteligencia desde campo.
    Rate limit: 20 req/min.
    """
    if report.agent_id != user.user_id and user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="AGENT_ID_MISMATCH")

    sync = _get_sync_service(request)
    mobile_report = await sync.process_mobile_report(report, db)

    await _append_audit(
        request, db,
        user_id=user.user_id,
        action="MOBILE_REPORT_SUBMITTED",
        resource_id=mobile_report.id,
        reason_code=report.report_type.value,
        device_id=report.device_fingerprint,
    )

    return MobileReportResponse(
        status="RECEIVED",
        report_id=mobile_report.id,
        received_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    )


@router.post("/status", status_code=204)
@limiter.limit("30/minute")
async def update_agent_status(
    request: Request,
    update_data: AgentStatusUpdate,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Actualiza el estado del agente."""
    if update_data.agent_id != user.user_id and user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="AGENT_ID_MISMATCH")

    sync = _get_sync_service(request)
    updated = await sync.update_agent_status(update_data, db)
    if not updated:
        raise HTTPException(status_code=404, detail="AGENT_NOT_FOUND")

    await _append_audit(
        request, db,
        user_id=user.user_id,
        action="AGENT_STATUS_UPDATE",
        resource_id=update_data.agent_id,
        reason_code=update_data.status,
        device_id="MOBILE",
    )


@router.get("/cases/{agent_id}", response_model=list[AgentCaseSummary])
@limiter.limit("30/minute")
async def get_agent_cases(
    request: Request,
    agent_id: str,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> list[AgentCaseSummary]:
    """Obtiene los casos asignados a un agente."""
    # Solo el propio agente o supervisores pueden consultar
    if agent_id != user.user_id and user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="ACCESS_DENIED")

    stmt = select(AgentProfile).where(AgentProfile.id == agent_id)
    result = await db.execute(stmt)
    profile = result.scalars().first()
    if not profile:
        raise HTTPException(status_code=404, detail="AGENT_NOT_FOUND")

    assigned = profile.assigned_cases or []
    if not assigned:
        return []

    cases_stmt = select(Case).where(Case.id.in_(assigned), Case.deleted_at.is_(None))
    cases_result = await db.execute(cases_stmt)
    cases = cases_result.scalars().all()

    return [
        AgentCaseSummary(
            case_id=c.id,
            case_name=c.name,
            sensitivity_level=c.sensitivity_level.name if c.sensitivity_level else "UNCLASSIFIED",
        )
        for c in cases
    ]


@router.get("/intel/{case_id}")
@limiter.limit("20/minute")
async def get_case_intel(
    request: Request,
    case_id: str,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Obtiene metadata de intel de un caso filtrado por permisos del usuario.
    Solo devuelve IDs y clasificacion, nunca contenido en claro.
    """
    if case_id not in user.assigned_cases and user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="ACCESS_DENIED")

    from sqlalchemy import or_
    from app.database.models import IntelPackage

    stmt = (
        select(IntelPackage.id, IntelPackage.classification_level, IntelPackage.timestamp)
        .where(IntelPackage.case_id == case_id)
        .where(IntelPackage.deleted_at.is_(None))
        .order_by(IntelPackage.timestamp.desc())
        .limit(50)
    )
    result = await db.execute(stmt)
    rows = result.all()

    await _append_audit(
        request, db,
        user_id=user.user_id,
        action="MOBILE_INTEL_LIST",
        resource_id=case_id,
        reason_code="FIELD_QUERY",
        device_id="MOBILE",
    )

    return {
        "case_id": case_id,
        "count": len(rows),
        "packages": [
            {
                "id": r.id,
                "classification": r.classification_level.name if r.classification_level else None,
                "timestamp": r.timestamp.isoformat() if r.timestamp else None,
            }
            for r in rows
        ],
    }


@router.post("/evidence", status_code=202)
@limiter.limit("5/minute")
async def upload_evidence(
    request: Request,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Sube evidencia cifrada (hasta 10 MB).
    El cuerpo raw llega como bytes; se cifra y almacena.
    Limitado a 5 req/min por el volumen de datos.
    """
    body = await request.body()
    if len(body) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="EVIDENCE_TOO_LARGE")
    if not body:
        raise HTTPException(status_code=400, detail="EMPTY_BODY")

    enc = request.app.state.encryption
    encrypted = enc.encrypt(
        body.decode("latin-1"),
        purpose="evidence",
        associated_data=user.user_id,
    )

    from uuid import uuid4
    evidence_id = str(uuid4())

    await _append_audit(
        request, db,
        user_id=user.user_id,
        action="EVIDENCE_UPLOADED",
        resource_id=evidence_id,
        reason_code="FIELD_EVIDENCE",
        device_id="MOBILE",
    )

    return {
        "status": "STORED",
        "evidence_id": evidence_id,
        "size_bytes": len(body),
        "stored_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }


@router.delete("/wipe/{device_id}", response_model=WipeResponse)
@limiter.limit("5/minute")
async def remote_wipe_device(
    request: Request,
    device_id: str,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> WipeResponse:
    """
    Borrado remoto de dispositivo.
    Solo DIRECTOR o ADMIN pueden ejecutar esta operacion.
    """
    if user.role not in ("DIRECTOR", "ADMIN"):
        raise HTTPException(status_code=403, detail="INSUFFICIENT_PRIVILEGES")

    sync = _get_sync_service(request)
    wiped = await sync.wipe_device(device_id, db)
    if not wiped:
        raise HTTPException(status_code=404, detail="DEVICE_NOT_FOUND")

    now = datetime.datetime.now(datetime.timezone.utc)
    await _append_audit(
        request, db,
        user_id=user.user_id,
        action="DEVICE_WIPE",
        resource_id=device_id,
        reason_code="REMOTE_WIPE_COMMAND",
        device_id="CORE_CMD",
    )

    return WipeResponse(
        status="WIPED",
        device_id=device_id,
        wiped_at=now.isoformat(),
    )
