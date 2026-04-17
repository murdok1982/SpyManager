"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import structlog
from fastapi import APIRouter, Depends, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.abac_engine import UserAttributes
from app.core.exceptions import ABACDeniedError
from app.core.security import verify_pki_and_auth
from app.database.repository import IntelRepository
from app.database.session_manager import get_db
from app.schemas.intel import IntelCreate, IntelResponse

logger = structlog.get_logger(__name__)
limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/intel", tags=["Intelligence"])


def _get_repo(request: Request, db: AsyncSession) -> IntelRepository:
    return IntelRepository(
        db=db,
        encryption=request.app.state.encryption,
        audit=request.app.state.audit,
        abac=request.app.state.abac,
    )


@router.post("/ingest", status_code=201)
@limiter.limit("30/minute")
async def ingest_intelligence(
    request: Request,
    data: IntelCreate,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Punto de entrada seguro para la ingestion de inteligencia.
    Pipeline: PKI Validation -> ABAC -> Encryption -> Audit -> AI Indexing.
    """
    repo = _get_repo(request, db)

    try:
        package = await repo.create_package(user, data.model_dump())
    except ABACDeniedError as exc:
        raise HTTPException(status_code=403, detail=exc.code) from exc
    except Exception as exc:
        logger.error("intel_ingest_error", error=type(exc).__name__)
        raise HTTPException(status_code=500, detail="INTERNAL_SECURE_ERROR") from exc

    # Indexar en IA compartimentada (fire-and-forget, no bloquea respuesta)
    import asyncio
    ai = request.app.state.ai
    asyncio.create_task(ai.ingest_intel(data.case_id, package.id, data.content))

    return {
        "status": "SECURE_INGESTED",
        "package_id": package.id,
        "hash_integrity": package.access_log_reference,
    }


@router.get("/{package_id}", response_model=IntelResponse)
@limiter.limit("60/minute")
async def get_intel_package(
    request: Request,
    package_id: str,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db),
) -> IntelResponse:
    """Recupera un paquete de inteligencia si el usuario tiene acceso."""
    repo = _get_repo(request, db)

    try:
        result = await repo.get_package(user, package_id)
    except ABACDeniedError as exc:
        raise HTTPException(status_code=403, detail=exc.code) from exc
    except Exception as exc:
        logger.error("intel_read_error", error=type(exc).__name__)
        raise HTTPException(status_code=500, detail="INTERNAL_SECURE_ERROR") from exc

    if result is None:
        raise HTTPException(status_code=404, detail="PACKAGE_NOT_FOUND")

    return IntelResponse(**result)
