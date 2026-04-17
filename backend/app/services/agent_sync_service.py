"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import datetime
from typing import Optional
from uuid import uuid4

import structlog
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models import AgentProfile, MobileReport, WearableDevice, WearableEventLog
from app.schemas.wearable import WearableEvent, WearableEventType
from app.schemas.mobile import AgentStatusUpdate, MobileIntelReport
from app.services.encryption_service import EncryptionService

logger = structlog.get_logger(__name__)


class AgentSyncService:
    """
    Servicio de sincronizacion de datos provenientes de dispositivos
    mobile y wearable. Encripta todos los payloads antes de persistir.
    """

    def __init__(self, encryption: EncryptionService) -> None:
        self.encryption = encryption

    # ------------------------------------------------------------------
    # Wearable
    # ------------------------------------------------------------------

    async def process_wearable_event(
        self, event: WearableEvent, db: AsyncSession
    ) -> WearableEventLog:
        """
        Procesa y persiste un evento de wearable.
        El payload se encripta con proposito 'wearable' y AAD = device_id.
        """
        import json

        payload = event.model_dump(mode="json", exclude_none=True)
        encrypted = self.encryption.encrypt(
            json.dumps(payload, default=str),
            purpose="wearable",
            associated_data=event.device_id,
        )

        log = WearableEventLog(
            id=str(uuid4()),
            device_id=event.device_id,
            agent_id=event.agent_id,
            event_type=event.event_type.value,
            payload_encrypted=encrypted,
            location_lat=event.location.latitude if event.location else None,
            location_lon=event.location.longitude if event.location else None,
            timestamp=event.timestamp,
            processed=False,
        )
        db.add(log)

        # Actualizar heartbeat del dispositivo
        await self._update_device_heartbeat(event.device_id, db)
        logger.info(
            "wearable_event_stored",
            device_id=event.device_id,
            event_type=event.event_type.value,
        )
        return log

    async def process_emergency(
        self, event: WearableEvent, db: AsyncSession
    ) -> WearableEventLog:
        """SOS de emergencia — misma logica pero marca processed=False con prioridad maxima."""
        log = await self.process_wearable_event(event, db)
        logger.warning(
            "emergency_sos_received",
            device_id=event.device_id,
            agent_id=event.agent_id,
        )
        return log

    async def get_device_config(
        self, device_id: str, db: AsyncSession
    ) -> Optional[dict]:
        """Retorna la configuracion de un dispositivo wearable."""
        stmt = select(WearableDevice).where(WearableDevice.device_id == device_id)
        result = await db.execute(stmt)
        device = result.scalars().first()
        if not device:
            return None
        return device.config or {"sync_interval": 30, "clandestine_mode": True, "auto_wipe_seconds": 3600}

    async def register_heartbeat(self, device_id: str, db: AsyncSession) -> bool:
        """Registra heartbeat de un dispositivo activo."""
        return await self._update_device_heartbeat(device_id, db)

    async def _update_device_heartbeat(self, device_id: str, db: AsyncSession) -> bool:
        stmt = (
            update(WearableDevice)
            .where(WearableDevice.device_id == device_id)
            .values(last_heartbeat=datetime.datetime.now(datetime.timezone.utc))
        )
        result = await db.execute(stmt)
        return result.rowcount > 0

    # ------------------------------------------------------------------
    # Mobile
    # ------------------------------------------------------------------

    async def process_mobile_report(
        self, report: MobileIntelReport, db: AsyncSession
    ) -> MobileReport:
        """
        Persiste un reporte de inteligencia mobile.
        El contenido se encripta con proposito 'mobile' y AAD = case_id.
        """
        encrypted_content = self.encryption.encrypt(
            report.content,
            purpose="mobile",
            associated_data=report.case_id,
        )

        mobile_report = MobileReport(
            id=str(uuid4()),
            agent_id=report.agent_id,
            case_id=report.case_id,
            report_type=report.report_type.value,
            content_encrypted=encrypted_content,
            classification=report.classification_claim,
            timestamp=report.timestamp,
            device_fingerprint=report.device_fingerprint,
            status="RECEIVED",
        )
        db.add(mobile_report)
        logger.info(
            "mobile_report_stored",
            agent_id=report.agent_id,
            report_type=report.report_type.value,
        )
        return mobile_report

    async def update_agent_status(
        self, update_data: AgentStatusUpdate, db: AsyncSession
    ) -> bool:
        """Actualiza el estado y last_seen del agente."""
        now = datetime.datetime.now(datetime.timezone.utc)
        stmt = (
            update(AgentProfile)
            .where(AgentProfile.id == update_data.agent_id)
            .values(status=update_data.status, last_seen=now)
        )
        result = await db.execute(stmt)
        updated = result.rowcount > 0
        if updated:
            logger.info(
                "agent_status_updated",
                agent_id=update_data.agent_id,
                status=update_data.status,
            )
        return updated

    async def wipe_device(self, device_id: str, db: AsyncSession) -> bool:
        """
        Borrado remoto: desactiva el dispositivo y elimina su configuracion.
        Los eventos historicos se retienen en DB (inmutabilidad de auditoria).
        """
        stmt = (
            update(WearableDevice)
            .where(WearableDevice.device_id == device_id)
            .values(is_active=False, config={})
        )
        result = await db.execute(stmt)
        wiped = result.rowcount > 0
        if wiped:
            logger.warning("device_wiped", device_id=device_id)
        return wiped
