"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from typing import AsyncGenerator, Optional

import structlog
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.exceptions import DatabaseError

logger = structlog.get_logger(__name__)

engine: Optional[AsyncEngine] = None
AsyncSessionLocal: Optional[async_sessionmaker[AsyncSession]] = None

# Re-export Base for alembic env.py
from app.database.models import Base  # noqa: E402, F401


def init_db(settings) -> None:
    """Inicializa el motor y la fabrica de sesiones. Llamar en lifespan."""
    global engine, AsyncSessionLocal

    engine = create_async_engine(
        settings.database_url,
        pool_size=20,
        max_overflow=10,
        pool_timeout=30,
        pool_recycle=1800,
        pool_pre_ping=True,
        echo=(settings.environment == "development"),
    )
    AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)
    logger.info("database_initialized", url=_safe_url(settings.database_url))


def _safe_url(url: str) -> str:
    """Oculta credenciales de la URL para logging."""
    try:
        from urllib.parse import urlparse, urlunparse
        parsed = urlparse(url)
        safe = parsed._replace(netloc=f"***:***@{parsed.hostname}:{parsed.port}")
        return urlunparse(safe)
    except Exception:
        return "***"


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependencia FastAPI que provee una sesion con commit/rollback automatico."""
    if AsyncSessionLocal is None:
        raise DatabaseError("Database not initialized — call init_db() in lifespan")

    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def close_db() -> None:
    """Cierra el motor al shutdown de la aplicacion."""
    global engine
    if engine is not None:
        await engine.dispose()
        logger.info("database_connection_closed")
        engine = None
