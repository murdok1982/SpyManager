"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from pydantic_settings import BaseSettings
from pydantic import field_validator
from functools import lru_cache
from typing import List


class Settings(BaseSettings):
    imc_master_key: str
    database_url: str
    redis_url: str = "redis://localhost:6379"
    allowed_origins: List[str] = []
    cert_dir: str = "./certs"
    vector_db_path: str = "./data/chroma"
    environment: str = "production"
    rate_limit_wearable_events: str = "60/minute"
    rate_limit_mobile_reports: str = "20/minute"
    rate_limit_default: str = "100/minute"

    @field_validator("imc_master_key")
    @classmethod
    def validate_master_key(cls, v: str) -> str:
        try:
            key_bytes = bytes.fromhex(v)
        except ValueError as exc:
            raise ValueError("IMC_MASTER_KEY debe ser hex valido") from exc
        if len(key_bytes) != 32:
            raise ValueError("IMC_MASTER_KEY debe ser 64 caracteres hex (32 bytes)")
        if key_bytes == bytes(32):
            raise ValueError("IMC_MASTER_KEY no puede ser la clave cero — generar con: python3 -c \"import secrets; print(secrets.token_hex(32))\"")
        return v

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if not v:
            raise ValueError("DATABASE_URL es requerida")
        return v

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
