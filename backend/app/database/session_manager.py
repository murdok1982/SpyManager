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
from app.core.config import settings as app_settings

logger = structlog.get_logger(__name__)

engine: Optional[AsyncEngine] = None
AsyncSessionLocal: Optional[async_sessionmaker[AsyncSession]] = None
replica_engine: Optional[AsyncEngine] = None
ReplicaSessionLocal: Optional[async_sessionmaker[AsyncSession]] = None

# Re-export Base for alembic env.py
from app.database.models import Base  # noqa: E402, F401


def init_db(settings) -> None:
    """Inicializa el motor y la fabrica de sesiones. Llamar en lifespan."""
    global engine, AsyncSessionLocal, replica_engine, ReplicaSessionLocal

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

    if settings.postgres_replica_url:
        replica_engine = create_async_engine(
            settings.postgres_replica_url,
            pool_size=10,
            max_overflow=5,
            pool_timeout=30,
            pool_recycle=1800,
            pool_pre_ping=True,
            echo=False,
        )
        ReplicaSessionLocal = async_sessionmaker(replica_engine, expire_on_commit=False)
        logger.info("read_replica_initialized", url=_safe_url(settings.postgres_replica_url))

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


async def get_db(read_only: bool = False) -> AsyncGenerator[AsyncSession, None]:
    """Dependencia FastAPI que provee una sesion con commit/rollback automatico.
    Use read_only=True for queries that can go to replica."""
    if read_only and ReplicaSessionLocal is not None:
        async with ReplicaSessionLocal() as session:
            try:
                yield session
            except Exception:
                raise
    else:
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
