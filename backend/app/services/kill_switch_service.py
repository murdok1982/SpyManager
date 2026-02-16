"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from app.core.pki_manager import PKIManager
from app.services.audit_service import AuditService

class KillSwitchService:
    """
    Servicio de Desconexión de Emergencia (Kill Switch).
    Permite la invalidación inmediata de accesos para dispositivos 
    o agentes comprometidos.
    """
    
    def __init__(self, pki: PKIManager, audit: AuditService):
        self.pki = pki
        self.audit = audit

    def trigger_kill_switch(self, target_entity_id: str, operator_id: str, reason: str):
        """
        Activa el Kill Switch para una entidad específica.
        Revoca su certificado y registra el evento de seguridad máxima.
        """
        # 1. Revocar en el gestor de PKI
        self.pki.revoke_certificate(target_entity_id)
        
        # 2. Registrar en la auditoría inmutable con código de alerta máxima
        self.audit.create_entry(
            user_id=operator_id,
            action="TRIGGER_KILL_SWITCH",
            resource_id=target_entity_id,
            reason_code="EMERGENCY_NEUTRALIZATION",
            device_id="CORE_CMD"
        )
        
        return {
            "status": "NEUTRALIZED",
            "entity": target_entity_id,
            "reason": reason
        }
