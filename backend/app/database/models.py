"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from uuid import uuid4

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
)
from sqlalchemy.orm import DeclarativeBase, relationship
from sqlalchemy.sql import func

from app.core.abac_engine import ClassificationLevel


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    username = Column(String, unique=True, index=True, nullable=False)
    role = Column(String, nullable=False)
    classification_level = Column(Enum(ClassificationLevel), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    assigned_cases = Column(JSON, default=list)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class AgentProfile(Base):
    """Perfil de agente con su entity_id de PKI."""

    __tablename__ = "agent_profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    entity_id = Column(String, unique=True, nullable=False, index=True)
    role = Column(String, nullable=False)
    classification_level = Column(String, nullable=False)
    assigned_cases = Column(JSON, default=list)
    status = Column(String, default="ACTIVE", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    last_seen = Column(DateTime(timezone=True), nullable=True)

    wearable_devices = relationship("WearableDevice", back_populates="agent", lazy="select")
    mobile_reports = relationship("MobileReport", back_populates="agent", lazy="select")


class Case(Base):
    __tablename__ = "cases"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    name = Column(String, nullable=False)
    description = Column(String)
    sensitivity_level = Column(Enum(ClassificationLevel), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)


class SourceProfile(Base):
    __tablename__ = "source_profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    pseudonym = Column(String, unique=True, nullable=False)
    reliability_rating = Column(Integer)
    sensitivity_level = Column(Enum(ClassificationLevel))
    case_linked = Column(String, ForeignKey("cases.id"), index=True)
    contact_channel_type = Column(String)
    handler_assigned = Column(String, ForeignKey("users.id"), index=True)
    risk_score = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)


class IntelPackage(Base):
    __tablename__ = "intel_packages"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    case_id = Column(String, ForeignKey("cases.id"), index=True, nullable=False)
    classification_level = Column(Enum(ClassificationLevel), nullable=False)
    source_profile_id = Column(String, ForeignKey("source_profiles.id"), index=True)
    confidence_score = Column(Float)
    location_lat = Column(Float, nullable=True)
    location_lon = Column(Float, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    tags = Column(JSON, default=list)
    dissemination_policy = Column(String)
    content_encrypted = Column(Text)
    hash_integrity = Column(String)
    created_by = Column(String, ForeignKey("users.id"), index=True)
    access_log_reference = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)


class AccessLog(Base):
    __tablename__ = "access_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    action = Column(String, nullable=False)
    resource_id = Column(String, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    reason_code = Column(String)
    device_id = Column(String)
    integrity_hash = Column(String, unique=True, nullable=False)
    previous_hash = Column(String, nullable=False)


class WearableDevice(Base):
    __tablename__ = "wearable_devices"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    device_id = Column(String, unique=True, nullable=False, index=True)
    agent_id = Column(String, ForeignKey("agent_profiles.id"), index=True)
    device_type = Column(String)  # WATCH, BAND, SENSOR
    last_heartbeat = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    config = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    agent = relationship("AgentProfile", back_populates="wearable_devices")
    events = relationship("WearableEventLog", back_populates="device", lazy="select")


class WearableEventLog(Base):
    __tablename__ = "wearable_events"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    device_id = Column(String, ForeignKey("wearable_devices.device_id"), index=True)
    agent_id = Column(String, ForeignKey("agent_profiles.id"), index=True)
    event_type = Column(String, nullable=False)
    payload_encrypted = Column(Text)
    location_lat = Column(Float, nullable=True)
    location_lon = Column(Float, nullable=True)
    timestamp = Column(DateTime(timezone=True), nullable=False)
    processed = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    device = relationship("WearableDevice", back_populates="events")


class MobileReport(Base):
    __tablename__ = "mobile_reports"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    agent_id = Column(String, ForeignKey("agent_profiles.id"), index=True)
    case_id = Column(String, ForeignKey("cases.id"), index=True)
    report_type = Column(String, nullable=False)
    content_encrypted = Column(Text)
    classification = Column(String, nullable=False)
    timestamp = Column(DateTime(timezone=True), nullable=False)
    device_fingerprint = Column(String, nullable=False)
    status = Column(String, default="RECEIVED", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    agent = relationship("AgentProfile", back_populates="mobile_reports")


class Case(Base):
    __tablename__ = "cases"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    name = Column(String, nullable=False)
    description = Column(String)
    sensitivity_level = Column(Enum(ClassificationLevel), nullable=False)
    is_honeypot = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)


class BehavioralBiometrics(Base):
    __tablename__ = "behavioral_biometrics"

    id = Column(Integer, primary_key=True)
    agent_id = Column(String, ForeignKey("agent_profiles.id"), index=True)
    typing_speed = Column(Float)
    usage_hour = Column(Integer)
    location_variance = Column(Float)
    tap_pressure_avg = Column(Float)
    swipe_speed_avg = Column(Float)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())


class MeshMessage(Base):
    __tablename__ = "mesh_messages"

    id = Column(Integer, primary_key=True)
    sender_node_id = Column(String, nullable=False)
    recipient_agent_id = Column(String, ForeignKey("agent_profiles.id"), index=True)
    payload = Column(Text, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    status = Column(String, default="pending")


class HUMINTSource(Base):
    __tablename__ = "humint_sources"

    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True, nullable=False)
    fuzzy_match_score = Column(Float)
    duplicate_of_id = Column(Integer, ForeignKey("humint_sources.id"), nullable=True)
    reliability_rating = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


# AgentProfile se define arriba en el archivo (linea ~43)
