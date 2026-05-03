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

    async def selective_wipe(
        self,
        db: AsyncSession,
        wipe_type: str,
        target_id: str,
        operator_id: str,
    ) -> dict:
        """
        Borrado selectivo: por caso, por credenciales, o por dispositivo.
        Registra en auditoría y notifica al SIEM.
        """
        from app.database.models import Case, AgentProfile, MobileReport
        import datetime

        last_hash = await self.audit.get_last_hash(db)
        wiped_items = []

        if wipe_type == "case":
            case = await db.get(Case, target_id)
            if case:
                case.deleted_at = datetime.datetime.utcnow()
                wiped_items.append(f"case:{target_id}")
        elif wipe_type == "credentials":
            # Revocar certificados del agente
            agent = await db.get(AgentProfile, target_id)
            if agent:
                self.pki.revoke_certificate(agent.entity_id)
                wiped_items.append(f"credentials:{target_id}")
        elif wipe_type == "device":
            # Eliminar reportes móviles asociados
            reports = await db.execute(
                select(MobileReport).where(MobileReport.agent_id == target_id)
            )
            for report in reports.scalars():
                report.status = "WIPED"
            wiped_items.append(f"device_data:{target_id}")

        # Auditoría
        audit_result = self.audit.create_entry(
            user_id=operator_id,
            action="SELECTIVE_WIPE",
            resource_id=target_id,
            reason_code="SELECTIVE_WIPE",
            device_id="CORE_CMD",
            previous_hash=last_hash,
        )

        # SIEM
        from app.services.siem_service import siem_service
        await siem_service.send_log({
            "action": "selective_wipe",
            "type": wipe_type,
            "target": target_id,
            "operator": operator_id,
            "wiped_items": wiped_items,
            "timestamp": datetime.datetime.utcnow().isoformat(),
        })

        return {
            "status": "WIPED",
            "type": wipe_type,
            "target": target_id,
            "wiped_items": wiped_items,
        }
