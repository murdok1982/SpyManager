"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from sqlalchemy import Column, String, Integer, DateTime, JSON, ForeignKey, Enum, Float
from sqlalchemy.orm import relationship, declarative_base
from geoalchemy2 import Geometry
import datetime
from app.core.abac_engine import ClassificationLevel

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)
    username = Column(String, unique=True, index=True)
    role = Column(String)
    classification_level = Column(Enum(ClassificationLevel))
    is_active = Column(Integer, default=1)
    # Lista de IDs de casos a los que tienen acceso
    assigned_cases = Column(JSON) 

class Case(Base):
    __tablename__ = "cases"
    id = Column(String, primary_key=True)
    name = Column(String)
    description = Column(String)
    sensitivity_level = Column(Enum(ClassificationLevel))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class IntelPackage(Base):
    __tablename__ = "intel_packages"
    
    id = Column(String, primary_key=True)
    case_id = Column(String, ForeignKey("cases.id"), index=True)
    classification_level = Column(Enum(ClassificationLevel))
    source_profile_id = Column(String, ForeignKey("source_profiles.id"))
    confidence_score = Column(Float)
    geo = Column(Geometry('POINT', srid=4326), nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    tags = Column(JSON)
    dissemination_policy = Column(String)
    content_encrypted = Column(String) # AES-256-GCM encrypted payload
    hash_integrity = Column(String)
    created_by = Column(String, ForeignKey("users.id"))
    access_log_reference = Column(String)

class SourceProfile(Base):
    __tablename__ = "source_profiles"
    
    id = Column(String, primary_key=True) # pseudonym_id
    pseudonym = Column(String, unique=True)
    reliability_rating = Column(Integer) # 1-10
    sensitivity_level = Column(Enum(ClassificationLevel))
    case_linked = Column(String, ForeignKey("cases.id"))
    contact_channel_type = Column(String)
    handler_assigned = Column(String, ForeignKey("users.id"))
    risk_score = Column(Float)

class AccessLog(Base):
    __tablename__ = "access_logs"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, ForeignKey("users.id"), index=True)
    action = Column(String)
    resource_id = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    reason_code = Column(String)
    device_id = Column(String)
    integrity_hash = Column(String, unique=True)
    previous_hash = Column(String)
