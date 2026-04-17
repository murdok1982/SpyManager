"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from typing import Optional

import structlog
from fastapi import Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.abac_engine import ClassificationLevel, UserAttributes
from app.core.exceptions import PKIError, SecurityError

logger = structlog.get_logger(__name__)


async def verify_pki_and_auth(
    request: Request,
    x_pki_entity_id: Optional[str] = Header(default=None),
) -> UserAttributes:
    """
    Validacion rigurosa de identidad:
    - development: acepta X-PKI-Entity-ID para testing
    - production: valida certificado cliente del TLS handshake
    - siempre: lookup real en DB de AgentProfile + verificacion de revocacion
    """
    from app.core.config import get_settings
    from app.database.session_manager import AsyncSessionLocal
    from app.database.models import AgentProfile

    settings = get_settings()
    pki = request.app.state.pki

    # Resolver entity_id segun entorno
    if settings.environment == "development":
        if not x_pki_entity_id:
            raise HTTPException(
                status_code=401,
                detail="X-PKI-Entity-ID header required in development mode",
            )
        entity_id = x_pki_entity_id
    else:
        # Produccion: extraer del certificado cliente del TLS handshake
        # El reverse proxy (nginx/traefik) debe inyectar el DN del cert en el header
        ssl_client_s_dn = request.headers.get("X-SSL-Client-S-DN")
        if not ssl_client_s_dn:
            raise HTTPException(
                status_code=401,
                detail="mTLS certificate required",
            )
        # Extraer UID del Distinguished Name: UID=agent-001,CN=...,O=...
        entity_id = _extract_uid_from_dn(ssl_client_s_dn)
        if not entity_id:
            raise HTTPException(
                status_code=401,
                detail="Cannot extract entity ID from client certificate",
            )

    # Verificar revocacion en PKI
    try:
        if pki.is_revoked(entity_id):
            logger.warning("entity_revoked_access_attempt", entity_id=entity_id)
            raise HTTPException(status_code=403, detail="ENTITY_NEUTRALIZED")
    except PKIError as exc:
        logger.error("pki_revocation_check_failed", error=exc.message)
        raise HTTPException(status_code=500, detail="PKI check failed") from exc

    # Lookup en base de datos
    if AsyncSessionLocal is None:
        logger.error("db_not_initialized_auth_rejected", entity_id=entity_id)
        raise HTTPException(status_code=503, detail="SERVICE_UNAVAILABLE")

    async with AsyncSessionLocal() as session:
        profile = await _get_agent_profile(session, entity_id)

    if profile is None:
        logger.warning("unknown_entity_access_attempt", entity_id=entity_id)
        raise HTTPException(status_code=403, detail="ENTITY_UNKNOWN")

    if profile.status != "ACTIVE":
        logger.warning(
            "inactive_entity_access_attempt",
            entity_id=entity_id,
            status=profile.status,
        )
        raise HTTPException(status_code=403, detail="ENTITY_INACTIVE")

    return UserAttributes(
        user_id=profile.id,
        role=profile.role,
        classification_level=ClassificationLevel[profile.classification_level],
        assigned_cases=profile.assigned_cases or [],
        is_active=True,
    )


async def _get_agent_profile(session: AsyncSession, entity_id: str):
    """Busca un AgentProfile por entity_id."""
    from app.database.models import AgentProfile

    stmt = select(AgentProfile).where(AgentProfile.entity_id == entity_id)
    result = await session.execute(stmt)
    return result.scalars().first()


def _extract_uid_from_dn(dn: str) -> Optional[str]:
    """Extrae el UID de un Distinguished Name como 'UID=agent-001,CN=...'."""
    for part in dn.split(","):
        part = part.strip()
        if part.upper().startswith("UID="):
            return part[4:].strip()
    return None


def _build_mock_profile(entity_id: str) -> UserAttributes:
    """Perfil mock solo para entornos sin DB (tests unitarios)."""
    return UserAttributes(
        user_id=entity_id,
        role="ANALISTA_CAMPO",
        classification_level=ClassificationLevel.SECRET,
        assigned_cases=["CASO_ALPHA", "CASO_OMEGA"],
        is_active=True,
    )
