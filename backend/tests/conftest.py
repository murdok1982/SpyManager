import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from unittest.mock import AsyncMock, MagicMock
import os

os.environ.setdefault("IMC_MASTER_KEY", "a" * 64)
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("ENVIRONMENT", "development")

from app.main import app
from app.database.session_manager import Base, get_db
from app.services.encryption_service import EncryptionService

TEST_MASTER_KEY = bytes.fromhex("a" * 64)

@pytest.fixture
def encryption_service():
    return EncryptionService(TEST_MASTER_KEY)

@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
