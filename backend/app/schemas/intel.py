"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from app.core.abac_engine import ClassificationLevel

class IntelCreate(BaseModel):
    id: str
    case_id: str
    classification_level: ClassificationLevel
    source_profile_id: str
    confidence_score: float = Field(ge=0, le=1)
    content: str
    tags: List[str] = []

class IntelResponse(BaseModel):
    id: str
    content: str
    classification: ClassificationLevel
    case_id: str

class UserAuth(BaseModel):
    user_id: str
    role: str
    classification: ClassificationLevel
    cases: List[str]
