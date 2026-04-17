"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class WearableEventType(str, Enum):
    LOCATION_UPDATE = "LOCATION_UPDATE"
    BIOMETRIC_ALERT = "BIOMETRIC_ALERT"
    EMERGENCY_SOS = "EMERGENCY_SOS"
    INTEL_CAPTURE = "INTEL_CAPTURE"
    STATUS_UPDATE = "STATUS_UPDATE"


class LocationData(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy_meters: float = Field(..., gt=0, le=1000)
    altitude_meters: Optional[float] = None


class BiometricData(BaseModel):
    heart_rate_bpm: Optional[int] = Field(None, ge=20, le=300)
    stress_level: Optional[int] = Field(None, ge=0, le=100)
    steps_count: Optional[int] = Field(None, ge=0)


class WearableEvent(BaseModel):
    device_id: str = Field(..., min_length=8, max_length=64)
    agent_id: str = Field(..., min_length=4, max_length=64)
    event_type: WearableEventType
    timestamp: datetime
    location: Optional[LocationData] = None
    biometrics: Optional[BiometricData] = None
    intel_note: Optional[str] = Field(None, max_length=2000)
    case_id: Optional[str] = Field(None, max_length=64)
    encrypted_payload: Optional[str] = None

    @field_validator("intel_note")
    @classmethod
    def sanitize_intel_note(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.replace("\x00", "").replace("\r", "")
            v = v[:2000]
        return v

    @field_validator("device_id", "agent_id")
    @classmethod
    def sanitize_id_fields(cls, v: str) -> str:
        # Eliminar caracteres de control
        return "".join(c for c in v if c.isprintable() and c not in "\x00\r\n")


class WearableHeartbeat(BaseModel):
    device_id: str = Field(..., min_length=8, max_length=64)
    agent_id: str = Field(..., min_length=4, max_length=64)
    timestamp: datetime
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    signal_strength: Optional[int] = Field(None, ge=-120, le=0)


class WearableEventResponse(BaseModel):
    status: str
    event_id: str
    received_at: str
