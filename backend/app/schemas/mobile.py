"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class MobileReportType(str, Enum):
    FIELD_REPORT = "FIELD_REPORT"
    CONTACT_LOG = "CONTACT_LOG"
    EVIDENCE_CAPTURE = "EVIDENCE_CAPTURE"
    EXFIL_REQUEST = "EXFIL_REQUEST"
    DEAD_DROP = "DEAD_DROP"


class MobileIntelReport(BaseModel):
    agent_id: str = Field(..., min_length=4, max_length=64)
    case_id: str = Field(..., min_length=4, max_length=64)
    report_type: MobileReportType
    content: str = Field(..., min_length=1, max_length=10000)
    classification_claim: str = Field(..., min_length=1, max_length=32)
    location: Optional[dict] = None
    attachments_count: int = Field(0, ge=0, le=10)
    timestamp: datetime
    device_fingerprint: str = Field(..., min_length=16, max_length=128)

    @field_validator("content")
    @classmethod
    def sanitize_content(cls, v: str) -> str:
        v = v.replace("\x00", "")
        return v[:10000]

    @field_validator("device_fingerprint")
    @classmethod
    def sanitize_fingerprint(cls, v: str) -> str:
        return "".join(c for c in v if c.isprintable() and c not in "\x00\r\n")


class AgentStatusUpdate(BaseModel):
    agent_id: str = Field(..., min_length=4, max_length=64)
    status: str = Field(..., pattern=r"^(ACTIVE|EXTRACTED|COMPROMISED|DARK|STANDBY)$")
    location: Optional[dict] = None
    timestamp: datetime
    message: Optional[str] = Field(None, max_length=500)

    @field_validator("message")
    @classmethod
    def sanitize_message(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.replace("\x00", "").replace("\r", "")
        return v


class MobileReportResponse(BaseModel):
    status: str
    report_id: str
    received_at: str


class AgentCaseSummary(BaseModel):
    case_id: str
    case_name: str
    sensitivity_level: str


class WipeResponse(BaseModel):
    status: str
    device_id: str
    wiped_at: str
