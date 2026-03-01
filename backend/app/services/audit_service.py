"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import hashlib
import json
import datetime
from typing import Optional
from pydantic import BaseModel

class AuditEntry(BaseModel):
    user_id: str
    action: str
    resource_id: str
    timestamp: str
    reason_code: str
    device_id: str
    previous_hash: str
    
    def compute_hash(self) -> str:
        # Serialización canónica y ordenada (RFC 8785 aproximación)
        dumped_dict = self.model_dump(mode='json')
        canonical_json = json.dumps(dumped_dict, sort_keys=True, separators=(',', ':')).encode('utf-8')
        return hashlib.sha256(canonical_json).hexdigest()

class AuditService:
    """
    Servicio de Auditoría Inmutable.
    Cada entrada está encadenada a la anterior mediante un hash SHA-256.
    """
    
    def create_entry(self, user_id: str, action: str, resource_id: str, 
                     reason_code: str, device_id: str, previous_hash: str) -> dict:
        """Crea una nueva entrada de auditoría encadenada."""
        entry = AuditEntry(
            user_id=user_id,
            action=action,
            resource_id=resource_id,
            timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),
            reason_code=reason_code,
            device_id=device_id,
            previous_hash=previous_hash
        )
        
        entry_hash = entry.compute_hash()
        
        return {
            "entry": entry.model_dump(),
            "integrity_hash": entry_hash
        }

    @staticmethod
    def verify_chain(entries: list) -> bool:
        """Verifica la integridad de una lista de entradas de auditoría."""
        current_hash = "0" * 64
        for data in entries:
            entry_data = data["entry"]
            entry = AuditEntry(**entry_data)
            
            if entry.previous_hash != current_hash:
                return False
                
            current_hash = data["integrity_hash"]
            if entry.compute_hash() != current_hash:
                return False
                
        return True
