"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.pki_manager import PKIManager
from app.services.audit_service import AuditService

logger = structlog.get_logger(__name__)


class KillSwitchService:
    """
    Servicio de Desconexion de Emergencia (Kill Switch).
    Permite la invalidacion inmediata de accesos para dispositivos
    o agentes comprometidos.
    La operacion es atomica: revocacion PKI + entrada de auditoria
    con previous_hash correcto dentro de la misma transaccion.
    """

    def __init__(self, pki: PKIManager, audit: AuditService) -> None:
        self.pki = pki
        self.audit = audit

    async def trigger_kill_switch(
        self,
        target_entity_id: str,
        operator_id: str,
        reason: str,
        db: AsyncSession,
    ) -> dict:
        """
        Activa el Kill Switch para una entidad especifica.
        1. Obtiene el ultimo hash de la cadena (SELECT FOR UPDATE)
        2. Revoca el certificado en PKI
        3. Registra en auditoria con previous_hash correcto
        4. Persiste el log en DB
        """
        from app.database.models import AccessLog

        # 1. Obtener ultimo hash con SELECT FOR UPDATE (evita race condition)
        last_hash = await self.audit.get_last_hash(db)

        # 2. Revocar en PKI
        self.pki.revoke_certificate(target_entity_id)
        logger.warning(
            "kill_switch_triggered",
            target=target_entity_id,
            operator=operator_id,
            reason=reason,
        )

        # 3. Crear entrada de auditoria con previous_hash correcto
        audit_result = self.audit.create_entry(
            user_id=operator_id,
            action="TRIGGER_KILL_SWITCH",
            resource_id=target_entity_id,
            reason_code="EMERGENCY_NEUTRALIZATION",
            device_id="CORE_CMD",
            previous_hash=last_hash,
        )

        # 4. Persistir log
        access_log = AccessLog(
            user_id=operator_id,
            action="TRIGGER_KILL_SWITCH",
            resource_id=target_entity_id,
            reason_code="EMERGENCY_NEUTRALIZATION",
            device_id="CORE_CMD",
            integrity_hash=audit_result["integrity_hash"],
            previous_hash=last_hash,
        )
        db.add(access_log)
        # El commit lo gestiona get_db() al salir del context manager

        return {
            "status": "NEUTRALIZED",
            "entity": target_entity_id,
            "reason": reason,
            "audit_hash": audit_result["integrity_hash"],
        }
