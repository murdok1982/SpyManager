"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from contextlib import asynccontextmanager
from typing import AsyncIterator

from pydantic import BaseModel, Field
import structlog
import structlog.stdlib
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

from app.core.abac_engine import ABACEngine, ClassificationPolicy, CaseAssignmentPolicy
from app.core.config import get_settings
from app.core.exceptions import (
    ABACDeniedError,
    AuditIntegrityError,
    DatabaseError,
    EncryptionError,
    IMCError,
    PKIError,
    SecurityError,
)
from app.core.pki_manager import PKIManager
from app.database.session_manager import close_db, init_db
from app.services.ai_compartment import AICompartmentService
from app.services.audit_service import AuditService
from app.services.encryption_service import EncryptionService
from app.services.kill_switch_service import KillSwitchService

# Logging estructurado — nunca imprime secrets
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Inicializa y limpia todos los servicios en el ciclo de vida de la app."""
    settings = get_settings()

    # Fail-fast: Settings valida master key y database_url al instanciarse
    init_db(settings)

    master_key = bytes.fromhex(settings.imc_master_key)

    # DI container en app.state
    app.state.encryption = EncryptionService(master_key)
    app.state.pki = PKIManager(settings.cert_dir, master_key)
    app.state.pki.generate_ca()
    app.state.audit = AuditService()
    app.state.abac = ABACEngine([ClassificationPolicy(), CaseAssignmentPolicy()])
    app.state.ai = AICompartmentService(settings.vector_db_path)
    app.state.kill_switch = KillSwitchService(app.state.pki, app.state.audit)

    logger.info("imc_started", environment=settings.environment)
    yield

    await close_db()
    logger.info("imc_stopped")


class KillSwitchBody(BaseModel):
    target_id: str = Field(..., min_length=4, max_length=64, pattern=r"^[A-Za-z0-9\-_]+$")
    reason: str = Field(..., min_length=4, max_length=256)


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="Intelligence Management Core (IMC)",
        version="2.0.0",
        lifespan=lifespan,
        # Sin docs en produccion (evita exposicion de superficie de ataque)
        docs_url="/docs" if settings.environment == "development" else None,
        redoc_url="/redoc" if settings.environment == "development" else None,
        openapi_url="/openapi.json" if settings.environment == "development" else None,
    )

    # Rate limiter global
    limiter = Limiter(key_func=get_remote_address, default_limits=[settings.rate_limit_default])
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)

    # CORS — nunca wildcard en produccion
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-PKI-Entity-ID"],
    )

    # Exception handlers centralizados
    @app.exception_handler(ABACDeniedError)
    async def abac_denied_handler(request: Request, exc: ABACDeniedError) -> JSONResponse:
        logger.warning("abac_denied", code=exc.code)
        return JSONResponse(status_code=403, content={"detail": exc.code})

    @app.exception_handler(SecurityError)
    async def security_error_handler(request: Request, exc: SecurityError) -> JSONResponse:
        logger.error("security_error", code=exc.code)
        return JSONResponse(status_code=401, content={"detail": exc.code})

    @app.exception_handler(PKIError)
    async def pki_error_handler(request: Request, exc: PKIError) -> JSONResponse:
        logger.error("pki_error", code=exc.code)
        return JSONResponse(status_code=403, content={"detail": exc.code})

    @app.exception_handler(EncryptionError)
    async def encryption_error_handler(request: Request, exc: EncryptionError) -> JSONResponse:
        # No exponer detalles de fallo de cifrado
        logger.error("encryption_error")
        return JSONResponse(status_code=500, content={"detail": "INTERNAL_SECURE_ERROR"})

    @app.exception_handler(AuditIntegrityError)
    async def audit_error_handler(request: Request, exc: AuditIntegrityError) -> JSONResponse:
        logger.critical("audit_integrity_broken", entry_id=exc.entry_id)
        return JSONResponse(status_code=500, content={"detail": "AUDIT_INTEGRITY_VIOLATION"})

    @app.exception_handler(DatabaseError)
    async def database_error_handler(request: Request, exc: DatabaseError) -> JSONResponse:
        logger.error("database_error")
        return JSONResponse(status_code=503, content={"detail": "SERVICE_UNAVAILABLE"})

    @app.exception_handler(IMCError)
    async def imc_error_handler(request: Request, exc: IMCError) -> JSONResponse:
        logger.error("imc_error", code=exc.code)
        return JSONResponse(status_code=500, content={"detail": "INTERNAL_SECURE_ERROR"})

    # Routers
    from app.api.wearable_api import router as wearable_router
    from app.api.mobile_api import router as mobile_router
    from app.api.intel_api import router as intel_router

    app.include_router(intel_router, prefix="/api/v1")
    app.include_router(wearable_router, prefix="/api/v1")
    app.include_router(mobile_router, prefix="/api/v1")

    # Kill switch endpoint (requiere ADMIN/DIRECTOR)
    from fastapi import Depends
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.core.abac_engine import UserAttributes
    from app.core.security import verify_pki_and_auth
    from app.database.session_manager import get_db

    @app.post("/api/v1/system/kill-switch", tags=["System"])
    @limiter.limit("5/minute")
    async def trigger_emergency_kill(
        request: Request,
        body: KillSwitchBody,
        user: UserAttributes = Depends(verify_pki_and_auth),
        db: AsyncSession = Depends(get_db),
    ) -> dict:
        """Activacion del Kill Switch. Solo ADMIN/DIRECTOR."""
        if user.role not in ("ADMIN", "DIRECTOR"):
            raise ABACDeniedError(user.user_id, "kill-switch", "trigger")
        logger.warning(
            "kill_switch_triggered",
            operator=user.user_id,
            target=body.target_id,
            client_ip=request.client.host if request.client else "unknown",
        )
        ks: KillSwitchService = app.state.kill_switch
        return await ks.trigger_kill_switch(body.target_id, user.user_id, body.reason, db)

    @app.get("/health", tags=["System"])
    def health_check() -> dict:
        return {"status": "OPERATIONAL", "security": "ZERO_TRUST_ENFORCED"}

    return app


app = create_app()
