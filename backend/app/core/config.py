from pydantic_settings import BaseSettings
from typing import Optional, Literal

class Settings(BaseSettings):
    # Existing settings preserved
    DB_PASSWORD: str
    REDIS_PASSWORD: str
    IMC_MASTER_KEY: str
    DATABASE_URL: str
    ALLOWED_ORIGINS: str
    ENVIRONMENT: str
    CERT_DIR: str
    VECTOR_DB_PATH: str

    # Read-Replica PostgreSQL
    POSTGRES_PRIMARY_URL: str = ""
    POSTGRES_REPLICA_URL: Optional[str] = None
    POSTGRES_PRIMARY_GEO: str = "us-east-1"
    POSTGRES_REPLICA_GEO: str = "eu-west-1"

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # SIEM Integration
    SIEM_ENABLED: bool = False
    SIEM_TYPE: Literal["splunk", "qradar"] = "splunk"
    SIEM_HEC_URL: Optional[str] = None
    SIEM_HEC_TOKEN: Optional[str] = None
    SIEM_SYSLOG_HOST: Optional[str] = None
    SIEM_SYSLOG_PORT: int = 514

    # Neo4j (Link Analysis)
    NEO4J_URI: str = "bolt://neo4j:7687"
    NEO4J_USER: str = "neo4j"
    NEO4J_PASSWORD: str = "CHANGE_ME_STRONG_PASSWORD"

    # Hyperledger Fabric (Distributed Audit)
    HYPERLEDGER_ENABLED: bool = False
    HYPERLEDGER_PEER_URL: str = "http://peer0.org1.example.com:7051"
    HYPERLEDGER_CHANNEL: str = "spychannel"
    HYPERLEDGER_CHAINCODE: str = "auditcc"

    # ChromaDB
    CHROMA_PERSIST_DIR: str = "./data/chroma"

    # Circuit Breaker
    CIRCUIT_BREAKER_FAIL_MAX: int = 5
    CIRCUIT_BREAKER_RESET_TIMEOUT: int = 60

    # Dead Man's Switch
    AGENT_CHECKIN_THRESHOLD_HOURS: int = 48

    # STANAG 5516 / Link 16
    STANAG_ENABLED: bool = False

    # Cross-Domain Solution (CDS)
    CDS_CLASSIFICATIONS: list[str] = ["UNCLASSIFIED", "CONFIDENTIAL", "SECRET", "TOP_SECRET"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
